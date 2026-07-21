import 'package:supabase_flutter/supabase_flutter.dart';

/// إعدادات الاتصال بمشروع Supabase الخاص بمنصة شهودة.
///
/// !! مهم: استبدل القيمتين التاليتين بالقيم الحقيقية من مشروعك:
/// Supabase Dashboard -> Project Settings -> API
/// - url: قيمة "Project URL"
/// - anonKey: قيمة "anon public" من API Keys
class SupabaseConfig {
  static const String url = 'https://sayhaiiirpecqioxhcke.supabase.co';
  static const String anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNheWhhaWlpcnBlY3Fpb3hoY2tlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1MDg0OTgsImV4cCI6MjEwMDA4NDQ5OH0.FdUzBH6mA4ukMbRWKfy6eR9ll1ajF68aD3dSOJC281A";

  /// يُستدعى مرة وحدة عند إقلاع التطبيق (من main.dart)
  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

/// اختصار سريع للوصول لعميل Supabase من أي مكان بالتطبيق
/// (بعد استدعاء SupabaseConfig.initialize() في main.dart)
SupabaseClient get supabase => Supabase.instance.client;
