/// نوع محتوى العنصر المتحرك: نص أو صورة PNG (بخلفية شفافة عادةً)
enum OverlayElementType { text, image }

/// أنواع الأنيميشن المتاحة لكل عنصر متحرك فوق الفيديو
enum OverlayAnimationType { fade, slideUp, slideDown, scale, zoom }

extension OverlayAnimationTypeLabel on OverlayAnimationType {
  String get arabicLabel {
    switch (this) {
      case OverlayAnimationType.fade:
        return 'ظهور تدريجي (Fade)';
      case OverlayAnimationType.slideUp:
        return 'انزلاق للأعلى';
      case OverlayAnimationType.slideDown:
        return 'انزلاق للأسفل';
      case OverlayAnimationType.scale:
        return 'تكبير تدريجي (Scale)';
      case OverlayAnimationType.zoom:
        return 'تقريب (Zoom)';
    }
  }

  static OverlayAnimationType fromKey(String key) =>
      OverlayAnimationType.values.firstWhere((e) => e.name == key, orElse: () => OverlayAnimationType.fade);
}

/// عنصر متحرك يظهر فوق الفيديو أثناء تشغيله (اسم العريس، شعار، زخرفة...).
/// كل عنصر مستقل بتوقيته وحركته وموقعه.
class OverlayElement {
  final String id;
  OverlayElementType type;

  // محتوى نصي (لو type == text)
  String text;
  String fontFamily;
  double fontSize;
  int colorValue;

  // محتوى صورة (لو type == image) - يفضّل PNG بخلفية شفافة
  String? imagePath;

  // الموقع: Alignment قياسي (-1..1 لكل محور)، افتراضياً في المنتصف
  double positionX;
  double positionY;

  // الحجم كنسبة من عرض إطار الفيديو (0.1 - 1.0)
  double widthFraction;

  // الشفافية النهائية بعد اكتمال الحركة (0-1)
  double opacity;

  // التوقيت
  double startDelaySeconds; // وقت بداية الظهور بعد بداية تشغيل الفيديو
  double durationSeconds; // مدة حركة الظهور نفسها

  OverlayAnimationType animationType;

  OverlayElement({
    required this.id,
    required this.type,
    this.text = '',
    this.fontFamily = 'Tajawal',
    this.fontSize = 22,
    this.colorValue = 0xFFFFFFFF,
    this.imagePath,
    this.positionX = 0,
    this.positionY = 0,
    this.widthFraction = 0.5,
    this.opacity = 1,
    this.startDelaySeconds = 0,
    this.durationSeconds = 1,
    this.animationType = OverlayAnimationType.fade,
  });

  OverlayElement copy() => OverlayElement.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'colorValue': colorValue,
        'imagePath': imagePath,
        'positionX': positionX,
        'positionY': positionY,
        'widthFraction': widthFraction,
        'opacity': opacity,
        'startDelaySeconds': startDelaySeconds,
        'durationSeconds': durationSeconds,
        'animationType': animationType.name,
      };

  factory OverlayElement.fromJson(Map<String, dynamic> json) => OverlayElement(
        id: json['id'] as String,
        type: OverlayElementType.values.firstWhere((e) => e.name == json['type'], orElse: () => OverlayElementType.text),
        text: json['text'] as String? ?? '',
        fontFamily: json['fontFamily'] as String? ?? 'Tajawal',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 22,
        colorValue: json['colorValue'] as int? ?? 0xFFFFFFFF,
        imagePath: json['imagePath'] as String?,
        positionX: (json['positionX'] as num?)?.toDouble() ?? 0,
        positionY: (json['positionY'] as num?)?.toDouble() ?? 0,
        widthFraction: (json['widthFraction'] as num?)?.toDouble() ?? 0.5,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1,
        startDelaySeconds: (json['startDelaySeconds'] as num?)?.toDouble() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 1,
        animationType: OverlayAnimationTypeLabel.fromKey(json['animationType'] as String? ?? 'fade'),
      );
}
