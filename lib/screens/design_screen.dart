import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/content_suggestions.dart';
import '../models/event_category.dart';
import '../models/gallery_layout.dart';
import '../models/invitation_section.dart';
import '../models/overlay_element.dart';
import '../models/section_icon_presets.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';
import '../providers/design_provider.dart';
import '../providers/template_provider.dart';
import '../theme/app_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/live_preview.dart';
import 'auth/login_screen.dart';

const _fallingPresetEmojis = ['🌹', '🌸', '❤️', '✨', '🎉', '❄️', '🕊️'];

class DesignScreen extends StatefulWidget {
  const DesignScreen({super.key});

  @override
  State<DesignScreen> createState() => _DesignScreenState();
}

class _DesignScreenState extends State<DesignScreen> {
  final _titleController = TextEditingController();
  final _welcomeNoteController = TextEditingController();
  final _familyLine1Controller = TextEditingController();
  final _familyLine2Controller = TextEditingController();
  final _locationController = TextEditingController();
  final _mapUrlController = TextEditingController();
  final _rulesController = TextEditingController();
  final _rsvpNoteController = TextEditingController();
  final _giftsController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _picker = ImagePicker();
  bool _controllersSynced = false;

  @override
  void dispose() {
    _titleController.dispose();
    _welcomeNoteController.dispose();
    _familyLine1Controller.dispose();
    _familyLine2Controller.dispose();
    _locationController.dispose();
    _mapUrlController.dispose();
    _rulesController.dispose();
    _rsvpNoteController.dispose();
    _giftsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _syncControllers(DesignProvider design) {
    final d = design.draft;
    _titleController.text = d.titleText;
    _welcomeNoteController.text = d.welcomeNoteText;
    _familyLine1Controller.text = d.hostFamilyLine1;
    _familyLine2Controller.text = d.hostFamilyLine2;
    _locationController.text = d.locationText ?? '';
    _mapUrlController.text = d.locationMapUrl ?? '';
    _rulesController.text = d.rulesText;
    _rsvpNoteController.text = d.rsvpNote ?? '';
    _giftsController.text = d.giftAccountsText ?? '';
    _whatsappController.text = d.whatsappNumber ?? '';
  }

  /// يعرض إشعار "جاري الرفع" أثناء تنفيذ [action]، ويتعامل مع أي خطأ رفع بلطف
  Future<T?> _withUploadIndicator<T>(Future<T> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('جاري رفع الملف...'), duration: Duration(seconds: 30)));
    try {
      final result = await action();
      messenger.hideCurrentSnackBar();
      return result;
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('تعذّر رفع الملف: $e')));
      return null;
    }
  }

  Future<void> _pickCoverImage(DesignProvider design) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'covers'));
    if (url != null) design.setCoverImage(url);
  }

  Future<void> _pickBackgroundImage(DesignProvider design) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'covers'));
    if (url != null) design.setBackgroundImage(url);
  }

  Future<void> _pickFallingParticleImage(DesignProvider design) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'covers'));
    if (url != null) design.setFallingParticleImage(url);
  }

  Future<void> _pickRevealVideo(DesignProvider design) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'videos'));
    if (url != null) design.setRevealVideo(url);
  }

  Future<void> _pickGalleryImage(DesignProvider design) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'covers'));
    if (url != null) design.addGalleryImage(url);
  }

  void _addTextOverlay(DesignProvider design) {
    final element = design.addTextOverlay();
    _openOverlayEditDialog(context, design, element.id);
  }

  Future<void> _addImageOverlay(DesignProvider design) async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadXFile(file, bucket: 'covers'));
    if (url == null) return;
    final element = design.addImageOverlay(url);
    if (mounted) _openOverlayEditDialog(context, design, element.id);
  }

  Future<void> _pickAudio(DesignProvider design) async {
    // نطلب البايتات دايماً (بدل الاعتماد على مسار محلي) عشان نرفعها لـ Supabase
    // بغض النظر عن المنصة، ونحصل برابط عام دائم بدل مسار مؤقت.
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result == null) return;
    final file = result.files.single;
    if (file.bytes == null) return;
    final url = await _withUploadIndicator(() => StorageService.uploadBytes(file.bytes!, file.name, bucket: 'audio'));
    if (url != null) design.setBackgroundAudio(url);
  }

  Future<void> _pickEventDateTime(DesignProvider design) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: design.draft.eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(design.draft.eventDate ?? now));
    if (time == null) return;
    design.setEventDate(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// يتأكد من وجود مستخدم مسجّل دخول قبل أي عملية كتابة (حفظ قالب أو نشر دعوة)،
  /// لأن سياسات RLS بقاعدة البيانات تتطلب ذلك. يفتح شاشة تسجيل الدخول عند الحاجة.
  Future<String?> _requireLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) return auth.userId;
    if (!context.mounted) return null;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    return auth.userId;
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final design = context.read<DesignProvider>();
    final templates = context.read<TemplateProvider>();
    final userId = await _requireLogin(context);
    if (userId == null || !context.mounted) return;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final nameController = TextEditingController();
    bool isPublic = false;
    EventCategory category = design.draft.category;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('حفظ التصميم كقالب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(hintText: 'اسم القالب'), autofocus: true),
              const SizedBox(height: 14),
              DropdownButtonFormField<EventCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'إدراج القالب في تصنيف'),
                items: EventCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.arabicLabel))).toList(),
                onChanged: (v) => setState(() => category = v!),
              ),
              if (isAdmin)
                CheckboxListTile(
                  value: isPublic,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('قالب عام (أدمن) - يظهر للجميع في المعرض'),
                  onChanged: (v) => setState(() => isPublic = v ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'name': nameController.text.trim(), 'public': isPublic, 'category': category}),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();

    if (result != null && (result['name'] as String).isNotEmpty) {
      try {
        await templates.saveDraftAsTemplate(
          draft: design.exportSnapshot(),
          templateName: result['name'] as String,
          userId: userId,
          isPublicTemplate: result['public'] as bool,
          category: result['category'] as EventCategory,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حفظ القالب باسم "${result['name']}"')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر حفظ القالب. قد تكون وصلت للحد الأقصى (3 قوالب) أو حدثت مشكلة اتصال.')),
          );
        }
      }
    }
  }

  Future<void> _publish(BuildContext context) async {
    final design = context.read<DesignProvider>();
    final error = design.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final userId = await _requireLogin(context);
    if (userId == null || !context.mounted) return;

    final String slug;
    try {
      slug = await design.publish(ownerUserId: userId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر نشر الدعوة، تحقق من الاتصال وحاول مرة أخرى')));
      }
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم نشر الدعوة 🎉'),
        content: SelectableText('azzama.com/i/$slug'),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('تمام'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final design = context.watch<DesignProvider>();
    final isWide = MediaQuery.of(context).size.width > 900;

    if (!_controllersSynced) {
      _syncControllers(design);
      _controllersSynced = true;
    }

    final preview = const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: SizedBox(width: 320, child: LivePreview())),
    );

    final controls = _ControlsPanel(
      titleController: _titleController,
      welcomeNoteController: _welcomeNoteController,
      familyLine1Controller: _familyLine1Controller,
      familyLine2Controller: _familyLine2Controller,
      locationController: _locationController,
      mapUrlController: _mapUrlController,
      rulesController: _rulesController,
      rsvpNoteController: _rsvpNoteController,
      giftsController: _giftsController,
      whatsappController: _whatsappController,
      onPickCover: () => _pickCoverImage(design),
      onPickBackgroundImage: () => _pickBackgroundImage(design),
      onPickFallingImage: () => _pickFallingParticleImage(design),
      onPickVideo: () => _pickRevealVideo(design),
      onPickGalleryImage: () => _pickGalleryImage(design),
      onAddTextOverlay: () => _addTextOverlay(design),
      onAddImageOverlay: () => _addImageOverlay(design),
      onPickAudio: () => _pickAudio(design),
      onPickDateTime: () => _pickEventDateTime(design),
      onSaveTemplate: () => _saveAsTemplate(context),
      onPublish: () => _publish(context),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('تصميم الدعوة')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.softGradient),
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 4, child: preview),
                  const VerticalDivider(width: 1),
                  Expanded(flex: 5, child: controls),
                ],
              )
            : SingleChildScrollView(child: Column(children: [preview, controls])),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController welcomeNoteController;
  final TextEditingController familyLine1Controller;
  final TextEditingController familyLine2Controller;
  final TextEditingController locationController;
  final TextEditingController mapUrlController;
  final TextEditingController rulesController;
  final TextEditingController rsvpNoteController;
  final TextEditingController giftsController;
  final TextEditingController whatsappController;
  final VoidCallback onPickCover;
  final VoidCallback onPickBackgroundImage;
  final VoidCallback onPickFallingImage;
  final VoidCallback onPickVideo;
  final VoidCallback onPickGalleryImage;
  final VoidCallback onAddTextOverlay;
  final VoidCallback onAddImageOverlay;
  final VoidCallback onPickAudio;
  final VoidCallback onPickDateTime;
  final VoidCallback onSaveTemplate;
  final VoidCallback onPublish;

  const _ControlsPanel({
    required this.titleController,
    required this.welcomeNoteController,
    required this.familyLine1Controller,
    required this.familyLine2Controller,
    required this.locationController,
    required this.mapUrlController,
    required this.rulesController,
    required this.rsvpNoteController,
    required this.giftsController,
    required this.whatsappController,
    required this.onPickCover,
    required this.onPickBackgroundImage,
    required this.onPickFallingImage,
    required this.onPickVideo,
    required this.onPickGalleryImage,
    required this.onAddTextOverlay,
    required this.onAddImageOverlay,
    required this.onPickAudio,
    required this.onPickDateTime,
    required this.onSaveTemplate,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    final design = context.read<DesignProvider>();
    final draft = context.watch<DesignProvider>().draft;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text('نوع المناسبة', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: EventCategory.values.map((cat) {
              return ChoiceChip(label: Text(cat.arabicLabel), selected: draft.category == cat, onSelected: (_) => design.setCategory(cat));
            }).toList(),
          ),
          const SizedBox(height: 10),
          _SuggestionChips(
            suggestions: ContentSuggestions.tipsFor(draft.category),
            icon: Icons.lightbulb_outline,
            onTap: (_) {}, // نصائح فقط للعرض، بدون تعبئة تلقائية
            selectable: false,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'الاسم / العنوان الرئيسي (يظهر على الغلاف)'),
            onChanged: design.setTitleText,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: OutlinedButton.icon(onPressed: onPickCover, icon: const Icon(Icons.image_outlined), label: const Text('صورة الغلاف'))),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: onPickVideo, icon: const Icon(Icons.videocam_outlined), label: const Text('فيديو الدعوة'))),
            ],
          ),
          const SizedBox(height: 24),

          const Text('عناصر متحركة فوق الفيديو', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('نص أو صورة PNG شفافة، بتوقيت وحركة مستقلة لكل عنصر', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          _OverlayElementsEditor(onAddText: onAddTextOverlay, onAddImage: onAddImageOverlay),
          const SizedBox(height: 24),

          const Text('الألوان', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ColorDot(color: Color(draft.primaryColorValue), onTap: () => _pickColor(context, Color(draft.primaryColorValue), design.setPrimaryColor)),
              const SizedBox(width: 10),
              _ColorDot(color: Color(draft.secondaryColorValue), onTap: () => _pickColor(context, Color(draft.secondaryColorValue), design.setSecondaryColor)),
              const SizedBox(width: 10),
              _ColorDot(color: Color(draft.backgroundColorValue), onTap: () => _pickColor(context, Color(draft.backgroundColorValue), design.setBackgroundColor)),
            ],
          ),
          const SizedBox(height: 16),
          Text('لون الخلفية أعلاه يُستخدم لو ما فيه صورة خلفية محددة', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickBackgroundImage,
                  icon: const Icon(Icons.wallpaper_outlined),
                  label: Text(draft.backgroundImagePath == null ? 'صورة خلفية عامة للدعوة' : 'تغيير صورة الخلفية'),
                ),
              ),
              if (draft.backgroundImagePath != null)
                IconButton(
                  tooltip: 'إزالة صورة الخلفية',
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  onPressed: design.clearBackgroundImage,
                ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('الخطوط', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('اختر خط مستقل لكل دور نصي', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          _FontDropdown(label: 'خط الأسماء البارزة', value: draft.namesFontFamily, onChanged: design.setNamesFont),
          const SizedBox(height: 10),
          _FontDropdown(label: 'خط العناوين', value: draft.titlesFontFamily, onChanged: design.setTitlesFont),
          const SizedBox(height: 10),
          _FontDropdown(label: 'خط النصوص', value: draft.bodyFontFamily, onChanged: design.setBodyFont),
          const SizedBox(height: 24),

          const Text('التأثير المتساقط', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.fallingAnimationEnabled,
            onChanged: design.setFallingAnimationEnabled,
            title: const Text('تفعيل التأثير المتساقط فوق الدعوة'),
          ),
          if (draft.fallingAnimationEnabled) ...[
            Wrap(
              spacing: 8,
              children: _fallingPresetEmojis.map((e) {
                final selected = draft.fallingParticles.contains(e);
                return FilterChip(label: Text(e, style: const TextStyle(fontSize: 18)), selected: selected, onSelected: (_) => design.toggleFallingParticle(e));
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              draft.fallingParticleImagePath == null
                  ? 'أو ارفع صورة PNG مخصصة (تُستخدم بدل الإيموجي تلقائياً)'
                  : 'يتم استخدام الصورة المرفوعة حالياً بدل الإيموجي',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickFallingImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(draft.fallingParticleImagePath == null ? 'رفع صورة PNG مخصصة' : 'تغيير الصورة'),
                  ),
                ),
                if (draft.fallingParticleImagePath != null)
                  IconButton(
                    tooltip: 'إزالة الصورة المخصصة (رجوع للإيموجي)',
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: design.clearFallingParticleImage,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('سرعة التساقط: ${draft.fallingAnimationDurationSeconds} ثانية', style: const TextStyle(fontSize: 13)),
            Slider(
              value: draft.fallingAnimationDurationSeconds.toDouble(),
              min: 3,
              max: 20,
              divisions: 17,
              label: '${draft.fallingAnimationDurationSeconds}s',
              onChanged: (v) => design.setFallingAnimationDuration(v.round()),
            ),
          ],
          const SizedBox(height: 24),

          const Text('الموسيقى الخلفية', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickAudio,
                  icon: const Icon(Icons.music_note_outlined),
                  label: Text(draft.backgroundAudioPath == null ? 'رفع ملف صوتي' : 'تم اختيار الملف ✓'),
                ),
              ),
              const SizedBox(width: 10),
              Switch(value: draft.backgroundAudioEnabled, onChanged: design.setBackgroundAudioEnabled),
            ],
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 8),
          const Text('صفحة التفاصيل (بعد الكشف)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text('فعّل/أخفِ كل قسم، وأعد ترتيبها بالسحب', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          _SectionsReorderList(),

          const SizedBox(height: 20),
          const Text('تخصيص الأيقونات', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('اختر شكل الأيقونة لكل قسم', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          const _SectionIconsEditor(),

          const SizedBox(height: 20),
          const Text('محتوى الأقسام', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
            controller: welcomeNoteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'شعر / آية / عبارة ترحيبية'),
            onChanged: design.setWelcomeNoteText,
          ),
          const SizedBox(height: 8),
          _SuggestionChips(
            suggestions: ContentSuggestions.welcomeNotesFor(draft.category),
            icon: Icons.auto_awesome_outlined,
            onTap: (text) {
              welcomeNoteController.text = text;
              design.setWelcomeNoteText(text);
            },
          ),
          const SizedBox(height: 20),

          TextField(controller: familyLine1Controller, decoration: const InputDecoration(labelText: 'اسم الأهل - السطر الأول (مثال: عائلة فلان)'), onChanged: design.setHostFamilyLine1),
          const SizedBox(height: 12),
          TextField(controller: familyLine2Controller, decoration: const InputDecoration(labelText: 'اسم الأهل - السطر الثاني (مثال: عائلة فلان)'), onChanged: design.setHostFamilyLine2),
          const SizedBox(height: 20),

          TextField(
            controller: rulesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'قواعد وتعليمات الحفل (اختياري)'),
            onChanged: design.setRulesText,
          ),
          const SizedBox(height: 20),

          _GalleryEditor(onPickImage: onPickGalleryImage),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: onPickDateTime,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(draft.eventDate == null ? 'اختر التاريخ والوقت' : draft.eventDate.toString()),
          ),
          const SizedBox(height: 14),

          TextField(controller: locationController, decoration: const InputDecoration(labelText: 'اسم الموقع / القاعة'), onChanged: design.setLocationText),
          const SizedBox(height: 14),
          TextField(controller: mapUrlController, decoration: const InputDecoration(labelText: 'رابط خرائط جوجل (اختياري)'), onChanged: design.setLocationMapUrl),
          const SizedBox(height: 20),

          TextField(
            controller: giftsController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'حسابات الهدايا (آيبان / STC Pay / رقم حساب)'),
            onChanged: design.setGiftAccountsText,
          ),
          const SizedBox(height: 20),

          TextField(
            controller: whatsappController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'رقم واتساب للتواصل (بصيغة دولية، مثال: 9665xxxxxxx)'),
            onChanged: design.setWhatsappNumber,
          ),
          const SizedBox(height: 20),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: draft.rsvpAllowGuestCount,
            onChanged: design.setRsvpAllowGuestCount,
            title: const Text('السماح بتحديد عدد المرافقين في RSVP'),
          ),
          TextField(controller: rsvpNoteController, decoration: const InputDecoration(labelText: 'ملاحظة فوق زر تأكيد الحضور (اختياري)'), onChanged: design.setRsvpNote),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onSaveTemplate, child: const Text('حفظ كقالب'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: onPublish, child: const Text('نشر الدعوة'))),
            ],
          ),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context, Color currentColor, void Function(Color) onSelected) {
    showDialog(context: context, builder: (ctx) => _FullColorPickerDialog(initialColor: currentColor, onSelected: onSelected));
  }
}

