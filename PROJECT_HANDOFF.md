# shahooda — ملف تسليم المشروع الكامل

هذا الملف مخصص لتعطيه لأي أداة ذكاء اصطناعي (أو مبرمج) تكمل معه المشروع، بحيث يفهم
كل شي من أول قراءة بدون ما يحتاج يسأل من الصفر.

---

## 1) نظرة عامة على المشروع

**shahooda** منصة ويب (Flutter Web) لتصميم دعوات إلكترونية لكل أنواع المناسبات
(زفاف، خطوبة، مولود، تخرج، مناسبة عامة) بأسلوب شبيه بمنصة numinds:

1. المستخدم يختار قالب جاهز أو يبدأ من الصفر
2. يصمم دعوته عبر شاشة فيها **معاينة حية** (يسار) + **أدوات تحكم كاملة** (يمين) —
   كل تغيير ينعكس فوراً بالمعاينة عبر `Provider`
3. الدعوة تعرض للضيف كالتالي: يضغط صورة الغلاف → فيديو يشتغل تلقائياً (بانتقال
   Fade+Zoom ناعم) → عناصر نصية/صور متحركة تظهر فوق الفيديو بتوقيت مخصص → المستخدم
   يسحب لتحت فيتابع صفحة تفاصيل (شعر/آية، أسماء الطرفين، معرض صور، تاريخ ووقت،
   موقع، عداد تنازلي، هدايا، واتساب، تأكيد حضور RSVP، قواعد الحفل)
4. المستخدم يقدر يحفظ تصميمه كقالب خاص فيه (حد أقصى 3 قوالب لغير الأدمن)، أو
   الأدمن يحفظه كقالب عام يظهر للجميع بمعرض القوالب
5. تسجيل دخول **إجباري** قبل الوصول لأي شاشة تصميم (بريد/كلمة مرور + دخول جوجل)

---

## 2) التقنيات المستخدمة

- **Flutter Web** (Dart) — الواجهة كاملة
- **Provider** — إدارة الحالة (State Management) بكل الشاشات
- **Supabase** — قاعدة البيانات (Postgres) + المصادقة (Auth) + تخزين الملفات (Storage)
- **google_fonts** — خطوط عربية متعددة قابلة للاختيار
- **image_picker / file_picker / video_player / audioplayers** — التعامل مع الوسائط
- **flutter_colorpicker** — منتقي ألوان حر (RGB/HSV كامل، مو ألوان مسبقة)

### الاعتماديات الكاملة (pubspec.yaml)
```
provider, uuid, image_picker, video_player, cached_network_image,
flutter_colorpicker, shared_preferences, intl, google_fonts,
file_picker, audioplayers, supabase_flutter
```

---

## 3) بيانات الاتصال بـ Supabase

**Project URL:** `https://sayhaiiirpecqioxhcke.supabase.co`

