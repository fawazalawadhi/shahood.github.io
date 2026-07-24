import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin/admin_templates_screen.dart';
import 'auth/login_screen.dart';
import 'template_gallery_screen.dart';

/// الشاشة الرئيسية — صفحة تعريفية كاملة بالمنصة (Hero + مميزات + كيف تعمل +
/// من نحن + دعوة ختامية)، بدل ما كانت مجرد زر واحد. الشعار حالياً نص عادي
/// "عزّامة" بالخط المعتمد — يستبدل بلوقو حقيقي لاحقاً بسهولة من هذا الملف فقط.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openAdminPanel(BuildContext context) async {
    var auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!context.mounted) return;
      auth = context.read<AuthProvider>();
    }
    if (!auth.isAdmin) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا الحساب لا يملك صلاحية الأدمن')),
        );
      }
      return;
    }
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTemplatesScreen()));
    }
  }

  /// يفرض تسجيل الدخول قبل الوصول لمعرض القوالب وشاشة التصميم - أي عميل
  /// لازم يسجّل دخول قبل ما يوصل لهذي المرحلة.
  Future<void> _openDesignFlow(BuildContext context) async {
    var auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (!context.mounted) return;
      auth = context.read<AuthProvider>();
    }
    if (!auth.isLoggedIn) return; // المستخدم رجع من شاشة الدخول بدون ما يسجّل فعلياً
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplateGalleryScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(
              isLoggedIn: auth.isLoggedIn,
              userEmail: auth.currentUser?.email,
              onLogin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              onLogout: () => auth.signOut(),
              onStartDesign: () => _openDesignFlow(context),
            ),
            const _FeaturesSection(),
            const _HowItWorksSection(),
            const _AboutSection(),
            _FinalCtaSection(onStartDesign: () => _openDesignFlow(context)),
            _Footer(isAdmin: auth.isAdmin, onAdminTap: () => _openAdminPanel(context)),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isLoggedIn;
  final String? userEmail;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onStartDesign;
  const _HeroSection({
    required this.isLoggedIn,
    required this.userEmail,
    required this.onLogin,
    required this.onLogout,
    required this.onStartDesign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 64),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'عزّامة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: .5),
                  ),
                  const Spacer(),
                  isLoggedIn
                      ? TextButton.icon(
                          onPressed: onLogout,
                          icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                          label: Text(userEmail ?? 'تسجيل الخروج', style: const TextStyle(color: Colors.white70)),
                        )
                      : TextButton.icon(
                          onPressed: onLogin,
                          icon: const Icon(Icons.login, color: Colors.white70, size: 18),
                          label: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white70)),
                        ),
                ],
              ),
              const SizedBox(height: 48),
              const Text(
                'صمّم دعوتك الإلكترونية بنفسك، وشاركها بضغطة واحدة',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'منصّة عربية لتصميم دعوات أنيقة لأي مناسبة — زواج، خطوبة، مولود، تخرّج — بدون خبرة تصميم، وبدون تكلفة طباعة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.white, height: 1.7),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blueDeep),
                  onPressed: onStartDesign,
                  child: const Text('صمّم دعوتك الآن'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  static const _features = [
    _Feature(Icons.dashboard_customize_outlined, 'قوالب جاهزة لكل مناسبة', 'زواج، خطوبة، مولود، تخرّج ومناسبات عامة — اختر قالباً وابدأ فوراً.'),
    _Feature(Icons.visibility_outlined, 'معاينة حية فورية', 'غيّر الألوان والصور والنصوص وشوف النتيجة أمامك لحظياً بدون تعقيد.'),
    _Feature(Icons.link_rounded, 'رابط دعوة خاص فيك', 'بعد النشر تحصل على رابط واحد تشاركه مع ضيوفك عبر واتساب أو أي مكان.'),
    _Feature(Icons.fact_check_outlined, 'تأكيد حضور مباشر', 'ضيوفك يأكدون حضورهم من نفس صفحة الدعوة، وتشوف الردود أول بأول.'),
    _Feature(Icons.photo_library_outlined, 'وسائط مخصصة بالكامل', 'صور، فيديو، وصوت خلفية تختارهم بنفسك، حتى لكل قسم من الدعوة على حدة.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beige,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        children: [
          const _SectionHeading(eyebrow: 'المميزات', title: 'كل شي تحتاجه بدعوة واحدة'),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [for (final f in _features) SizedBox(width: 260, child: _FeatureCard(feature: f))],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.beigeDeep, borderRadius: BorderRadius.circular(14)),
              child: Icon(feature.icon, color: AppColors.blueDeep, size: 24),
            ),
            const SizedBox(height: 14),
            Text(feature.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(feature.desc, style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    _Step('١', 'اختر قالب', 'أو ابدأ تصميم من فراغ حسب رغبتك.'),
    _Step('٢', 'خصّص التصميم', 'ألوان، صور، نصوص، وصوت خلفية.'),
    _Step('٣', 'انشر الدعوة', 'تحصل فوراً على رابط جاهز للمشاركة.'),
    _Step('٤', 'شارك وتابع الردود', 'أرسل الرابط وتابع تأكيدات الحضور مباشرة.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        children: [
          const _SectionHeading(eyebrow: 'كيف تعمل', title: 'أربع خطوات وخلاص'),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Wrap(
              spacing: 24,
              runSpacing: 28,
              alignment: WrapAlignment.center,
              children: [for (final s in _steps) SizedBox(width: 200, child: _StepCard(step: s))],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _Step step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
          child: Center(child: Text(step.number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
        ),
        const SizedBox(height: 14),
        Text(step.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        Text(step.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.5)),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.beige,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const _SectionHeading(eyebrow: 'من نحن', title: 'عزّامة'),
              const SizedBox(height: 16),
              // TODO: نص مبدئي - استبدله بمحتوى حقيقي عن قصة/هدف المنصة قبل الإطلاق.
              const Text(
                'منصة سعودية تهدف لتسهيل تصميم ومشاركة الدعوات الإلكترونية لجميع المناسبات، '
                'بواجهة عربية بسيطة تناسب الجميع بدون الحاجة لخبرة تقنية أو تصميمية.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalCtaSection extends StatelessWidget {
  final VoidCallback onStartDesign;
  const _FinalCtaSection({required this.onStartDesign});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 56),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 960),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(28)),
        child: Column(
          children: [
            const Text('جاهز تصمم دعوتك؟', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('يستغرق أقل من 5 دقائق، وما يحتاج بطاقة دفع.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 22),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blueDeep),
                onPressed: onStartDesign,
                child: const Text('ابدأ الآن مجاناً'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onAdminTap;
  const _Footer({required this.isAdmin, required this.onAdminTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          if (isAdmin) ...[
            TextButton(
              onPressed: onAdminTap,
              child: const Text('دخول لوحة التحكم (أدمن)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 4),
          ],
          const Text('© 2026 عزّامة — جميع الحقوق محفوظة', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  const _SectionHeading({required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(eyebrow, style: const TextStyle(color: AppColors.pinkDeep, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: .5)),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  const _Feature(this.icon, this.title, this.desc);
}

class _Step {
  final String number;
  final String title;
  final String desc;
  const _Step(this.number, this.title, this.desc);
}
