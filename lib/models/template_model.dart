import 'event_category.dart';
import 'invitation_draft.dart';

/// يمثّل قالب دعوة: إما قالب عام أضافه الأدمن (isSystemTemplate = true)
/// أو قالب خاص حفظه مستخدم بعد تصميمه (isSystemTemplate = false).
///
/// القالب هنا هو ببساطة "لقطة كاملة" (snapshot) من InvitationDraft وقت الحفظ:
/// كل الأقسام، محتواها، ترتيبها، وحالتها، بالإضافة لاسم القالب وتصنيفه.
/// هذا يعني: نفس شاشة التصميم يستخدمها المستخدم العادي والأدمن، والفرق فقط
/// في checkbox "قالب عام" وقت الحفظ.
class TemplateModel {
  final String id;
  final String name; // اسم القالب في معرض القوالب
  final EventCategory category;
  final String thumbnailImagePath; // نفس صورة الغلاف - تُستخدم كصورة مصغرة بالمعرض

  final InvitationDraft draftSnapshot; // اللقطة الكاملة القابلة لإعادة التحميل بالكامل

  final bool isSystemTemplate;
  final String? ownerUserId; // فارغ للقوالب العامة
  final DateTime createdAt;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.category,
    required this.thumbnailImagePath,
    required this.draftSnapshot,
    required this.isSystemTemplate,
    this.ownerUserId,
    required this.createdAt,
  });

  TemplateModel copyWith({
    String? name,
    EventCategory? category,
    String? thumbnailImagePath,
    InvitationDraft? draftSnapshot,
    bool? isSystemTemplate,
  }) {
    return TemplateModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      thumbnailImagePath: thumbnailImagePath ?? this.thumbnailImagePath,
      draftSnapshot: draftSnapshot ?? this.draftSnapshot,
      isSystemTemplate: isSystemTemplate ?? this.isSystemTemplate,
      ownerUserId: ownerUserId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'thumbnailImagePath': thumbnailImagePath,
        'draftSnapshot': draftSnapshot.toJson(),
        'isSystemTemplate': isSystemTemplate,
        'ownerUserId': ownerUserId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TemplateModel.fromJson(Map<String, dynamic> json) => TemplateModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: EventCategoryLabel.fromKey(json['category'] as String),
        thumbnailImagePath: json['thumbnailImagePath'] as String,
        draftSnapshot: InvitationDraft.fromJson(json['draftSnapshot'] as Map<String, dynamic>),
        isSystemTemplate: json['isSystemTemplate'] as bool,
        ownerUserId: json['ownerUserId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
