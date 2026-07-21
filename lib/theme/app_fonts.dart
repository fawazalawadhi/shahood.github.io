import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

/// خطوط عربية مختارة يدوياً (مقروءة وتناسب دعوات المناسبات).
/// الأدمن/المستخدم يختار خط منفصل لكل دور: الأسماء البارزة، العناوين، النصوص.
class AppFonts {
  AppFonts._();

  static const List<String> available = [
    'Tajawal',
    'Almarai',
    'Cairo',
    'Amiri',
    'Lateef',
    'Reem Kufi',
    'Lalezar',
    'Changa',
    'Markazi Text',
    'Rakkas',
    'El Messiri',
    'Harmattan',
    'IBM Plex Sans Arabic',
    'Noto Kufi Arabic',
    'Aref Ruqaa',
    'Mada',
    'Jomhuria',
  ];

  static TextStyle style(String fontName, {double? fontSize, FontWeight? fontWeight, Color? color}) {
    try {
      return GoogleFonts.getFont(fontName, fontSize: fontSize, fontWeight: fontWeight, color: color);
    } catch (_) {
      // خط غير معروف؟ ارجع لخط افتراضي آمن بدل ما يكسر الواجهة
      return GoogleFonts.tajawal(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }
}
