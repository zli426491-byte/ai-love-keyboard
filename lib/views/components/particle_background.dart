import 'dart:math';

import 'package:flutter/material.dart';

/// A reusable animated background with floating pink/purple particles.
/// Use inside a Stack behind main content.
class ParticleBackground extends StatefulWidget {
  final int particleCount;

  const ParticleBackground({super.key, this.particleCount = 18});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.particleCount, (_) => _generateParticle());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _controller.addListener(_tick);
  }

  _Particle _generateParticle({bool fromBottom = false}) {
    final isHeart = _random.nextDouble() < 0.3;
    return _Particle(
      x: _random.nextDouble(),
      y: fromBottom ? 1.0 + _random.nextDouble() * 0.1 : _random.nextDouble(),
      size: 2.0 + _random.nextDouble() * 4.0,
      speed: 0.0002 + _random.nextDouble() * 0.0004,
      opacity: 0.15 + _random.nextDouble() * 0.25,
      color: _random.nextBool()
          ? const Color(0xFFAB47BC) // purple
          : const Color(0xFFFF80AB), // pink
      isHeart: isHeart,
      drift: (_random.nextDouble() - 0.5) * 0.0002,
    );
  }

  void _tick() {
    setState(() {
      for (int i = 0; i < _particles.length; i++) {
        final p = _particles[i];
        p.y -= p.speed;
        p.x += p.drift;
        // wrap around
        if (p.y < -0.05) {
          _particles[i] = _generateParticle(fromBottom: true);
        }
        if (p.x < -0.05 || p.x > 1.05) {
          _particles[i] = _generateParticle(fromBottom: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;
  bool isHeart;
  double drift;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
    required this.isHeart,
    required this.drift,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      final offset = Offset(p.x * size.width, p.y * size.height);

      if (p.isHeart) {
        _drawHeart(canvas, offset, p.size, paint);
      } else {
        canvas.drawCircle(offset, p.size, paint);
      }
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final s = size * 0.8;
    path.moveTo(center.dx, center.dy + s * 0.4);
    path.cubicTo(
      center.dx - s, center.dy - s * 0.2,
      center.dx - s * 0.5, center.dy - s,
      center.dx, center.dy - s * 0.4,
    );
    path.cubicTo(
      center.dx + s * 0.5, center.dy - s,
      center.dx + s, center.dy - s * 0.2,
      center.dx, center.dy + s * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
