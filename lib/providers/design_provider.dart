import 'package:flutter/material.dart';
import '../models/event_category.dart';
import '../models/gallery_layout.dart';
import '../models/invitation_draft.dart';
import '../models/invitation_section.dart';
import '../models/overlay_element.dart';
import '../models/template_model.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';

/// هذا الـ Provider هو قلب شاشة "تصميم الدعوة".
/// أي تعديل يسويه المستخدم يمر من هنا، وبفضل ChangeNotifier، تنعكس
/// المعاينة اليسرى فوراً بدون أي إعادة بناء يدوية.
class DesignProvider extends ChangeNotifier {
  InvitationDraft _draft = InvitationDraft(
    primaryColorValue: AppColors.blueDeep.value,
    secondaryColorValue: AppColors.pinkDeep.value,
    backgroundColorValue: AppColors.beige.value,
  );

  InvitationDraft get draft => _draft;

  void loadFromTemplate(TemplateModel template) {
    _draft = template.draftSnapshot.copy()
      ..baseTemplateId = template.id
      ..isPublished = false
      ..slug = null;
    notifyListeners();
  }

  void resetBlank() {
    _draft = InvitationDraft(
      primaryColorValue: AppColors.blueDeep.value,
      secondaryColorValue: AppColors.pinkDeep.value,
      backgroundColorValue: AppColors.beige.value,
    );
    notifyListeners();
  }

  InvitationDraft exportSnapshot() => _draft.copy();

  // --- الغلاف والنصوص الأساسية ---
  void setTitleText(String value) {
    _draft.titleText = value;
    notifyListeners();
  }

  void setCategory(EventCategory category) {
    _draft.category = category;
    notifyListeners();
  }

  void setCoverImage(String path) {
    _draft.coverImagePath = path;
    notifyListeners();
  }

  void setBackgroundImage(String path) {
    _draft.backgroundImagePath = path;
    notifyListeners();
  }

  void clearBackgroundImage() {
    _draft.backgroundImagePath = null;
    notifyListeners();
  }

  void setRevealVideo(String path) {
    _draft.revealVideoPath = path;
    notifyListeners();
  }

  // --- شعر / آية / عبارة ترحيبية ---
  void setWelcomeNoteText(String value) {
    _draft.welcomeNoteText = value;
    notifyListeners();
  }

  // --- أسماء الطرفين (كل عائلة سطر لحالها) ---
  void setHostFamilyLine1(String value) {
    _draft.hostFamilyLine1 = value;
    notifyListeners();
  }

  void setHostFamilyLine2(String value) {
    _draft.hostFamilyLine2 = value;
    notifyListeners();
  }

  // --- التاريخ والوقت ---
  void setEventDate(DateTime date) {
    _draft.eventDate = date;
    notifyListeners();
  }

  // --- الموقع ---
  void setLocationText(String value) {
    _draft.locationText = value;
    notifyListeners();
  }

  void setLocationMapUrl(String value) {
    _draft.locationMapUrl = value;
    notifyListeners();
  }

  // --- معرض الصور (حتى 4 صور) ---
  void addGalleryImage(String path) {
    if (_draft.galleryImagePaths.length >= 4) return;
    _draft.galleryImagePaths.add(path);
    notifyListeners();
  }

  void removeGalleryImage(String path) {
    _draft.galleryImagePaths.remove(path);
    notifyListeners();
  }

  void setGalleryLayout(GalleryLayout layout) {
    _draft.galleryLayout = layout;
    notifyListeners();
  }

  // --- قواعد وتعليمات الحفل ---
  void setRulesText(String value) {
    _draft.rulesText = value;
    notifyListeners();
  }

  // --- الهدايا (نص حر) ---
  void setGiftAccountsText(String value) {
    _draft.giftAccountsText = value;
    notifyListeners();
  }

  // --- تواصل واتساب ---
  void setWhatsappNumber(String value) {
    _draft.whatsappNumber = value;
    notifyListeners();
  }

  // --- تأكيد الحضور RSVP ---
  void setRsvpAllowGuestCount(bool value) {
    _draft.rsvpAllowGuestCount = value;
    notifyListeners();
  }

  void setRsvpNote(String value) {
    _draft.rsvpNote = value;
    notifyListeners();
  }

  // --- الصوت الخلفي ---
  void setBackgroundAudio(String path) {
    _draft.backgroundAudioPath = path;
    _draft.backgroundAudioEnabled = true;
    notifyListeners();
  }

  void setBackgroundAudioEnabled(bool value) {
    _draft.backgroundAudioEnabled = value;
    notifyListeners();
  }

