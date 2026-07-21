import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/overlay_element.dart';
import '../providers/design_provider.dart';
import '../theme/app_fonts.dart';
import 'detail_sections.dart';
import 'falling_particles.dart';
import 'overlay_elements_layer.dart';

/// شاشة المعاينة الحية (توضع على يسار شاشة التصميم).
/// تعرض شكل الدعوة كاملاً كصفحة واحدة قابلة للسكرول الطبيعي:
/// غلاف (صورة/فيديو) في الأعلى، وتحته مباشرة كل أقسام التفاصيل
/// المفعّلة بالترتيب اللي حدده المستخدم - بدون أي زر أو سهم "ينقل" للأسفل،
/// المستخدم يسحب بإصبعه/الماوس زي أي صفحة عادية.
class LivePreview extends StatefulWidget {
  const LivePreview({super.key});

  @override
  State<LivePreview> createState() => _LivePreviewState();
}

class _LivePreviewState extends State<LivePreview> with TickerProviderStateMixin {
  bool _revealed = false;
  VideoPlayerController? _videoController;
  String? _loadedVideoPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _loadedAudioPath;

  // تتبع الوقت المنقضي منذ بداية العرض - يُستخدم لتوقيت العناصر المتحركة فوق الفيديو
  Ticker? _overlayTicker;
  final Stopwatch _overlayStopwatch = Stopwatch();
  double _elapsedSeconds = 0;