class _FontDropdown extends StatelessWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;
  const _FontDropdown({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: AppFonts.available
          .map((f) => DropdownMenuItem(value: f, child: Text(f, style: AppFonts.style(f, fontSize: 15))))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final IconData icon;
  final void Function(String) onTap;
  final bool selectable;
  const _SuggestionChips({required this.suggestions, required this.icon, required this.onTap, this.selectable = true});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((s) {
        return ActionChip(
          avatar: Icon(icon, size: 16),
          label: Text(s.length > 34 ? '${s.substring(0, 34)}...' : s, style: const TextStyle(fontSize: 12)),
          onPressed: selectable ? () => onTap(s) : () {},
        );
      }).toList(),
    );
  }
}

class _GalleryEditor extends StatelessWidget {
  final VoidCallback onPickImage;
  const _GalleryEditor({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final design = context.read<DesignProvider>();
    final draft = context.watch<DesignProvider>().draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('معرض الصور (حتى 4 صور)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final path in draft.galleryImagePaths)
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade300,
                    ),
                    child: const Icon(Icons.image, color: Colors.white70),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => design.removeGalleryImage(path),
                      child: const CircleAvatar(radius: 11, backgroundColor: Colors.redAccent, child: Icon(Icons.close, size: 14, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            if (draft.galleryImagePaths.length < 4)
              InkWell(
                onTap: onPickImage,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: GalleryLayout.values.map((l) {
            return ChoiceChip(label: Text(l.arabicLabel), selected: draft.galleryLayout == l, onSelected: (_) => design.setGalleryLayout(l));
          }).toList(),
        ),
      ],
    );
  }
}

/// يعرض قائمة العناصر المتحركة الحالية (نص/صورة) مع أزرار تعديل وحذف،
/// وزرين لإضافة عنصر جديد. نفس أسلوب _GalleryEditor بالضبط.
class _OverlayElementsEditor extends StatelessWidget {
  final VoidCallback onAddText;
  final VoidCallback onAddImage;
  const _OverlayElementsEditor({required this.onAddText, required this.onAddImage});

