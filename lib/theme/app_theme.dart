import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان الهوية البصرية لمنصة "شهودة"
/// التدرج الأساسي: أزرق هادئ -> وردي ناعم -> بيج دافئ
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF6E9FC7); // أزرق هادئ
  static const Color blueDeep = Color(0xFF3F6A91); // أزرق أغمق للنصوص/الأزرار
  static const Color pink = Color(0xFFE8B4C0); // وردي ناعم
  static const Color pinkDeep = Color(0xFFD98CA0);
  static const Color beige = Color(0xFFF3E7D3); // بيج دافئ للخلفيات
  static const Color beigeDeep = Color(0xFFE7D4B5);

  static const Color textDark = Color(0xFF3A3A3A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFDF9);

  /// التدرج الرئيسي المستخدم في الخلفيات والهيدرات
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, pink, beige],
  );

  /// تدرج أخف يستخدم كخلفية عامة للشاشات
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [beige, surface],
  );

  /// تدرج يستخدم لأزرار الحدث الرئيسية (مثل "نشر الدعوة")
  static const LinearGradient actionGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [blueDeep, pinkDeep],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.beige,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blueDeep,
        secondary: AppColors.pinkDeep,
        surface: AppColors.surface,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.tajawalTextTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blueDeep,
          foregroundColor: AppColors.textLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.beigeDeep),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.beigeDeep),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.blueDeep.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