**anon/publishable key** (آمن للمشاركة حسب توثيق Supabase نفسه، مخصص للاستخدام
بالمتصفح - **ليس** service_role):
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNheWhhaWlpcnBlY3Fpb3hoY2tlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1MDg0OTgsImV4cCI6MjEwMDA4NDQ5OH0.FdUzBH6mA4ukMbRWKfy6eR9ll1ajF68aD3dSOJC281A
```
موجودة بـ `lib/services/supabase_config.dart`.

⚠️ **مهم جداً:** لا تشارك أبداً مفتاح `service_role` (يعطي وصول كامل بدون قيود) —
هذا فقط للاستخدام من سيرفر خلفي (Backend)، أبداً من كود Flutter/متصفح.

### جداول قاعدة البيانات (`supabase/schema.sql`)
- `profiles` (id, email, role) — يمتد من auth.users، فيه trigger ينشئه تلقائياً
  عند التسجيل (`handle_new_user`)
- `templates` (id, name, category, is_system_template, owner_user_id,
  thumbnail_image_path, draft_json, created_at) — القالب = لقطة JSON كاملة من
  InvitationDraft
- `invitations` (id, slug, owner_user_id, draft_json, published_at, view_count)
- `rsvp_responses` (id, invitation_id, guest_name, attending, guest_count, note)

### قواعد أمان مهمة مطبّقة (RLS)
- القوالب العامة (`is_system_template = true`) يشوفها الجميع، **الإدراج يتطلب
  صلاحية admin فعلية من جدول profiles** (كانت هذي ثغرة انصلحت لاحقاً — تأكد إنها
  مطبّقة عندك)
- كل مستخدم عادي محدود بـ **3 قوالب خاصة كحد أقصى** (trigger:
  `enforce_template_limit`) — الأدمن مستثنى من هذا الحد
- مخازن Storage (`covers`, `videos`, `audio`) لازم قواعد صريحة على
  `storage.objects` (عرض عام + رفع لأي مسجّل دخول) — **كانت مفقودة بالكامل وتم
  إصلاحها بآخر تحديث لملف schema.sql، تأكد إنها اتشغّلت فعلياً بمشروعك**

### مخازن Storage المطلوبة (لازم تُنشأ يدوياً من لوحة Supabase، الاسم بالضبط):
- `covers` (Public) — صور الغلاف، الخلفية العامة، المعرض، صورة التساقط، عناصر متحركة
- `videos` (Public) — فيديو الكشف
- `audio` (Public) — الموسيقى الخلفية

**كيف تتحقق إن كل شي مطبّق صح:** روح لـ SQL Editor بسوبا بيس وشغّل ملف
`supabase/schema.sql` **كامل من جديد** (كل الأوامر فيه آمنة تتكرر — تستخدم
`create or replace`/`if not exists`/`drop ... if exists` بكل مكان).

---

## 4) هيكلة المشروع (lib/)

```
lib/
  main.dart                              نقطة الدخول: تهيئة Supabase + Providers
  services/
    supabase_config.dart                 رابط ومفتاح Supabase + دالة initialize()
    storage_service.dart                 رفع الملفات لـ Storage وإرجاع رابط عام
  models/
    event_category.dart                  أنواع المناسبات (enum + تسميات عربية)
    invitation_section.dart              أنواع الأقسام (SectionType) + SectionConfig
    gallery_layout.dart                  طريقة عرض معرض الصور (شبكة/فوق بعض/جنب بعض)
    overlay_element.dart                 العناصر المتحركة فوق الفيديو (نص/صورة + توقيت)
    section_icon_presets.dart            بدائل الأيقونات لكل قسم
    content_suggestions.dart             اقتراحات محتوى جاهزة حسب نوع المناسبة
    invitation_draft.dart                *الموديل المركزي* - كل بيانات الدعوة (راجع القسم 5)
    template_model.dart                  القالب = لقطة كاملة من InvitationDraft
  providers/
    design_provider.dart                 الحالة الحية للتصميم (ChangeNotifier)
    template_provider.dart               إدارة القوالب (متصل بـ Supabase الآن)
    auth_provider.dart                   حالة تسجيل الدخول + دور المستخدم (user/admin)
  screens/
    home_screen.dart                     الشاشة الرئيسية (شعار + دخول/أدمن)
    template_gallery_screen.dart         معرض القوالب (مع حالات تحميل/خطأ/فراغ)
    design_screen.dart                   *أكبر ملف* - شاشة التصميم بكل أدواتها
    auth/login_screen.dart               تسجيل الدخول (بريد/كلمة مرور + جوجل)
    admin/admin_templates_screen.dart    لوحة الأدمن (تستخدم نفس شاشة التصميم)
  widgets/
    live_preview.dart                    المعاينة الحية (غلاف→فيديو→تفاصيل قابلة للسكرول)
    detail_sections.dart                 ويدجت كل قسم من أقسام صفحة التفاصيل
    overlay_elements_layer.dart          عرض العناصر المتحركة فوق الفيديو حسب التوقيت
    falling_particles.dart               تأثير الإيموجي/الصورة المتساقطة
  theme/
    app_theme.dart                       الألوان (تدرج أزرق/وردي/بيج) والثيم العام
    app_fonts.dart                       قائمة الخطوط العربية المتاحة (google_fonts)