  // --- تأثير العناصر المتساقطة ---
  void setFallingAnimationEnabled(bool value) {
    _draft.fallingAnimationEnabled = value;
    notifyListeners();
  }

  void toggleFallingParticle(String emoji) {
    if (_draft.fallingParticles.contains(emoji)) {
      _draft.fallingParticles.remove(emoji);
    } else {
      _draft.fallingParticles.add(emoji);
    }
    notifyListeners();
  }

  void setFallingParticleImage(String path) {
    _draft.fallingParticleImagePath = path;
    notifyListeners();
  }

  void clearFallingParticleImage() {
    _draft.fallingParticleImagePath = null;
    notifyListeners();
  }

  void setFallingAnimationDuration(int seconds) {
    _draft.fallingAnimationDurationSeconds = seconds;
    notifyListeners();
  }

  // --- التحكم بالأقسام: تفعيل/إخفاء وإعادة ترتيب ---
  void toggleSection(SectionType type, bool enabled) {
    final section = _draft.sections.firstWhere((s) => s.type == type);
    section.enabled = enabled;
    notifyListeners();
  }

  void reorderSections(int oldIndex, int newIndex) {
    final sorted = List<SectionConfig>.from(_draft.sections)..sort((a, b) => a.order.compareTo(b.order));
    if (newIndex > oldIndex) newIndex -= 1;
    final item = sorted.removeAt(oldIndex);
    sorted.insert(newIndex, item);
    for (var i = 0; i < sorted.length; i++) {
      sorted[i].order = i;
    }
    _draft.sections = sorted;
    notifyListeners();
  }

  // --- العناصر المتحركة فوق الفيديو ---
  String _newOverlayId() => 'ov_${DateTime.now().microsecondsSinceEpoch}';

  OverlayElement addTextOverlay() {
    final element = OverlayElement(id: _newOverlayId(), type: OverlayElementType.text, text: 'نص جديد');
    _draft.overlayElements.add(element);
    notifyListeners();
    return element;
  }

  OverlayElement addImageOverlay(String path) {
    final element = OverlayElement(id: _newOverlayId(), type: OverlayElementType.image, imagePath: path, widthFraction: 0.4);
    _draft.overlayElements.add(element);
    notifyListeners();
    return element;
  }

  void updateOverlay(String id, void Function(OverlayElement el) update) {
    final el = _draft.overlayElements.firstWhere((e) => e.id == id);
    update(el);
    notifyListeners();
  }

  void removeOverlay(String id) {
    _draft.overlayElements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- تخصيص أيقونات الأقسام ---
  void setSectionIcon(SectionType type, int iconIndex) {
    _draft.sectionIconChoice[type.name] = iconIndex;
    notifyListeners();
  }

  // --- الألوان ---
  void setPrimaryColor(Color color) {
    _draft.primaryColorValue = color.value;
    notifyListeners();
  }

  void setSecondaryColor(Color color) {
    _draft.secondaryColorValue = color.value;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _draft.backgroundColorValue = color.value;
    notifyListeners();
  }

  // --- الخطوط: كل نوع نص مستقل ---
  void setNamesFont(String font) {
    _draft.namesFontFamily = font;
    notifyListeners();
  }

  void setTitlesFont(String font) {
    _draft.titlesFontFamily = font;
    notifyListeners();
  }

  void setBodyFont(String font) {
    _draft.bodyFontFamily = font;
    notifyListeners();
  }

  // --- التحقق قبل النشر ---
  /// يرجع رسالة خطأ لو ناقص شي أساسي، أو null لو كل شي تمام
  String? validate() {
    if (_draft.titleText.trim().isEmpty) return 'أدخل الاسم / العنوان الرئيسي قبل النشر';
    if (_draft.coverImagePath == null || _draft.coverImagePath!.isEmpty) {
      return 'أضف صورة الغلاف قبل النشر';
    }
    return null;
  }

  // --- النشر ---
  /// ينشر الدعوة ويحفظها بجدول public.invitations. [ownerUserId] مطلوب لأن
  /// سياسة RLS بالجدول تسمح بالإدراج فقط لصاحب الدعوة (auth.uid() = owner_user_id).
  Future<String> publish({required String ownerUserId}) async {
    final base = _draft.titleText
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^\w\-\u0600-\u06FF]'), '');
    final shortId = DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(4);
    final slug = '${base.isEmpty ? 'invite' : base}-$shortId';

    await supabase.from('invitations').insert({
      'slug': slug,
      'owner_user_id': ownerUserId,
      'draft_json': _draft.toJson(),
    });

    _draft.slug = slug;
    _draft.isPublished = true;
    notifyListeners();
    return slug;
  }
}
