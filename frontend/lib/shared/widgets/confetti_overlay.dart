import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool show;
  final VoidCallback? onFinished;

  const ConfettiOverlay({super.key, required this.show, this.onFinished});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addListener(() {
            _updateParticles();
          });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
      }
    });

    if (widget.show) {
      _startCelebration();
    }
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _particles.clear();
    _controller.reset();
    _controller.forward();
  }

  void _initializeParticles(Size size) {
    if (_particles.isNotEmpty) return;

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.blueprint,
      AppColors.danger,
    ];

    for (int i = 0; i < 120; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble() * size.width,
          y: -_random.nextDouble() * size.height * 0.5,
          size: _random.nextDouble() * 10 + 6,
          color: colors[_random.nextInt(colors.length)],
          speedY: _random.nextDouble() * 150 + 100, // píxeles por seg
          speedX: (_random.nextDouble() - 0.5) * 60,
          angle: _random.nextDouble() * 2 * math.pi,
          spinSpeed: (_random.nextDouble() - 0.5) * 8 * math.pi,
        ),
      );
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;

    // El valor dt es la fracción del progreso animado
    final dt = 1.0 / 60.0; // aprox 60fps
    for (final p in _particles) {
      p.y += p.speedY * dt;
      p.x += p.speedX * dt;
      p.angle += p.spinSpeed * dt;
      // Añadir gravedad leve
      p.speedY += 80 * dt;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initializeParticles(size);

        // Opacidad difumina al final del tiempo de vida de la animación
        final double opacity = _controller.value > 0.85
            ? (1.0 - _controller.value) / 0.15
            : 1.0;

        return IgnorePointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: CustomPaint(
              size: size,
              painter: _ConfettiPainter(particles: _particles),
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double size;
  final Color color;
  double speedY;
  double speedX;
  double angle;
  final double spinSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speedY,
    required this.speedX,
    required this.angle,
    required this.spinSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Ignorar partículas fuera del borde inferior
      if (p.y > size.height + p.size) continue;

      paint.color = p.color;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.angle);

      // Dibujar rectángulos y círculos alternados
      if (p.x.toInt() % 2 == 0) {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.5,
          ),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
