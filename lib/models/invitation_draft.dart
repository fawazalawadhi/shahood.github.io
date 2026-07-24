import 'event_category.dart';
import 'gallery_layout.dart';
import 'overlay_element.dart';
import 'invitation_section.dart';

/// يمثّل مسودة الدعوة كاملة أثناء التصميم: من صورة الغلاف إلى كل قسم
/// من أقسام صفحة التفاصيل. هذا الكائن بالكامل يُبث لحظياً لشاشة المعاينة
/// عبر DesignProvider، وهو نفسه اللي يُحفظ كـ"لقطة كاملة" عند حفظ التصميم كقالب.
class InvitationDraft {
  // -------- الغلاف (قبل الكشف) --------
  String titleText; // مثال: "أحمد و سارة" أو "بشرى مولود"
  EventCategory category;
  String? coverImagePath;
  String? backgroundImagePath; // صورة خلفية عامة تغطي كامل الدعوة (بدل اللون فقط)
  String? revealVideoPath; // فيديو يرفعه المستخدم خاص بهذه الدعوة

  // -------- قسم: شعر / آية / عبارة ترحيبية --------
  String welcomeNoteText;

  // -------- قسم: أسماء الطرفين (كل عائلة سطر لحالها) --------
  String hostFamilyLine1; // مثال: "عائلة الشيخ فلان"
  String hostFamilyLine2; // مثال: "عائلة فلان"

  // -------- قسم: التاريخ والوقت --------
  DateTime? eventDate;

  // -------- قسم: الموقع --------
  String? locationText;
  String? locationMapUrl;

  // -------- قسم: صور إضافية (حتى 4 صور) --------
  List<String> galleryImagePaths;
  GalleryLayout galleryLayout;

  // -------- قسم: قواعد وتعليمات الحفل --------
  String rulesText;

  // -------- قسم: عداد تنازلي --------
  // يعتمد على eventDate، لا يحتاج حقول إضافية

  // -------- قسم: الهدايا (نص حر يظهر عند الضغط: آيبان/STC Pay/رقم حساب) --------
  String? giftAccountsText;

  // -------- قسم: تواصل واتساب --------
  String? whatsappNumber; // بصيغة دولية بدون +، مثال: 9665xxxxxxxx

  // -------- قسم: تأكيد الحضور (RSVP) --------
  bool rsvpAllowGuestCount;
  String? rsvpNote;

  // -------- خلفية صوتية --------
  String? backgroundAudioPath;
  bool backgroundAudioEnabled;

  // -------- تأثير العناصر المتساقطة (إيموجي متساقط فوق الدعوة) --------
  bool fallingAnimationEnabled;
  List<String> fallingParticles; // مثال: ['🌹','✨']
  String? fallingParticleImagePath; // صورة PNG مخصصة - لو محددة تُستخدم بدل الإيموجي
  int fallingAnimationDurationSeconds; // "المؤقت": سرعة/مدة دورة التساقط الكاملة

  // -------- الألوان --------
  int primaryColorValue;
  int secondaryColorValue;
  int backgroundColorValue;

  // -------- الخطوط: كل نوع نص له خط مستقل يتحكم فيه الأدمن --------
  String namesFontFamily; // الأسماء البارزة (العنوان الرئيسي + أسماء العائلتين)
  String titlesFontFamily; // عناوين الأقسام الصغيرة داخل صفحة التفاصيل
  String bodyFontFamily; // النصوص العادية (الشعر، القواعد، الوصف...)

  // -------- إعدادات الأقسام: التفعيل والترتيب --------
  List<SectionConfig> sections;

  // -------- عناصر متحركة تظهر فوق الفيديو أثناء تشغيله --------
  List<OverlayElement> overlayElements;

  // -------- تخصيص أيقونات الأقسام: SectionType.name -> فهرس الأيقونة المختارة --------
  Map<String, int> sectionIconChoice;

  // -------- صورة خلفية مخصصة لكل قسم على حدة: SectionType.name -> رابط/مسار الصورة --------
  // مثلاً وضع صورة القاعة خلف قسم "الموقع"، أو صورة زخرفية خلف قسم "الشعر".
  Map<String, String> sectionBackgroundImage;

  // -------- ربط/نشر --------
  String? baseTemplateId;
  String? slug;
  bool isPublished;

  InvitationDraft({
    this.titleText = '',
    this.category = EventCategory.general,
    this.coverImagePath,
    this.backgroundImagePath,
    this.revealVideoPath,
    this.welcomeNoteText = '',
    this.hostFamilyLine1 = '',
    this.hostFamilyLine2 = '',
    this.eventDate,
    this.locationText,
    this.locationMapUrl,
    List<String>? galleryImagePaths,
    this.galleryLayout = GalleryLayout.sideBySide,
    this.rulesText = '',
    this.giftAccountsText,
    this.whatsappNumber,
    this.rsvpAllowGuestCount = true,
    this.rsvpNote,
    this.backgroundAudioPath,
    this.backgroundAudioEnabled = false,
    this.fallingAnimationEnabled = false,
    List<String>? fallingParticles,
    this.fallingParticleImagePath,
    this.fallingAnimationDurationSeconds = 8,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    required this.backgroundColorValue,
    this.namesFontFamily = 'Tajawal',
    this.titlesFontFamily = 'Tajawal',
    this.bodyFontFamily = 'Tajawal',
    List<SectionConfig>? sections,
    List<OverlayElement>? overlayElements,
    Map<String, int>? sectionIconChoice,
    Map<String, String>? sectionBackgroundImage,
    this.baseTemplateId,
    this.slug,
    this.isPublished = false,
  })  : galleryImagePaths = galleryImagePaths ?? [],
        fallingParticles = fallingParticles ?? [],
        sections = sections ?? SectionConfig.defaults(),
        overlayElements = overlayElements ?? [],
        sectionIconChoice = sectionIconChoice ?? {},
        sectionBackgroundImage = sectionBackgroundImage ?? {};

