import 'package:flutter/material.dart';
import '../models/overlay_element.dart';
import '../theme/app_fonts.dart';
import 'smart_image.dart';

/// يعرض كل العناصر المتحركة (نص/صورة) فوق الفيديو، بالاعتماد على
/// [elapsedSeconds] المنقضي منذ بداية تشغيل الفيديو. كل عنصر يبدأ حركته
/// عند [OverlayElement.startDelaySeconds] وتستغرق [OverlayElement.durationSeconds].
class OverlayElementsLayer extends StatelessWidget {
  final List<OverlayElement> elements;
  final double elapsedSeconds;

  const OverlayElementsLayer({super.key, required this.elements, required this.elapsedSeconds});

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: Stack(children: elements.map(_buildElement).toList()),
    );
  }

  Widget _buildElement(OverlayElement el) {
    final localElapsed = elapsedSeconds - el.startDelaySeconds;
    if (localElapsed < 0) return const SizedBox.shrink(); // لسا ما جا وقت ظهوره

    final rawProgress = el.durationSeconds <= 0 ? 1.0 : (localElapsed / el.durationSeconds).clamp(0.0, 1.0);
    final curved = Curves.easeOut.transform(rawProgress);

    final opacity = (curved * el.opacity).clamp(0.0, 1.0);
    double scale = 1.0;
    Offset translate = Offset.zero;

    switch (el.animationType) {
      case OverlayAnimationType.fade:
        break;
      case OverlayAnimationType.slideUp:
        translate = Offset(0, (1 - curved) * 40);
        break;
      case OverlayAnimationType.slideDown:
        translate = Offset(0, (1 - curved) * -40);
        break;
      case OverlayAnimationType.scale:
        scale = 0.7 + curved * 0.3;
        break;
      case OverlayAnimationType.zoom:
        scale = 0.3 + curved * 0.7;
        break;
    }

    final content = el.type == OverlayElementType.text
        ? Text(
            el.text,
            textAlign: TextAlign.center,
            style: AppFonts.style(el.fontFamily, fontSize: el.fontSize, fontWeight: FontWeight.w700, color: Color(el.colorValue)),
          )
        : _OverlayImage(path: el.imagePath);

    return Align(
      alignment: Alignment(el.positionX, el.positionY),
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: translate,
          child: Transform.scale(
            scale: scale,
            child: FractionallySizedBox(widthFactor: el.widthFraction, child: content),
          ),
        ),
      ),
    );
  }
}

class _OverlayImage extends StatelessWidget {
  final String? path;
  const _OverlayImage({required this.path});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) return const SizedBox.shrink();
    return SmartImage(path: path);
  }
}