  @override
  Widget build(BuildContext context) {
    final design = context.read<DesignProvider>();
    final elements = context.watch<DesignProvider>().draft.overlayElements;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (elements.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('ما فيه عناصر متحركة بعد', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          )
        else
          ...elements.map((el) {
            final label = el.type == OverlayElementType.text
                ? (el.text.isEmpty ? 'نص فارغ' : el.text)
                : 'صورة PNG';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(el.type == OverlayElementType.text ? Icons.text_fields : Icons.image_outlined),
                title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('يبدأ عند ${el.startDelaySeconds.toStringAsFixed(1)}ث - مدة ${el.durationSeconds.toStringAsFixed(1)}ث - ${el.animationType.arabicLabel}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openOverlayEditDialog(context, design, el.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => design.removeOverlay(el.id),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(onPressed: onAddText, icon: const Icon(Icons.text_fields), label: const Text('إضافة نص متحرك')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(onPressed: onAddImage, icon: const Icon(Icons.image_outlined), label: const Text('إضافة صورة PNG')),
            ),
          ],
        ),
      ],
    );
  }
}

/// نافذة تعديل خصائص عنصر متحرك واحد: المحتوى، الموقع، الحجم، الشفافية،
/// توقيت الظهور، ونوع الأنيميشن. كل تغيير ينعكس فوراً على المعاينة الحية
/// لأنه يُطبَّق مباشرة عبر design.updateOverlay.
void _openOverlayEditDialog(BuildContext context, DesignProvider design, String elementId) {
  showDialog(
    context: context,
    builder: (ctx) => _OverlayEditDialog(design: design, elementId: elementId),
  );
}

