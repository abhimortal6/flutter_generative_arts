import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(MaterialApp(home: Scaffold(body: Center(child: JellyFishAnimation()))));

class JellyFishAnimation extends StatefulWidget {
  @override
  _JellyFishAnimationState createState() => _JellyFishAnimationState();
}

class _JellyFishAnimationState extends State<JellyFishAnimation> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double t = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((Duration elapsed) {
      setState(() {
t = elapsed.inMilliseconds / 1000 * pi * 2;
      });
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(800, 800),
      painter: JellyFishPainter(t),
    );
  }
}

class JellyFishPainter extends CustomPainter {
  final double t;
  JellyFishPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =  Colors.white54
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black,
    );

    for (int i = 0; i < 10000; i++) {
      double x = (i % 200).toDouble();
      double y = (i / 55).floorToDouble();
      final p = computePoint(x, y, t);
      canvas.drawPoints(ui.PointMode.points, [p], paint);
    }
  }

  Offset computePoint(double x, double y, double t) {
    double k = 9 * cos(x / 8);
    double e = y / 8 - 12.5;
    double d = pow(sqrt(k * k + e * e), 2) / 99 + sin(t) / 6 + 0.5;
    double q = 99 - e * sin(atan2(k, e) * 7) / d + k * (3 + cos(d * d - t) * 2);
    double c = d / 2 + e / 69 - t / 16;

    double px = q * sin(c) + 400;
    double py = (q + 19 * d) * cos(c) + 400;
    return Offset(px, py);
  }

  @override
  bool shouldRepaint(covariant JellyFishPainter oldDelegate) => true;
}
