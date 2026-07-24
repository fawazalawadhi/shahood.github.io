import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/event_category.dart';
import '../models/invitation_draft.dart';
import '../models/template_model.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

/// يدير قائمة القوالب: القوالب العامة (يضيفها الأدمن من نفس شاشة التصميم
/// عبر تفعيل خيار "قالب عام") وقوالب المستخدمين الخاصة.
///
/// مرتبط بجدول public.templates في Supabase: يقرأ منه عبر loadTemplates()،
/// ويكتب إليه عند الحفظ/إعادة التسمية/الحذف. تبقى نسخة بالذاكرة (_templates)
/// كحالة محلية تُبث فوراً للواجهة.
class TemplateProvider extends ChangeNotifier {
  final List<TemplateModel> _templates = [];

  bool isLoading = true;
  String? lastErrorMessage; // لو فشل الاتصال بـ Supabase، نحتفظ برسالة الخطأ للعرض/التشخيص

  List<TemplateModel> get all => List.unmodifiable(_templates);

  List<TemplateModel> systemTemplates() =>
      _templates.where((t) => t.isSystemTemplate).toList();

  List<TemplateModel> userTemplates(String userId) =>
      _templates.where((t) => !t.isSystemTemplate && t.ownerUserId == userId).toList();

  List<TemplateModel> byCategory(EventCategory category, {bool systemOnly = true}) {
    return _templates
        .where((t) => t.category == category && (!systemOnly || t.isSystemTemplate))
        .toList();
  }

  /// يجلب القوالب من جدول public.templates: القوالب العامة دائماً، بالإضافة
  /// لقوالب المستخدم الخاصة إذا كان مسجّل دخول ([userId] غير فارغ).
  /// عند فشل الاتصال (مثلاً بيانات Supabase غير مهيأة بعد) يرجع للبذور المحلية.
  Future<void> loadTemplates({String? userId}) async {
    isLoading = true;
    lastErrorMessage = null;
    notifyListeners();
    try {
      final rows = await supabase.from('templates').select();
      _templates
        ..clear()
        ..addAll((rows as List).map((r) => _templateFromRow(r as Map<String, dynamic>)));
      if (_templates.isEmpty) seedIfEmpty();
    } catch (e) {
      // لا يوجد اتصال بقاعدة البيانات بعد (أو الإعدادات غير مكتملة) - نستخدم بذور محلية مؤقتة
      lastErrorMessage = e.toString();
      seedIfEmpty();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// حفظ التصميم الحالي كقالب. [category] هو التصنيف اللي يُدرج فيه القالب
  /// بمعرض القوالب - يُختار صراحة وقت الحفظ (قد يختلف عن تصنيف المسودة
  /// الحالي، مثلاً تصميم عام يبيه المستخدم يصنّفه "خطوبة" تحديداً).
  Future<TemplateModel> saveDraftAsTemplate({
    required InvitationDraft draft,
    required String templateName,
    required String userId,
    required bool isPublicTemplate,
    required EventCategory category,
  }) async {
    final snapshot = draft.copy()..category = category;
    final template = TemplateModel(
      id: _uuid.v4(),
      name: templateName,
      category: category,
      thumbnailImagePath: draft.coverImagePath ?? '',
      draftSnapshot: snapshot,
      isSystemTemplate: isPublicTemplate,
      ownerUserId: isPublicTemplate ? null : userId,
      createdAt: DateTime.now(),
    );
    // لا نضيف القالب محلياً إلا بعد نجاح الحفظ فعلياً بقاعدة البيانات، وإلا
    // يرى المستخدم "تم الحفظ" رغم أن القالب لم يُحفظ (مثلاً بسبب تجاوز حد
    // 3 قوالب أو مشكلة اتصال). الخطأ يُرمى للمتصل ليعرضه بشكل صريح.
    await supabase.from('templates').insert(_templateToRow(template));
    _templates.add(template);
    notifyListeners();
    return template;
  }

  Future<void> renameTemplate(String id, String newName) async {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final previous = _templates[index];
    _templates[index] = previous.copyWith(name: newName);
    notifyListeners();
    try {
      await supabase.from('templates').update({'name': newName}).eq('id', id);
    } catch (e) {
      _templates[index] = previous; // تراجع عن التحديث المحلي إن فشل الحفظ فعلياً
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final removed = _templates[index];
    _templates.removeAt(index);
    notifyListeners();
    try {
      await supabase.from('templates').delete().eq('id', id);
    } catch (e) {
      _templates.insert(index, removed); // تراجع عن الحذف المحلي إن فشل الحذف فعلياً
      notifyListeners();
      rethrow;
    }
  }

  TemplateModel _templateFromRow(Map<String, dynamic> row) => TemplateModel(
        id: row['id'] as String,
        name: row['name'] as String,
        category: EventCategoryLabel.fromKey(row['category'] as String),
        thumbnailImagePath: row['thumbnail_image_path'] as String? ?? '',
        draftSnapshot: InvitationDraft.fromJson(row['draft_json'] as Map<String, dynamic>),
        isSystemTemplate: row['is_system_template'] as bool? ?? false,
        ownerUserId: row['owner_user_id'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  Map<String, dynamic> _templateToRow(TemplateModel t) => {
        'id': t.id,
        'name': t.name,
        'category': t.category.name,
        'is_system_template': t.isSystemTemplate,
        'owner_user_id': t.ownerUserId,
        'thumbnail_image_path': t.thumbnailImagePath,
        'draft_json': t.draftSnapshot.toJson(),
      };

  void seedIfEmpty() {
    if (_templates.isNotEmpty) return;

    TemplateModel makeSeed({
      required String name,
      required EventCategory category,
      required String cover,
      required int primary,
      required int secondary,
    }) {
      final draft = InvitationDraft(
        titleText: 'فلان و فلانة',
        category: category,
        coverImagePath: cover,
        welcomeNoteText: 'بسم الله نبدأ، وعلى بركة الله نجتمع لنشاركم أجمل لحظاتنا.',
        hostFamilyLine1: 'عائلة فلان الفلاني',
        hostFamilyLine2: 'عائلة فلان الفلانية',
        primaryColorValue: primary,
        secondaryColorValue: secondary,
        backgroundColorValue: AppColors.beige.value,
      );
      return TemplateModel(
        id: _uuid.v4(),
        name: name,
        category: category,
        thumbnailImagePath: cover,
        draftSnapshot: draft,
        isSystemTemplate: true,
        createdAt: DateTime.now(),
      );
    }

    _templates.addAll([
      makeSeed(
        name: 'قالب زفاف كلاسيكي',
        category: EventCategory.wedding,
        cover: 'assets/images/placeholder_wedding.jpg',
        primary: 0xFF3F6A91,
        secondary: 0xFFD98CA0,
      ),
      makeSeed(
        name: 'قالب مولود',
        category: EventCategory.newborn,
        cover: 'assets/images/placeholder_newborn.jpg',
        primary: 0xFF6E9FC7,
        secondary: 0xFFE8B4C0,
      ),
      makeSeed(
        name: 'قالب خطوبة',
        category: EventCategory.engagement,
        cover: 'assets/images/placeholder_engagement.jpg',
        primary: 0xFFD98CA0,
        secondary: 0xFF6E9FC7,
      ),
    ]);
    notifyListeners();
  }
}