class _OverlayEditDialog extends StatefulWidget {
  final DesignProvider design;
  final String elementId;
  const _OverlayEditDialog({required this.design, required this.elementId});

  @override
  State<_OverlayEditDialog> createState() => _OverlayEditDialogState();
}

class _OverlayEditDialogState extends State<_OverlayEditDialog> {
  late final TextEditingController _textController;

  OverlayElement get _element => widget.design.draft.overlayElements.firstWhere((e) => e.id == widget.elementId);

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _element.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _update(void Function(OverlayElement el) fn) {
    widget.design.updateOverlay(widget.elementId, fn);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final el = _element;

    return AlertDialog(
      title: Text(el.type == OverlayElementType.text ? 'تعديل نص متحرك' : 'تعديل صورة متحركة'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (el.type == OverlayElementType.text) ...[
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(labelText: 'النص'),
                  onChanged: (v) => _update((e) => e.text = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: el.fontFamily,
                  decoration: const InputDecoration(labelText: 'الخط'),
                  items: AppFonts.available.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (v) => _update((e) => e.fontFamily = v!),
                ),
                const SizedBox(height: 8),
                Text('حجم الخط: ${el.fontSize.toStringAsFixed(0)}'),
                Slider(value: el.fontSize, min: 10, max: 60, onChanged: (v) => _update((e) => e.fontSize = v)),
              ] else ...[
                const Text('صورة PNG (يفضّل بخلفية شفافة)', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
              const SizedBox(height: 8),
              Text('العرض: ${(el.widthFraction * 100).toStringAsFixed(0)}%'),
              Slider(value: el.widthFraction, min: 0.1, max: 1.0, onChanged: (v) => _update((e) => e.widthFraction = v)),
              Text('الشفافية: ${(el.opacity * 100).toStringAsFixed(0)}%'),
              Slider(value: el.opacity, min: 0.1, max: 1.0, onChanged: (v) => _update((e) => e.opacity = v)),
              Text('الموقع الأفقي'),
              Slider(value: el.positionX, min: -1, max: 1, onChanged: (v) => _update((e) => e.positionX = v)),
              Text('الموقع الرأسي'),
              Slider(value: el.positionY, min: -1, max: 1, onChanged: (v) => _update((e) => e.positionY = v)),
              const Divider(),
              Text('وقت البداية: ${el.startDelaySeconds.toStringAsFixed(1)} ثانية بعد بداية الفيديو'),
              Slider(value: el.startDelaySeconds, min: 0, max: 15, onChanged: (v) => _update((e) => e.startDelaySeconds = v)),
              Text('مدة الحركة: ${el.durationSeconds.toStringAsFixed(1)} ثانية'),
              Slider(value: el.durationSeconds, min: 0.2, max: 5, onChanged: (v) => _update((e) => e.durationSeconds = v)),
              DropdownButtonFormField<OverlayAnimationType>(
                initialValue: el.animationType,
                decoration: const InputDecoration(labelText: 'نوع الأنيميشن'),
                items: OverlayAnimationType.values
                    .map((a) => DropdownMenuItem(value: a, child: Text(a.arabicLabel)))
                    .toList(),
                onChanged: (v) => _update((e) => e.animationType = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('تم')),
      ],
    );
  }
}

class _SectionsReorderList extends StatefulWidget {
  @override
  State<_SectionsReorderList> createState() => _SectionsReorderListState();
}

class _SectionsReorderListState extends State<_SectionsReorderList> {
  final _picker = ImagePicker();
  SectionType? _uploadingType;

  Future<void> _pickBackground(BuildContext context, SectionType type) async {
    final design = context.read<DesignProvider>();
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploadingType = type);
    try {
      final url = await StorageService.uploadXFile(file, bucket: 'covers');
      design.setSectionBackgroundImage(type, url);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('تعذّر رفع الصورة: $e')));
    } finally {
      if (mounted) setState(() => _uploadingType = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final design = context.read<DesignProvider>();
    final draft = context.watch<DesignProvider>().draft;
    final sorted = List.of(draft.sections)..sort((a, b) => a.order.compareTo(b.order));

    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: design.reorderSections,
      children: [
        for (final section in sorted)
          Card(
            key: ValueKey(section.type),
            margin: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                SwitchListTile(
                  value: section.enabled,
                  onChanged: (v) => design.toggleSection(section.type, v),
                  title: Text(section.type.arabicLabel),
                  secondary: const Icon(Icons.drag_handle),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('صورة خلفية للقسم', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Spacer(),
                      if (_uploadingType == section.type)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else ...[
                        if ((draft.sectionBackgroundImage[section.type.name] ?? '').isNotEmpty)
                          IconButton(
                            tooltip: 'إزالة الصورة',
                            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                            onPressed: () => design.clearSectionBackgroundImage(section.type),
                          ),
                        TextButton.icon(
                          onPressed: () => _pickBackground(context, section.type),
                          icon: const Icon(Icons.upload_outlined, size: 16),
                          label: Text((draft.sectionBackgroundImage[section.type.name] ?? '').isEmpty ? 'إضافة' : 'تغيير'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// يعرض لكل قسم له بدائل أيقونات (من sectionIconPresets) صفاً من الخيارات
/// يقدر المستخدم يضغط عليها لتغيير شكل الأيقونة في الدعوة النهائية.
class _SectionIconsEditor extends StatelessWidget {
  const _SectionIconsEditor();

  @override
  Widget build(BuildContext context) {
    final design = context.read<DesignProvider>();
    final draft = context.watch<DesignProvider>().draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sectionIconPresets.entries.map((entry) {
        final type = entry.key;
        final options = entry.value;
        final selectedIndex = draft.sectionIconChoice[type.name] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(type.arabicLabel, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: List.generate(options.length, (i) {
                    final selected = i == selectedIndex;
                    return InkWell(
                      onTap: () => design.setSectionIcon(type, i),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.blue.withOpacity(0.18) : Colors.transparent,
                          border: Border.all(color: selected ? AppColors.blueDeep : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(options[i], size: 18, color: selected ? AppColors.blueDeep : Colors.grey.shade700),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _ColorDot({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)]),
      ),
    );
  }
}

class _FullColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final void Function(Color) onSelected;
  const _FullColorPickerDialog({required this.initialColor, required this.onSelected});

  @override
  State<_FullColorPickerDialog> createState() => _FullColorPickerDialogState();
}

class _FullColorPickerDialogState extends State<_FullColorPickerDialog> {
  late Color _current = widget.initialColor;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('اختر أي لون تحبه'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _current,
          onColorChanged: (c) => setState(() => _current = c),
          enableAlpha: false,
          displayThumbColor: true,
          portraitOnly: true,
          pickerAreaHeightPercent: 0.7,
          labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: () {
            widget.onSelected(_current);
            Navigator.pop(context);
          },
          child: const Text('استخدام هذا اللون'),
        ),
      ],
    );
  }
}