  /// ترتيب الأقسام المفعّلة فقط، جاهزة للعرض بالترتيب الصحيح
  List<SectionConfig> get enabledSectionsInOrder {
    final list = sections.where((s) => s.enabled).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  InvitationDraft copy() => InvitationDraft.fromJson(toJson());

  Map<String, dynamic> toJson() => {
        'titleText': titleText,
        'category': category.name,
        'coverImagePath': coverImagePath,
        'backgroundImagePath': backgroundImagePath,
        'revealVideoPath': revealVideoPath,
        'welcomeNoteText': welcomeNoteText,
        'hostFamilyLine1': hostFamilyLine1,
        'hostFamilyLine2': hostFamilyLine2,
        'eventDate': eventDate?.toIso8601String(),
        'locationText': locationText,
        'locationMapUrl': locationMapUrl,
        'galleryImagePaths': galleryImagePaths,
        'galleryLayout': galleryLayout.name,
        'rulesText': rulesText,
        'giftAccountsText': giftAccountsText,
        'whatsappNumber': whatsappNumber,
        'rsvpAllowGuestCount': rsvpAllowGuestCount,
        'rsvpNote': rsvpNote,
        'backgroundAudioPath': backgroundAudioPath,
        'backgroundAudioEnabled': backgroundAudioEnabled,
        'fallingAnimationEnabled': fallingAnimationEnabled,
        'fallingParticles': fallingParticles,
        'fallingParticleImagePath': fallingParticleImagePath,
        'fallingAnimationDurationSeconds': fallingAnimationDurationSeconds,
        'primaryColorValue': primaryColorValue,
        'secondaryColorValue': secondaryColorValue,
        'backgroundColorValue': backgroundColorValue,
        'namesFontFamily': namesFontFamily,
        'titlesFontFamily': titlesFontFamily,
        'bodyFontFamily': bodyFontFamily,
        'sections': sections.map((s) => s.toJson()).toList(),
        'overlayElements': overlayElements.map((e) => e.toJson()).toList(),
        'sectionIconChoice': sectionIconChoice,
        'sectionBackgroundImage': sectionBackgroundImage,
        'baseTemplateId': baseTemplateId,
        'slug': slug,
        'isPublished': isPublished,
      };

  factory InvitationDraft.fromJson(Map<String, dynamic> json) => InvitationDraft(
        titleText: json['titleText'] as String? ?? '',
        category: EventCategoryLabel.fromKey(json['category'] as String? ?? 'general'),
        coverImagePath: json['coverImagePath'] as String?,
        backgroundImagePath: json['backgroundImagePath'] as String?,
        revealVideoPath: json['revealVideoPath'] as String?,
        welcomeNoteText: json['welcomeNoteText'] as String? ?? '',
        hostFamilyLine1: json['hostFamilyLine1'] as String? ?? '',
        hostFamilyLine2: json['hostFamilyLine2'] as String? ?? '',
        eventDate: json['eventDate'] != null ? DateTime.parse(json['eventDate'] as String) : null,
        locationText: json['locationText'] as String?,
        locationMapUrl: json['locationMapUrl'] as String?,
        galleryImagePaths: (json['galleryImagePaths'] as List?)?.map((e) => e as String).toList() ?? [],
        galleryLayout: GalleryLayoutLabel.fromKey(json['galleryLayout'] as String? ?? 'sideBySide'),
        rulesText: json['rulesText'] as String? ?? '',
        giftAccountsText: json['giftAccountsText'] as String?,
        whatsappNumber: json['whatsappNumber'] as String?,
        rsvpAllowGuestCount: json['rsvpAllowGuestCount'] as bool? ?? true,
        rsvpNote: json['rsvpNote'] as String?,
        backgroundAudioPath: json['backgroundAudioPath'] as String?,
        backgroundAudioEnabled: json['backgroundAudioEnabled'] as bool? ?? false,
        fallingAnimationEnabled: json['fallingAnimationEnabled'] as bool? ?? false,
        fallingParticles: (json['fallingParticles'] as List?)?.map((e) => e as String).toList() ?? [],
        fallingParticleImagePath: json['fallingParticleImagePath'] as String?,
        fallingAnimationDurationSeconds: json['fallingAnimationDurationSeconds'] as int? ?? 8,
        primaryColorValue: json['primaryColorValue'] as int,
        secondaryColorValue: json['secondaryColorValue'] as int,
        backgroundColorValue: json['backgroundColorValue'] as int,
        namesFontFamily: json['namesFontFamily'] as String? ?? 'Tajawal',
        titlesFontFamily: json['titlesFontFamily'] as String? ?? 'Tajawal',
        bodyFontFamily: json['bodyFontFamily'] as String? ?? 'Tajawal',
        sections: (json['sections'] as List?)
                ?.map((e) => SectionConfig.fromJson(e as Map<String, dynamic>))
                .toList() ??
            SectionConfig.defaults(),
        overlayElements: (json['overlayElements'] as List?)
                ?.map((e) => OverlayElement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        sectionIconChoice: (json['sectionIconChoice'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
        sectionBackgroundImage:
            (json['sectionBackgroundImage'] as Map?)?.map((k, v) => MapEntry(k as String, v as String)) ?? {},
        baseTemplateId: json['baseTemplateId'] as String?,
        slug: json['slug'] as String?,
        isPublished: json['isPublished'] as bool? ?? false,
      );
}
