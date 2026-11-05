import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionSplash extends StatelessWidget {
  const SessionSplash({super.key});

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF369BEF),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF174B96),
      body: Semantics(
        label: 'BengkelKu. Aplikasi Manajemen Bengkel. Memuat akun.',
        liveRegion: true,
        child: const ExcludeSemantics(child: SplashArtwork()),
      ),
    ),
  );
}

/// Shared composition for the session screen and native launch exports.
class SplashArtwork extends StatelessWidget {
  const SplashArtwork({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final height = constraints.maxHeight;
      final width = math.min(constraints.maxWidth, height * .55);
      final left = (constraints.maxWidth - width) / 2;
      final emblemSize = width * .34;
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF16478C),
                  Color(0xFF1B5AB6),
                  Color(0xFF329DF5),
                ],
                stops: [0, .53, 1],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _SplashBackdrop())),
          Positioned(
            left: left + (width - emblemSize) / 2,
            top: height * .279 - emblemSize / 2,
            width: emblemSize,
            height: emblemSize,
            child: ColorFiltered(
              // Preserve the new mark's silhouette; its white wrench becomes
              // transparent so the inverse version reads on the blue field.
              colorFilter: const ColorFilter.matrix([
                0,
                0,
                0,
                0,
                255,
                0,
                0,
                0,
                0,
                255,
                0,
                0,
                0,
                0,
                255,
                -.75,
                -.75,
                0,
                1.5,
                0,
              ]),
              child: Image.asset(
                'assets/branding/emblem-mockup.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                cacheWidth:
                    (emblemSize * MediaQuery.devicePixelRatioOf(context))
                        .ceil(),
              ),
            ),
          ),
          Positioned(
            top: height * .345,
            left: left + width * .04,
            width: width * .92,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BengkelKu',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: width * .12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -.6,
                  ),
                ),
                SizedBox(height: width * .014),
                Text(
                  'Aplikasi Manajemen Bengkel',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                    fontSize: width * .049,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: left + width * .025,
            top: height * .57,
            width: width * .95,
            height: width * .95 / 1.75,
            child: Image.asset(
              'assets/illustrations/splash-vehicles.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              cacheWidth: (width * .95 * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
            ),
          ),
        ],
      );
    },
  );
}

class _SplashBackdrop extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = math.min(w, h * .55) * .33;
    final center = Offset(w / 2 + math.min(w, h * .55) * .52, h * .235);
    final gear = Path()..fillType = PathFillType.evenOdd;
    for (var i = 0; i < 64; i++) {
      final angle = i * math.pi / 32 - math.pi / 2;
      final r = radius * (i % 8 >= 2 && i % 8 <= 5 ? 1 : .79);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        gear.moveTo(point.dx, point.dy);
      } else {
        gear.lineTo(point.dx, point.dy);
      }
    }
    gear.close();
    gear.addOval(Rect.fromCircle(center: center, radius: radius * .45));
    canvas.drawPath(gear, Paint()..color = const Color(0x10FFFFFF));

    final back = Path()
      ..moveTo(0, h * .754)
      ..cubicTo(w * .36, h * .754, w * .58, h * .80, w, h * .79)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = const Color(0xFFE6F3FF));
    final middle = Path()
      ..moveTo(0, h * .82)
      ..cubicTo(w * .33, h * .805, w * .53, h * .925, w, h * .872)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(middle, Paint()..color = const Color(0xFFCAE5FF));
    final front = Path()
      ..moveTo(0, h * .862)
      ..cubicTo(w * .29, h * .855, w * .47, h * .96, w, h * .899)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF329AF0), Color(0xFF71B8F7)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SplashBackdrop oldDelegate) => false;
}
