import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'admin/admin_templates_screen.dart';
import 'auth/login_screen.dart';
import 'template_gallery_screen.dart';

/// الشاشة الرئيسية. الشعار حالياً نص عادي "shahooda" بالخط المعتمد
/// وبالتدرج اللوني للمنصة (أزرق/وردي/بيج) - يستبدل بلوقو حقيقي لاحقاً بسهولة
/// من هذا الملف فقط.
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
  /// لازم يسجّل دخول قبل ما يوصل لهذي المرحلة، بنفس نمط فحص دخول الأدمن أعلاه.
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: auth.isLoggedIn
                      ? TextButton.icon(
                          onPressed: () => auth.signOut(),
                          icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                          label: Text(auth.currentUser?.email ?? 'تسجيل الخروج', style: const TextStyle(color: Colors.white70)),
                        )
                      : TextButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                          icon: const Icon(Icons.login, color: Colors.white70, size: 18),
                          label: const Text('تسجيل الدخول', style: TextStyle(color: Colors.white70)),
                        ),
                ),
                const Spacer(),
                const Text(
                  'shahooda',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'صمّم دعوتك لأي مناسبة في دقائق',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Spacer(),
                SizedBox(
                  width: 260,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.blueDeep,
                    ),
                    onPressed: () => _openDesignFlow(context),
                    child: const Text('ابدأ تصميم دعوتك'),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => _openAdminPanel(context),
                  child: const Text(
                    'دخول لوحة التحكم (أدمن)',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
