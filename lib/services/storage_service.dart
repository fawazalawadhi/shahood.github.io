import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

const _uuid = Uuid();

/// خدمة موحّدة لرفع الملفات (صور/فيديو/صوت) إلى Supabase Storage،
/// وإرجاع رابط عام (Public URL) دائم بدل المسار المحلي المؤقت
/// (blob:) اللي يختفي بمجرد تغيير الجهاز أو المتصفح.
///
/// المخازن (Buckets) المتوقع وجودها بمشروع Supabase (راجع خطوات الإعداد):
/// - covers  : صور الأغلفة، الخلفيات العامة، المعرض، صور التساقط، العناصر المتحركة
/// - videos  : فيديوهات الكشف
/// - audio   : الموسيقى الخلفية
class StorageService {
  StorageService._();

  /// يرفع صورة/فيديو (XFile من image_picker) ويرجع الرابط العام
  static Future<String> uploadXFile(XFile file, {required String bucket}) async {
    final bytes = await file.readAsBytes();
    return _upload(bucket: bucket, bytes: bytes, originalName: file.name);
  }

  /// يرفع بايتات جاهزة (مثلاً من file_picker) ويرجع الرابط العام
  static Future<String> uploadBytes(Uint8List bytes, String originalName, {required String bucket}) {
    return _upload(bucket: bucket, bytes: bytes, originalName: originalName);
  }

  /// امتدادات مسموحة وحجم أقصى (بالبايت) لكل bucket، لمنع رفع أي نوع/حجم ملف
  /// بلا قيود لمخزن عام (كان بلا أي تحقق سابقاً).
  static const Map<String, List<String>> _allowedExtensions = {
    'covers': ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    'videos': ['mp4', 'mov', 'webm'],
    'audio': ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
  };

  static const Map<String, int> _maxBytes = {
    'covers': 8 * 1024 * 1024, // 8MB
    'videos': 100 * 1024 * 1024, // 100MB
    'audio': 20 * 1024 * 1024, // 20MB
  };

  static Future<String> _upload({
    required String bucket,
    required Uint8List bytes,
    required String originalName,
  }) async {
    final ext = (originalName.contains('.') ? originalName.split('.').last : 'bin').toLowerCase();

    final allowed = _allowedExtensions[bucket];
    if (allowed != null && !allowed.contains(ext)) {
      throw Exception('نوع الملف غير مدعوم لهذا المخزن ($bucket). الأنواع المسموحة: ${allowed.join(', ')}');
    }

    final maxBytes = _maxBytes[bucket];
    if (maxBytes != null && bytes.length > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      throw Exception('حجم الملف أكبر من الحد المسموح ($maxMb ميجابايت) لهذا المخزن.');
    }

    final path = '${_uuid.v4()}.$ext';
    await supabase.storage.from(bucket).uploadBinary(path, bytes);
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
