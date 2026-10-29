import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_routes.dart';
import '../providers/group_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

/// Splash screen (/): the peso coin pops in while two gold orbit rings spin
/// around it. Once the groups have loaded, the coin splits in half and Home
/// fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Shortest time the splash stays up, so the animation can be seen.
  static const minDuration = Duration(seconds: 5);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Goes from 0 to 1 every 2 seconds; repeat() keeps the rings spinning.
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  // Plays once: the coin grows from nothing with a small bounce.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  // Plays when leaving: the coin's halves slide apart, the rings fade out.
  late final AnimationController _split = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  // Started as soon as the splash opens, so the 5 seconds count from launch.
  final Future<void> _minDelay = Future.delayed(SplashScreen.minDuration);
  bool _leaving = false;

  @override
  void dispose() {
    _orbit.dispose();
    _intro.dispose();
    _split.dispose();
    super.dispose();
  }

  /// Once the groups have loaded and the minimum time has passed, splits
  /// the coin and fades in Home.
  Future<void> _goHome() async {
    _leaving = true;
    await _minDelay;
    if (!mounted) return;
    await _split.forward();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: AppRoutes.home),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;
    if (!isLoading && !_leaving) _goHome();

    final coin = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
    final split = CurvedAnimation(parent: _split, curve: Curves.easeInOutCubic);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: SizedBox.square(
          dimension: 280,
          child: AnimatedBuilder(
            animation: Listenable.merge([_orbit, _intro, _split]),
            builder: (_, _) => CustomPaint(
              painter: _LogoPainter(
                spin: _orbit.value,
                coin: coin.value,
                split: split.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Split It logo: a gold coin with a white peso sign, inside two
/// swoosh rings.
///
/// [spin] (0 to 1) turns the rings once around. [coin] (0 to about 1.1
/// with the bounce) is the coin's size. [split] (0 to 1) pulls the coin's
/// halves apart and fades everything out.
class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.spin, required this.coin, required this.split});

  final double spin;
  final double coin;
  final double split;

  static const _gold = AppColors.amber;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final width = size.width;
    final fade = Paint()
      ..color = Colors.black.withValues(alpha: (1 - split).clamp(0, 1));

    // The rings grow a little as they fade out.
    canvas.saveLayer(null, fade);
    canvas.scale(1 + 0.4 * split);
    _paintRings(canvas, width);
    canvas.restore();

    if (coin > 0) {
      final radius = width * 0.33 * coin;
      canvas.saveLayer(null, fade);
      if (split == 0) {
        _paintCoin(canvas, radius);
      } else {
        // Left half (-1) and right half (1), each sliding and tipping
        // outwards, cut along the middle.
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(side * split * width * 0.8, 0);
          canvas.rotate(side * split * 0.4);
          canvas.clipRect(
            Rect.fromLTRB(
              side < 0 ? -radius * 2 : 0,
              -radius * 2,
              side < 0 ? 0 : radius * 2,
              radius * 2,
            ),
          );
          _paintCoin(canvas, radius);
          canvas.restore();
        }
      }
      canvas.restore();
    }

    canvas.restore();
  }

  /// Two swooshes, half a turn apart. Each has a rounded head and an outer
  /// edge that spirals in until it meets the inner ring.
  void _paintRings(Canvas canvas, double width) {
    final outer = width * 0.49;
    final inner = width * 0.40;
    final paint = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.016
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.rotate(spin * 2 * math.pi);
    for (final head in [-0.75 * math.pi, 0.25 * math.pi]) {
      canvas.drawPath(_swoosh(head, outer, inner), paint);
    }
    canvas.restore();
  }

  Path _swoosh(double head, double outer, double inner) {
    const sweep = 1.25 * math.pi;
    const steps = 60;
    Offset at(double angle, double radius) =>
        Offset(math.cos(angle) * radius, math.sin(angle) * radius);

    final path = Path()..moveTo(at(head, inner).dx, at(head, inner).dy);
    // Rounded head, bulging back against the spin direction.
    final start = at(head, outer);
    path.arcToPoint(
      start,
      radius: Radius.circular((outer - inner) / 2),
      clockwise: true,
    );
    // Outer edge, shrinking onto the inner ring.
    for (var i = 1; i <= steps; i++) {
      final s = i / steps;
      final point = at(head + s * sweep, inner + (outer - inner) * (1 - s));
      path.lineTo(point.dx, point.dy);
    }
    // Inner edge, back to the head.
    for (var i = steps; i >= 0; i--) {
      final point = at(head + i / steps * sweep, inner);
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  /// The coin and its peso sign, drawn around (0, 0) with [radius].
  void _paintCoin(Canvas canvas, double radius) {
    canvas.drawCircle(Offset.zero, radius, Paint()..color = _gold);

    final r = radius;
    final peso = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.1
      ..strokeCap = StrokeCap.round;

    // The "P": a stem with a rounded bowl at the top.
    final stemX = -r * 0.25;
    final top = -r * 0.47;
    final bowlBottom = r * 0.17;
    final bowlRadius = (bowlBottom - top) / 2;
    final bowlX = r * 0.08;
    final p = Path()
      ..moveTo(stemX, r * 0.55)
      ..lineTo(stemX, top)
      ..lineTo(bowlX, top)
      ..arcToPoint(
        Offset(bowlX, bowlBottom),
        radius: Radius.circular(bowlRadius),
      )
      ..lineTo(stemX, bowlBottom);
    canvas.drawPath(p, peso);

    // The two bars across the bowl.
    for (final y in [-r * 0.25, -r * 0.05]) {
      canvas.drawLine(Offset(-r * 0.4, y), Offset(r * 0.52, y), peso);
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.spin != spin || old.coin != coin || old.split != split;
}
