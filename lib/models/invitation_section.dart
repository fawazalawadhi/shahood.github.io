/// كل قسم يظهر في صفحة تفاصيل الدعوة (أثناء السكرول بعد الكشف) له نوع ثابت،
/// لكن حالة التفعيل والترتيب يتحكم فيها المستخدم بالكامل - تماماً مثل numinds.
enum SectionType {
  welcomeNote, // بيت شعر / آية / عبارة ترحيبية
  hostNames, // أسماء الطرفين/العائلتين
  dateTime, // التاريخ والوقت
  location, // الموقع
  gallery, // صور إضافية (حتى 4 صور)
  rules, // قواعد/تعليمات الحفل
  countdown, // عداد تنازلي للمناسبة
  gifts, // الهدايا (حسابات مالية تظهر عند الضغط)
  whatsappContact, // رابط تواصل واتساب
  rsvp, // تأكيد الحضور
}

extension SectionTypeLabel on SectionType {
  String get arabicLabel {
    switch (this) {
      case SectionType.welcomeNote:
        return 'شعر / آية / عبارة ترحيبية';
      case SectionType.hostNames:
        return 'أسماء الطرفين / العائلتين';
      case SectionType.dateTime:
        return 'التاريخ والوقت';
      case SectionType.location:
        return 'الموقع';
      case SectionType.gallery:
        return 'صور إضافية';
      case SectionType.rules:
        return 'قواعد وتعليمات الحفل';
      case SectionType.countdown:
        return 'عداد تنازلي';
      case SectionType.gifts:
        return 'الهدايا';
      case SectionType.whatsappContact:
        return 'تواصل واتساب';
      case SectionType.rsvp:
        return 'تأكيد الحضور (RSVP)';
    }
  }

  static SectionType fromKey(String key) =>
      SectionType.values.firstWhere((e) => e.name == key, orElse: () => SectionType.welcomeNote);
}

/// إعداد قسم واحد داخل الدعوة: هل هو مفعّل، وترتيبه بين باقي الأقسام.
class SectionConfig {
  final SectionType type;
  bool enabled;
  int order;

  SectionConfig({required this.type, this.enabled = true, required this.order});

  SectionConfig copy() => SectionConfig(type: type, enabled: enabled, order: order);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'enabled': enabled,
        'order': order,
      };

  factory SectionConfig.fromJson(Map<String, dynamic> json) => SectionConfig(
        type: SectionTypeLabel.fromKey(json['type'] as String),
        enabled: json['enabled'] as bool,
        order: json['order'] as int,
      );

  /// الترتيب الافتراضي عند بدء تصميم جديد.
  /// بعض الأقسام (الهدايا، واتساب، الصوت) نخليها مطفأة افتراضياً حتى
  /// يعبّي المستخدم بياناتها الحساسة (حسابات بنكية مثلاً) بنفسه قبل تفعيلها.
  static List<SectionConfig> defaults() => [
        SectionConfig(type: SectionType.welcomeNote, order: 0),
        SectionConfig(type: SectionType.hostNames, order: 1),
        SectionConfig(type: SectionType.dateTime, order: 2),
        SectionConfig(type: SectionType.location, order: 3),
        SectionConfig(type: SectionType.gallery, order: 4, enabled: false),
        SectionConfig(type: SectionType.rules, order: 5, enabled: false),
        SectionConfig(type: SectionType.countdown, order: 6),
        SectionConfig(type: SectionType.gifts, order: 7, enabled: false),
        SectionConfig(type: SectionType.rsvp, order: 8),
        SectionConfig(type: SectionType.whatsappContact, order: 9, enabled: false),
      ];
}
