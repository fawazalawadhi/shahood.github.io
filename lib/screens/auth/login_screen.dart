import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_config.dart';
import '../../theme/app_theme.dart';

/// شاشة تسجيل الدخول وإنشاء حساب جديد (بريد إلكتروني وكلمة مرور عبر Supabase).
/// تُستخدم قبل أي عملية تتطلب مستخدم مسجّل: حفظ قالب، نشر دعوة، أو دخول لوحة الأدمن.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = _isSignUpMode
        ? await auth.signUp(email: email, password: password)
        : await auth.signIn(email: email, password: password);

    if (!context.mounted) return;

    if (success) {
      // إذا اتنشأ الحساب لكن ما فيه جلسة دخول فعلية بعد، يعني Supabase يتطلب
      // تأكيد البريد الإلكتروني أولاً - ننبّه المستخدم بدل ما نغلق الشاشة بصمت
      if (_isSignUpMode && supabase.auth.currentSession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الحساب. تحقق من بريدك الإلكتروني واضغط رابط التفعيل قبل تسجيل الدخول'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage ?? 'تعذّر تسجيل الدخول')),
      );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUpMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.blueDeep),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
                              if (!v.contains('@')) return 'بريد إلكتروني غير صالح';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'كلمة المرور'),
                            validator: (v) {
                              if (v == null || v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueDeep,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: auth.isLoading ? null : () => _submit(context),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(_isSignUpMode ? 'إنشاء الحساب' : 'دخول'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: auth.isLoading
                              ? null
                              : ()async{
                            await supabase.auth.signInWithOAuth(
                              OAuthProvider.google,
                              redirectTo: 'http://localhost:3000'
                            );
                          },
                              child: const Text("تسجيل الدخول عبر جوجل")),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => setState(() => _isSignUpMode = !_isSignUpMode),
                            child: Text(
                              _isSignUpMode
                                  ? 'لديك حساب بالفعل؟ سجّل الدخول'
                                  : 'ما عندك حساب؟ أنشئ واحد الآن',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