  void _ensureVideoController(String? path) {
    if (path == null || path == _loadedVideoPath) return;
    _videoController?.dispose();
    _loadedVideoPath = path;
    // على الويب، image_picker يرجّع مسار "blob:" يُعامل كرابط شبكة
    _videoController = (kIsWeb || path.startsWith('http'))
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));
    _videoController!.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _playBackgroundAudio(String? path, bool enabled) async {
    if (!enabled || path == null || path.isEmpty || path == _loadedAudioPath) return;
    _loadedAudioPath = path;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      if (kIsWeb || path.startsWith('http')) {
        await _audioPlayer.play(UrlSource(path));
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
      }
    } catch (_) {
      // تشغيل الصوت ليس حرجاً - لو فشل نتجاهله بصمت في وضع المعاينة
    }
  }

  void _reveal(DesignProvider design) {
    setState(() => _revealed = true);
    _videoController?.play();
    // تشغيل الموسيقى الخلفية مرتبط بنفس لفتة الضغط (متطلب المتصفحات لتشغيل صوت تلقائي)
    _playBackgroundAudio(design.draft.backgroundAudioPath, design.draft.backgroundAudioEnabled);
    _startOverlayTicker(design.draft.overlayElements);
  }

  void _startOverlayTicker(List<OverlayElement> overlayElements) {
    if (overlayElements.isEmpty) return;
    // نوقف المؤقت تلقائياً بعد ما تخلص كل العناصر حركتها - لتفادي أي استهلاك إضافي بدون داعي
    final maxTime = overlayElements
            .map((e) => e.startDelaySeconds + e.durationSeconds)
            .fold<double>(0, (a, b) => a > b ? a : b) +
        0.3;
    _overlayStopwatch
      ..reset()
      ..start();
    _overlayTicker?.dispose();
    _overlayTicker = createTicker((_) {
      final seconds = _overlayStopwatch.elapsedMilliseconds / 1000.0;
      if (mounted) setState(() => _elapsedSeconds = seconds);
      if (seconds > maxTime) _overlayTicker?.stop();
    })
      ..start();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _overlayTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DesignProvider>(
      builder: (context, design, _) {
        final draft = design.draft;
        _ensureVideoController(draft.revealVideoPath);
        final accent = Color(draft.primaryColorValue);
        final sections = draft.enabledSectionsInOrder;

        return Container(
          decoration: BoxDecoration(
            color: Color(draft.backgroundColorValue),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final frameHeight = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // صورة الخلفية العامة (لو محددة) - أدنى طبقة، تظهر خلف كل شي
                    if (draft.backgroundImagePath != null && draft.backgroundImagePath!.isNotEmpty)
                      Positioned.fill(child: _CoverImage(path: draft.backgroundImagePath)),

                    // المحتوى القابل للسكرول: الغلاف بارتفاع كامل الإطار، ثم الأقسام أسفله
                    SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: frameHeight,
                            child: _CoverHeader(
                              draft: draft,
                              revealed: _revealed,
                              controller: _videoController,
                              onTap: () => _reveal(design),
                              hasMoreBelow: sections.isNotEmpty,
                              elapsedSeconds: _elapsedSeconds,
                              overlayElements: draft.overlayElements,
                            ),
                          ),
                          if (sections.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Text(
                                    draft.titleText.isEmpty ? 'اسم المناسبة هنا' : draft.titleText,
                                    textAlign: TextAlign.center,
                                    style: AppFonts.style(draft.namesFontFamily, fontSize: 22, fontWeight: FontWeight.bold, color: accent),
                                  ),
                                  const Divider(height: 30, indent: 40, endIndent: 40),
                                  for (final section in sections) buildSectionWidget(section.type, draft, accent),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // طبقة الأنيميشن المتساقط - ثابتة فوق المحتوى، ما تتحرك مع السكرول
                    if (draft.fallingAnimationEnabled && draft.fallingParticles.isNotEmpty)
                      Positioned.fill(
                        child: FallingParticles(
                          emojis: draft.fallingParticles,
                          imagePath: draft.fallingParticleImagePath,
                          durationSeconds: draft.fallingAnimationDurationSeconds,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// رأس الغلاف: صورة يُضغط عليها فتشتغل الفيديو فوق الاسم، وتلميح سكرول
/// خفيف (زخرفي فقط - مو زر) لو فيه أقسام تحت.
class _CoverHeader extends StatelessWidget {
  final dynamic draft;
  final bool revealed;
  final VideoPlayerController? controller;
  final VoidCallback onTap;
  final bool hasMoreBelow;
  final double elapsedSeconds;
  final List<OverlayElement> overlayElements;

  const _CoverHeader({
    required this.draft,
    required this.revealed,
    required this.controller,
    required this.onTap,
    required this.hasMoreBelow,
    required this.elapsedSeconds,
    required this.overlayElements,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          // بدون هذا، AnimatedSwitcher يستخدم Stack غير ممدود داخلياً، فيحجّم
          // الفيديو/الصورة حسب أبعادها الطبيعية بدل ما تملأ الإطار كامل.
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [...previousChildren, if (currentChild != null) currentChild],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0)
                  .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          ),
          child: (revealed && controller != null && controller!.value.isInitialized)
              ? SizedBox.expand(
                  key: const ValueKey('video'),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller!.value.size.width,
                      height: controller!.value.size.height,
                      child: VideoPlayer(controller!),
                    ),
                  ),
                )
              : SizedBox.expand(
                  key: const ValueKey('cover'),
                  child: GestureDetector(
                    onTap: onTap,
                    child: _CoverImage(path: draft.coverImagePath),
                  ),
                ),
        ),
        if (revealed)
          Positioned.fill(
            child: OverlayElementsLayer(elements: overlayElements, elapsedSeconds: elapsedSeconds),
          ),
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Text(
                draft.titleText.isEmpty ? 'اسم المناسبة هنا' : draft.titleText,
                textAlign: TextAlign.center,
                style: AppFonts.style(draft.namesFontFamily, fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)
                    .copyWith(shadows: const [Shadow(blurRadius: 12, color: Colors.black45)]),
              ),
              if (!revealed)
                const Padding(padding: EdgeInsets.only(top: 14), child: _TapHint()),
              if (revealed && hasMoreBelow)
                const Padding(padding: EdgeInsets.only(top: 14), child: _ScrollHint()),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? path;
  const _CoverImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return Container(
        color: const Color(0xFFEADFC8),
        child: const Center(child: Icon(Icons.image_outlined, size: 56, color: Colors.white70)),
      );
    }
    if (path!.startsWith('assets/')) {
      return Image.asset(path!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _missingImagePlaceholder());
    }
    if (kIsWeb || path!.startsWith('http')) {
      return Image.network(path!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _missingImagePlaceholder());
    }
    return Image.file(File(path!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _missingImagePlaceholder());
  }

  Widget _missingImagePlaceholder() {
    return Container(
      color: const Color(0xFFEADFC8),
      child: const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.white70)),
    );
  }
}

class _TapHint extends StatefulWidget {
  const _TapHint();

  @override
  State<_TapHint> createState() => _TapHintState();
}

class _TapHintState extends State<_TapHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + (_controller.value * 0.12),
          child: Opacity(opacity: 0.75 + (_controller.value * 0.25), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.28), shape: BoxShape.circle),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

/// تلميح زخرفي بسيط (سهم ينبض) يشير إن فيه محتوى تحت - غير قابل للضغط،
/// المستخدم يسحب بنفسه، هذا مجرد إشارة بصرية.
class _ScrollHint extends StatefulWidget {
  const _ScrollHint();

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _controller.value * 6),
          child: child,
        ),
        child: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 26),
      ),
    );
  }
}
