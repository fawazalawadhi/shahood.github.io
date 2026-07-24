-- ============================================
-- شهودة (Shahooda) — إعداد قاعدة بيانات Supabase
-- شغّل هذا الملف كامل مرة وحدة من SQL Editor
-- ============================================

-- جدول الملفات الشخصية (يمتد من auth.users المدمج بسوبا بيس)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  role text not null default 'user' check (role in ('user', 'admin')),
  created_at timestamptz not null default now()
);

-- جدول القوالب (عامة من الأدمن أو خاصة بمستخدم)
create table if not exists public.templates (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null,
  is_system_template boolean not null default false,
  owner_user_id uuid references auth.users(id) on delete cascade,
  thumbnail_image_path text,
  draft_json jsonb not null,
  created_at timestamptz not null default now()
);

-- جدول الدعوات المنشورة
create table if not exists public.invitations (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  owner_user_id uuid references auth.users(id) on delete cascade,
  draft_json jsonb not null,
  published_at timestamptz not null default now(),
  view_count integer not null default 0
);

-- جدول ردود تأكيد الحضور (RSVP)
create table if not exists public.rsvp_responses (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references public.invitations(id) on delete cascade,
  guest_name text,
  attending boolean not null,
  guest_count integer default 1,
  note text,
  created_at timestamptz not null default now()
);

-- ============================================
-- الفهارس (تسريع البحث)
-- ============================================
create index if not exists idx_templates_category on public.templates(category);
create index if not exists idx_templates_owner on public.templates(owner_user_id);
create index if not exists idx_invitations_slug on public.invitations(slug);
create index if not exists idx_rsvp_invitation on public.rsvp_responses(invitation_id);

-- ============================================
-- تفعيل Row Level Security (حماية أساسية إجبارية)
-- ============================================
alter table public.profiles enable row level security;
alter table public.templates enable row level security;
alter table public.invitations enable row level security;
alter table public.rsvp_responses enable row level security;

-- profiles: كل مستخدم يشوف ويعدّل ملفه بس
create policy "read own profile" on public.profiles for select using (auth.uid() = id);
create policy "update own profile" on public.profiles for update using (auth.uid() = id);

-- templates: القوالب العامة يشوفها الجميع، الخاصة يشوفها صاحبها بس
create policy "view system templates" on public.templates for select using (is_system_template = true);
create policy "view own templates" on public.templates for select using (auth.uid() = owner_user_id);
create policy "insert own templates" on public.templates for insert with check (
  -- المستخدم يقدر يحفظ قالب خاص باسمه هو بس
  (auth.uid() = owner_user_id and is_system_template = false)
  or
  -- القالب العام (is_system_template = true) يتطلب صلاحية أدمن فعلية من جدول profiles
  (is_system_template = true and exists (
    select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
  ))
);
-- تحديث/حذف: صاحب القالب الخاص، أو الأدمن لأي قالب (خاصة القوالب العامة اللي owner_user_id فيها فاضي)
create policy "update own or admin templates" on public.templates for update using (
  auth.uid() = owner_user_id
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
create policy "delete own or admin templates" on public.templates for delete using (
  auth.uid() = owner_user_id
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- ============================================
-- حد أقصى 3 قوالب خاصة لكل مستخدم عادي (الأدمن مستثنى)
-- كانت موثّقة كـ"مطبّقة" لكنها لم تكن موجودة فعلياً بهذا الملف - أُضيفت الآن.
-- ============================================
create or replace function public.enforce_template_limit()
returns trigger as $$
declare
  is_caller_admin boolean;
  current_count integer;
begin
  -- القوالب العامة (is_system_template = true) غير محدودة أصلاً (الأدمن فقط يقدر يدرجها - مضمون بسياسة insert)
  if new.is_system_template then
    return new;
  end if;

  select (role = 'admin') into is_caller_admin from public.profiles where id = new.owner_user_id;
  if coalesce(is_caller_admin, false) then
    return new;
  end if;

  select count(*) into current_count
  from public.templates
  where owner_user_id = new.owner_user_id and is_system_template = false;

  if current_count >= 3 then
    raise exception 'الحد الأقصى 3 قوالب خاصة لكل مستخدم';
  end if;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_enforce_template_limit on public.templates;
create trigger trg_enforce_template_limit
  before insert on public.templates
  for each row execute procedure public.enforce_template_limit();

-- invitations: الدعوة المنشورة يقدر أي زائر يشوفها (رابط عام)، بس صاحبها بس يعدّل/يحذف
create policy "anyone can view published invitations" on public.invitations for select using (true);
create policy "owner can insert invitation" on public.invitations for insert with check (auth.uid() = owner_user_id);
create policy "owner can update invitation" on public.invitations for update using (auth.uid() = owner_user_id);
create policy "owner can delete invitation" on public.invitations for delete using (auth.uid() = owner_user_id);

-- rsvp: أي ضيف يقدر يرسل رد (بدون تسجيل دخول)، بس صاحب الدعوة يشوف الردود
create policy "anyone can submit rsvp" on public.rsvp_responses for insert with check (true);
create policy "owner can view rsvp" on public.rsvp_responses for select using (
  exists (select 1 from public.invitations i where i.id = invitation_id and i.owner_user_id = auth.uid())
);

-- ============================================
-- دالة تلقائية: تنشئ صف بجدول profiles عند تسجيل أي مستخدم جديد
-- ============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ============================================
-- صلاحيات مخازن الملفات (Storage) — كانت مفقودة بالكامل!
-- ملاحظة مهمة: تفعيل "Public bucket" من الواجهة يكفي وحده للعرض/التحميل
-- (Supabase يتجاوز RLS تماماً لملفات المخازن العامة عند الجلب برابط معروف).
-- لا تضف policy من نوع "select" هنا: هذا النوع تحديداً يفتح صلاحية استعراض/جرد
-- كل الملفات بالمخزن (List) لأي حد، وليس له علاقة بجلب ملف تعرف رابطه أصلاً -
-- وهذا بالضبط ما ينبّه عليه Supabase Security Advisor بتحذير
-- "Clients can list all files in this bucket". التطبيق لا يستخدم .list() إطلاقاً
-- (كل الوصول عبر getPublicUrl برابط مباشر)، فلا حاجة لهذا النوع من الصلاحية أبداً.
-- شغّل هذا الجزء بعد ما تنشئ المخازن الثلاثة (covers, videos, audio) كـ Public.
-- ============================================

create policy "logged in users can upload covers" on storage.objects for insert with check (
  bucket_id = 'covers' and auth.uid() is not null
);
create policy "logged in users can upload videos" on storage.objects for insert with check (
  bucket_id = 'videos' and auth.uid() is not null
);
create policy "logged in users can upload audio" on storage.objects for insert with check (
  bucket_id = 'audio' and auth.uid() is not null
);
