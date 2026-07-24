import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/design_provider.dart';
import 'providers/template_provider.dart';
import 'screens/home_screen.dart';
import 'screens/invitation_view_screen.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة الاتصال بقاعدة بيانات Supabase (المصادقة + الجداول)
  await SupabaseConfig.initialize();
  // تهيئة بيانات تنسيق التاريخ للعربية (مطلوبة لعرض التاريخ في قسم "التاريخ والوقت")
  await initializeDateFormatting('ar');
  runApp(ShahoodaApp(invitationSlug: _slugFromCurrentUrl()));
}

/// يقرأ مسار الرابط الذي فُتح فيه التطبيق فعلياً بالمتصفح (مثلاً
/// https://azzama.com/i/ahmad-sara-abc123) ويستخرج الـ slug إن وُجد.
/// يعمل هذا بدون أي حزمة توجيه إضافية لأننا نحتاج فقط قراءة الرابط الأولي
/// مرة واحدة عند الإقلاع، وليس تغييره أثناء تنقل المستخدم داخل التطبيق.
/// شرط استضافة أساسي: يجب أن يكون السيرفر مهيأ لإعادة توجيه كل المسارات
/// إلى index.html (SPA rewrite) وإلا ستحصل صفحة 404 من السيرفر قبل ما
/// يوصل الطلب لتطبيق Flutter أصلاً.
String? _slugFromCurrentUrl() {
  final segments = Uri.base.pathSegments;
  final i = segments.indexOf('i');
  if (i != -1 && i + 1 < segments.length && segments[i + 1].isNotEmpty) {
    return segments[i + 1];
  }
  return null;
}

class ShahoodaApp extends StatelessWidget {
  final String? invitationSlug;
  const ShahoodaApp({super.key, this.invitationSlug});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DesignProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()..loadTemplates()),
      ],
      child: MaterialApp(
        title: 'عزّامة',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // المنصة عربية بالكامل، لذلك نفرض اتجاه RTL دائماً
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: invitationSlug != null ? InvitationViewScreen(slug: invitationSlug!) : const HomeScreen(),
      ),
    );
  }
}