```

---

## 5) قاموس بيانات InvitationDraft (كل حقل ووظيفته)

الموديل المركزي لكل تصميم/دعوة. يُحفظ كـ JSON كامل بعمود `draft_json`.

**الغلاف:** `titleText`, `category`, `coverImagePath`, `backgroundImagePath`, `revealVideoPath`

**شعر/ترحيب:** `welcomeNoteText`

**أسماء الطرفين:** `hostFamilyLine1`, `hostFamilyLine2` (سطرين منفصلين)

**التاريخ:** `eventDate` (يُستخدم أيضاً للعداد التنازلي)

**الموقع:** `locationText`, `locationMapUrl`

**معرض الصور:** `galleryImagePaths` (حتى 4)، `galleryLayout` (grid/stacked/sideBySide)

**قواعد الحفل:** `rulesText`

**الهدايا:** `giftAccountsText` (نص حر، يظهر عند الضغط على زر)

**واتساب:** `whatsappNumber`

**RSVP:** `rsvpAllowGuestCount`, `rsvpNote`

**الصوت:** `backgroundAudioPath`, `backgroundAudioEnabled`

**التأثير المتساقط:** `fallingAnimationEnabled`, `fallingParticles` (إيموجي)،
`fallingParticleImagePath` (صورة مخصصة تلغي الإيموجي)، `fallingAnimationDurationSeconds`

**الألوان:** `primaryColorValue`, `secondaryColorValue`, `backgroundColorValue`

**الخطوط:** `namesFontFamily` (أسماء بارزة)، `titlesFontFamily` (عناوين الأقسام)،
`bodyFontFamily` (نصوص عادية)

**الأقسام المتقدمة:**
- `sections`: List<SectionConfig> — كل قسم له `type` + `enabled` + `order`
  (قابل لإعادة الترتيب بالسحب من شاشة التصميم)
- `overlayElements`: List<OverlayElement> — عناصر متحركة فوق الفيديو، كل عنصر
  له: نوع (نص/صورة)، موقع X/Y، حجم، شفافية، وقت بداية الظهور، مدة الحركة، نوع
  الأنيميشن (Fade/SlideUp/SlideDown/Scale/Zoom)
- `sectionIconChoice`: Map<String,int> — اسم القسم → رقم الأيقونة المختارة من
  البدائل المعرّفة بـ `section_icon_presets.dart`

**النشر:** `baseTemplateId`, `slug`, `isPublished`

---

## 6) قواعد العمل الإلزامية (أعطها لأي AI يكمل معك)

انسخ هذي القواعد حرفياً لأي أداة ذكاء اصطناعي تشتغل بها على المشروع:

```
1. لا تعيد كتابة أي ملف بالكامل إلا إذا طلبت ذلك صراحة.
2. نفّذ أقل تعديل ممكن (Minimal Diff).
3. عدّل فقط الملفات المرتبطة بالمطلوب.
4. لا تقم بإعادة هيكلة المشروع.
5. لا تغيّر أسماء الملفات أو الكلاسات أو الدوال أو المتغيرات إلا إذا كان ذلك ضرورياً.
6. لا تغيّر تنسيق الكود أو ترتيب الاستيرادات بدون سبب.
7. لا تحذف أي ميزة موجودة.
8. حافظ على جميع الوظائف الحالية.
9. قبل أي تعديل اذكر الملفات التي ستعدلها وسبب تعديل كل ملف.
10. إذا احتجت تعديل أكثر من 3 ملفات، توقف واشرح السبب وانتظر موافقتي.
11. اعرض خطة قصيرة ثم نفّذ.
12. عند الانتهاء اذكر بالضبط ما الذي تغيّر، ولا تعرض الملفات كاملة إلا إذا طُلب ذلك.
```

**نصيحة إضافية مهمة:** بعد أي تعديل، اطلب من الـ AI يتأكد من توازن الأقواس
(`{}`/`()`) بكل الملفات المعدّلة، ويتحقق إن كل Extension method (زي `.arabicLabel`)
مستورد صراحة بكل ملف يستخدمه (خاصية Dart: استيراد النوع مو كافي، لازم تستورد
الملف اللي فيه الـ extension نفسه).

---

## 7) الوضع الحالي: تم ✅ / باقي 🔲

### ✅ تم
- كل واجهة التصميم (كل الأقسام، العناصر المتحركة، التأثيرات، الخطوط، الألوان الحرة)
- الربط الكامل مع Supabase (قاعدة بيانات + مصادقة + تخزين ملفات)
- تسجيل دخول إجباري قبل الوصول لشاشة التصميم (بريد/كلمة مرور)
- حد 3 قوالب خاصة لكل مستخدم عادي (مطبّق من قاعدة البيانات نفسها)
- حماية القوالب العامة (أدمن فقط)
- رفع الملفات فعلياً لـ Storage (بعد آخر إصلاح لقواعد الصلاحيات)

### 🔲 باقي (بالأولوية)
1. **دخول جوجل (Google OAuth)** — مفعّل بإعدادات Supabase بس **غير مربوط بالكود
   بعد** (لا يوجد زر/دالة signInWithGoogle في login_screen.dart أو auth_provider.dart).
   يحتاج أيضاً ضبط Authorized redirect URI بـ Google Cloud Console حسب رابط
   الموقع (يختلف بين localhost والدومين النهائي).
2. **صفحة عرض الدعوة المنشورة فعلياً** (`shahooda.com/i/<slug>`) — الرابط يتولّد
   بس ما فيه شاشة حقيقية تفتحه الضيوف وتقرأ من جدول `invitations`.
3. **حفظ ردود RSVP فعلياً** — الضيف يضغط "سأحضر" بس الرد ما ينحفظ بجدول
   `rsvp_responses` حالياً (الجدول جاهز، الكود الفعلي للحفظ ناقص).
4. **شاشة "قوالبي الخاصة"** — دالة `userTemplates()` بـ template_provider.dart
   موجودة وجاهزة بس **غير مستخدمة بأي شاشة** — المستخدم يقدر يحفظ قالب خاص بس
   ما يقدر يستعرضه لاحقاً.
5. **إعادة تحميل القوالب بعد تسجيل الدخول** — `loadTemplates()` يُستدعى مرة وحدة
   بس عند إقلاع التطبيق (قبل ما يسجّل المستخدم دخول)، فلو سجّل دخول أثناء الجلسة،
   قوالبه الخاصة ما تظهر إلا لو أعاد تحميل الصفحة كاملة.
6. **حماية مباشرة داخل admin_templates_screen.dart نفسها** — حالياً تعتمد بالكامل
   على فحص يصير بـ home_screen.dart قبل الدخول، بدون فحص ثاني داخل الشاشة نفسها
   (دفاع مضاعف).
7. **تفعيل url_launcher** — زر خرائط جوجل وزر واتساب بالدعوة النهائية موجودين
   بالتصميم بس ما يفتحون الروابط فعلياً بعد (يحتاج إضافة حزمة `url_launcher`).
8. **حد أقصى لحجم الملفات المرفوعة** — لا يوجد تحقق حالياً، ممكن مستخدم يرفع
   فيديو ضخم يبطّئ الموقع.
9. **صور Placeholder حقيقية** — القوالب الاحتياطية المحلية (`seedIfEmpty`) لسا
   تشير لملفات `assets/images/placeholder_*.jpg` غير موجودة فعلياً بالمشروع
   (غير مؤثر حالياً لأن بطاقة القالب بالمعرض ما تعرض الصورة أصلاً، بس يستاهل
   تنظيف لاحقاً).

---

## 8) ملاحظات تقنية مهمة (دروس مستفادة أثناء البناء)

- **Flutter Web + `Image.file`/`VideoPlayerController.file`:** غير مدعومين
  إطلاقاً على الويب. أي مسار من `image_picker` على الويب هو `blob:` URL، لازم
  يُعامل عبر `Image.network`/`VideoPlayerController.networkUrl` (تحقق بـ `kIsWeb`).
- **`file_picker` على الويب:** لا يرجّع `path` حقيقي، لازم `withData: true`
  واستخدام `.bytes`.
- **`SingleTickerProviderStateMixin`:** يسمح بـ Ticker واحد **طول عمر الـ State**
  حتى لو تعمل `dispose()` على الـ AnimationController القديم وتسوي وحدة جديدة —
  استخدم `TickerProviderStateMixin` (بدون Single) لو محتاج تنشئ أكثر من واحد.
- **`AnimatedSwitcher`:** يستخدم Stack بـ `StackFit.loose` افتراضياً بالداخل،
  فأبناءه ما يمتدون يملون المساحة تلقائياً. لازم `layoutBuilder` مخصص بـ
  `StackFit.expand`، أو تغليف كل child بـ `SizedBox.expand`.
- **Dart Extensions:** استيراد النوع (مثل `EventCategory`) من ملف ثاني **لا يكفي**
  لرؤية الـ extension methods عليه (مثل `.arabicLabel`) — لازم تستورد الملف اللي
  فيه تعريف الـ extension نفسه بشكل مباشر بكل ملف يستخدمها.
- **Supabase Storage "Public bucket":** يتحكم بالعرض/التحميل فقط، **لا يسمح
  بالرفع تلقائياً** — لازم RLS policies صريحة على `storage.objects` للـ insert.
- **PostgREST + `.single()`:** يرمي خطأ 406 لو رجع 0 أو أكثر من صف — استخدم
  `.maybeSingle()` للتعامل الآمن مع احتمال عدم وجود صف.

---

## 9) كيف تشغّل المشروع

```bash
flutter pub get
flutter run -d chrome
```

قبل أول تشغيل: تأكد إن `supabase/schema.sql` **كامل** اشتغل بمشروع Supabase
(بما فيه آخر إضافة لقواعد Storage بالأسفل)، وإن المخازن الثلاثة (`covers`,
`videos`, `audio`) موجودة كـ Public buckets.
