/// أنواع المناسبات المدعومة في المنصة.
/// الأدمن لاحقاً يقدر يضيف أنواع جديدة من نفس هذا التعريف
/// أو نحوّله لقائمة ديناميكية قادمة من قاعدة البيانات بدل enum ثابت.
enum EventCategory {
  wedding, // زفاف
  engagement, // خطوبة
  newborn, // مولود
  graduation, // تخرج
  general, // مناسبة عامة / أخرى
}

extension EventCategoryLabel on EventCategory {
  String get arabicLabel {
    switch (this) {
      case EventCategory.wedding:
        return 'زفاف';
      case EventCategory.engagement:
        return 'خطوبة';
      case EventCategory.newborn:
        return 'مولود';
      case EventCategory.graduation:
        return 'تخرج';
      case EventCategory.general:
        return 'مناسبة عامة';
    }
  }

  static EventCategory fromKey(String key) {
    return EventCategory.values.firstWhere(
      (e) => e.name == key,
      orElse: () => EventCategory.general,
    );
  }
}
