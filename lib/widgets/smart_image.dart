import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Widget موحّد لعرض صورة قد تكون:
/// - أصل بالتطبيق: `assets/...` → [Image.asset]
/// - رابط شبكي: `http(s)://...` → [CachedNetworkImage] (يستفيد من كاش حقيقي
///   بدل إعادة تحميل نفس الصورة من الشبكة في كل مرة، كان مفقوداً سابقاً رغم
///   أن الحزمة معرّفة أصلاً بـ pubspec.yaml بدون استخدام).
/// - رابط `data:` (صورة base64 مضمّنة) → [Image.network] مباشرة (لا يدعمها
///   CachedNetworkImage لأنها ليست طلب HTTP فعلي).
/// - مسار ملف محلي (غير مستخدم عملياً بما إن المشروع Flutter Web فقط حالياً،
///   لكن يبقى كخيار احتياطي لو توسّع المشروع لمنصات أخرى مستقبلاً) → [Image.file]
///
/// كان هذا المنطق مكرراً بالضبط في 4 ملفات مختلفة:
/// live_preview.dart, detail_sections.dart, falling_particles.dart,
/// overlay_elements_layer.dart. توحيده هنا يمنع اختلاف السلوك بينها مستقبلاً
/// عند أي تعديل يُطبَّق على نسخة واحدة وينسى الباقي.
class SmartImage extends StatelessWidget {
  final String? path;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// يُستدعى عند فشل تحميل الصورة (رابط ميت، ملف غير موجود...). لو لم يُمرَّر
  /// أي شيء، تُعرض مساحة فارغة بنفس الأبعاد بدل ظهور خطأ لأحمر بالواجهة.
  final WidgetBuilder? errorBuilder;

  const SmartImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  Widget _fallback(BuildContext context) =>
      errorBuilder?.call(context) ?? SizedBox(width: width, height: height);

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return _fallback(context);

    if (p.startsWith('assets/')) {
      return Image.asset(
        p,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (p.startsWith('data:')) {
      return Image.network(
        p,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    if (kIsWeb || p.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: p,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => SizedBox(width: width, height: height),
        errorWidget: (_, __, ___) => _fallback(context),
      );
    }

    return Image.file(
      File(p),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _fallback(context),
    );
  }
}
