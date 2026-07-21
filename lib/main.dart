import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/design_provider.dart';
import 'providers/template_provider.dart';
import 'screens/home_screen.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تهيئة الاتصال بقاعدة بيانات Supabase (المصادقة + الجداول)
  await SupabaseConfig.initialize();
  // تهيئة بيانات تنسيق التاريخ للعربية (مطلوبة لعرض التاريخ في قسم "التاريخ والوقت")
  await initializeDateFormatting('ar');
  runApp(const ShahoodaApp());
}

class ShahoodaApp extends StatelessWidget {
  const ShahoodaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DesignProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()..loadTemplates()),
      ],
      child: MaterialApp(
        title: 'shahooda',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // المنصة عربية بالكامل، لذلك نفرض اتجاه RTL دائماً
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
