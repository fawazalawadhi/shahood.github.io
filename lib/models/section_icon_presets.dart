import 'package:flutter/material.dart';
import 'invitation_section.dart';

/// لكل قسم له أيقونة ظاهرة، هذي مجموعة بدائل جاهزة يقدر المستخدم يختار
/// منها بدل الأيقونة الافتراضية. الأقسام غير المذكورة هنا (شعر/ترحيب) ما
/// تعرض أيقونة أصلاً فما تحتاج تخصيص.
const Map<SectionType, List<IconData>> sectionIconPresets = {
  SectionType.hostNames: [Icons.favorite, Icons.favorite_border, Icons.people_outline, Icons.diversity_3],
  SectionType.gallery: [Icons.photo_library_outlined, Icons.collections_outlined, Icons.image_outlined, Icons.photo_camera_outlined],
  SectionType.dateTime: [Icons.event_outlined, Icons.calendar_today_outlined, Icons.calendar_month_outlined, Icons.schedule_outlined],
  SectionType.location: [Icons.location_on_outlined, Icons.map_outlined, Icons.place_outlined, Icons.pin_drop_outlined],
  SectionType.rules: [Icons.info_outline, Icons.rule_outlined, Icons.checklist_outlined, Icons.notes_outlined],
  SectionType.countdown: [Icons.hourglass_bottom, Icons.timer_outlined, Icons.alarm, Icons.watch_later_outlined],
  SectionType.gifts: [Icons.card_giftcard_outlined, Icons.redeem_outlined, Icons.wallet_giftcard, Icons.volunteer_activism_outlined],
  SectionType.rsvp: [Icons.check_circle_outline, Icons.how_to_reg_outlined, Icons.event_available_outlined, Icons.task_alt_outlined],
  SectionType.whatsappContact: [Icons.chat, Icons.phone_outlined, Icons.message_outlined, Icons.contact_phone_outlined],
};

/// يرجع الأيقونة المختارة فعلياً لهذا القسم (أو أول أيقونة افتراضية لو ما فيه اختيار محفوظ)
IconData resolveSectionIcon(SectionType type, Map<String, int> chosenIndexes) {
  final presets = sectionIconPresets[type];
  if (presets == null || presets.isEmpty) return Icons.circle_outlined;
  final idx = chosenIndexes[type.name] ?? 0;
  return presets[idx.clamp(0, presets.length - 1)];
}
