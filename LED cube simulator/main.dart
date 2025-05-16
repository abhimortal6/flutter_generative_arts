import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(
  const MaterialApp(
    home: Scaffold(body: LedCubeApp(), backgroundColor: Colors.black),
  ),
);

class LedCubeApp extends StatefulWidget {
  const LedCubeApp({Key? key}) : super(key: key);

  @override
  _LedCubeAppState createState() => _LedCubeAppState();
}

class _LedCubeAppState extends State<LedCubeApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double rotation = 0;

  int cubeSize = 10;
  double spacing = 30;
  double perspective = 400;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 20))
          ..addListener(() {
            setState(() {
              rotation = _controller.value * 3 * pi;
            });
          })
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: LedCubePainter(rotation, cubeSize, spacing, perspective),
            child: Container(),
          ),
        ),
        Container(
          color: Colors.grey[900],
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSlider(
                label: 'Cube Size',
                value: cubeSize.toDouble(),
                min: 2,
                max: 20,
                onChanged: (val) => setState(() => cubeSize = val.toInt()),
              ),
              _buildSlider(
                label: 'Spacing',
                value: spacing,
                min: 10,
                max: 60,
                onChanged: (val) => setState(() => spacing = val),
              ),
              _buildSlider(
                label: 'Perspective',
                value: perspective,
                min: 100,
                max: 800,
                onChanged: (val) => setState(() => perspective = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${value.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class LedCubePainter extends CustomPainter {
  final double rotation;
  final int cubeSize;
  final double spacing;
  final double perspective;

  LedCubePainter(this.rotation, this.cubeSize, this.spacing, this.perspective);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final Paint dotPaint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);

    for (int x = 0; x < cubeSize; x++) {
      for (int y = 0; y < cubeSize; y++) {
        for (int z = 0; z < cubeSize; z++) {
          final dx = (x - cubeSize / 2) * spacing;
          final dy = (y - cubeSize / 2) * spacing;
          final dz = (z - cubeSize / 2) * spacing;

          final rotatedX = dx * cos(rotation) - dz * sin(rotation);
          final rotatedZ = dx * sin(rotation) + dz * cos(rotation);

          // Perspective
          final scaleFactor = perspective / (perspective + rotatedZ);
          final px = rotatedX * scaleFactor;
          final py = dy * scaleFactor;

          final hue = (rotation + x * 0.1 + y * 0.1 + z * 0.1) % (2 * pi);
          final color = HSVColor.fromAHSV(
            1.0,
            (hue * 180 / pi) % 360,
            1.0,
            1.0,
          ).toColor();

          glowPaint.color = color.withOpacity(0.25);
          dotPaint.color = color;

          canvas.drawCircle(center + Offset(px, py), 6.0 * scaleFactor, glowPaint);
          canvas.drawCircle(center + Offset(px, py), 2.5 * scaleFactor, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
