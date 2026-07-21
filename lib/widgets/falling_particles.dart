import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// تأثير بصري بسيط: مجموعة إيموجي (وردة، قلب، نجمة...) أو صورة PNG مخصصة
/// تتساقط باستمرار من أعلى الشاشة لأسفلها بحركة وسرعة عشوائية خفيفة،
/// فوق محتوى الدعوة. مصمم ليكون decorative فقط (IgnorePointer) بحيث ما
/// يعيق التفاعل تحته.
class FallingParticles extends StatefulWidget {
  final List<String> emojis; // مثال: ['🌹','✨'] - يُستخدم لو ما فيه صورة مخصصة
  final String? imagePath; // صورة PNG مخصصة - لو محددة تُستخدم بدل الإيموجي
  final int count;
  final int durationSeconds; // "المؤقت": مدة دورة التساقط الكاملة (كل ما قلّت، صارت أسرع)

  const FallingParticles({
    super.key,
    required this.emojis,
    this.imagePath,
    this.count = 14,
    this.durationSeconds = 8,
  });

  @override
  State<FallingParticles> createState() => _FallingParticlesState();
}

class _FallingParticlesState extends State<FallingParticles> with TickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.durationSeconds))..repeat();
    _particles = List.generate(widget.count, (_) => _spawn());
  }

  _Particle _spawn() {
    return _Particle(
      emoji: widget.emojis.isEmpty ? '' : widget.emojis[_random.nextInt(widget.emojis.length)],
      xFraction: _random.nextDouble(),
      startDelay: _random.nextDouble(),
      speedFactor: 0.6 + _random.nextDouble() * 0.8,
      size: 16 + _random.nextDouble() * 14,
      swayFactor: _random.nextDouble() * 20,
    );
  }

  @override
  void didUpdateWidget(covariant FallingParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationSeconds != widget.durationSeconds) {
      _controller.dispose();
      _controller = AnimationController(vsync: this, duration: Duration(seconds: widget.durationSeconds))..repeat();
    }
    if (oldWidget.emojis.join() != widget.emojis.join() ||
        oldWidget.count != widget.count ||
        oldWidget.imagePath != widget.imagePath) {
      _particles = List.generate(widget.count, (_) => _spawn());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _particleVisual(_Particle p) {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      final path = widget.imagePath!;
      final errorFallback = SizedBox(width: p.size, height: p.size);
      if (path.startsWith('assets/')) {
        return Image.asset(path, width: p.size, height: p.size, errorBuilder: (_, __, ___) => errorFallback);
      }
      if (kIsWeb || path.startsWith('http') || path.startsWith('data:')) {
        return Image.network(path, width: p.size, height: p.size, errorBuilder: (_, __, ___) => errorFallback);
      }
      return Image.file(File(path), width: p.size, height: p.size, errorBuilder: (_, __, ___) => errorFallback);
    }
    return Text(p.emoji, style: TextStyle(fontSize: p.size));
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null && widget.imagePath!.isNotEmpty;
    if (!hasImage && widget.emojis.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: _particles.map((p) {
                  // تقدّم كل جسيم دورة كاملة (0 -> 1) بسرعة مختلفة قليلاً،
                  // مع تأخير بداية عشوائي لتفادي كل الجسيمات تتساقط بنفس التوقيت
                  final progress = ((_controller.value * p.speedFactor) + p.startDelay) % 1.0;
                  final y = progress * (constraints.maxHeight + 40) - 20;
                  final sway = sin(progress * 2 * pi * 2) * p.swayFactor;
                  final x = p.xFraction * constraints.maxWidth + sway;
                  final opacity = (1 - (progress - 0.85).clamp(0, 0.15) / 0.15).clamp(0.0, 1.0);
                  return Positioned(
                    left: x.clamp(0, constraints.maxWidth - 20),
                    top: y,
                    child: Opacity(
                      opacity: opacity.toDouble(),
                      child: _particleVisual(p),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}

class _Particle {
  final String emoji;
  final double xFraction;
  final double startDelay;
  final double speedFactor;
  final double size;
  final double swayFactor;

  _Particle({
    required this.emoji,
    required this.xFraction,
    required this.startDelay,
    required this.speedFactor,
    required this.size,
    required this.swayFactor,
  });
}
