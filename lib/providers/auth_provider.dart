import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';

/// يدير حالة تسجيل الدخول (بريد إلكتروني وكلمة مرور عبر Supabase Auth).
/// أي شاشة تحتاج تعرف هل يوجد مستخدم مسجّل دخول، معرّفه، أو هل هو أدمن،
/// تستخدم هذا الـ Provider بدل التعامل مع Supabase مباشرة.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSub = supabase.auth.onAuthStateChange.listen((_) => _loadProfileRole());
    _loadProfileRole();
  }

  late final StreamSubscription<AuthState> _authSub;

  String _role = 'user';
  bool isLoading = false;
  String? errorMessage;

  User? get currentUser => supabase.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;
  bool get isAdmin => isLoggedIn && _role == 'admin';

  /// يقرأ صلاحية المستخدم (user/admin) من جدول profiles بعد كل تغيّر بحالة الدخول
  Future<void> _loadProfileRole() async {
    if (currentUser == null) {
      _role = 'user';
      notifyListeners();
      return;
    }
    try {
      final row = await supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser!.id)
          .single();
      _role = row['role'] as String? ?? 'user';
    } catch (_) {
      _role = 'user';
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() async {
      await supabase.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<bool> signUp({required String email, required String password}) {
    return _run(() async {
      await supabase.auth.signUp(email: email, password: password);
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      isLoading = false;
      errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
