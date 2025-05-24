import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const PongWarsApp());

class PongWarsApp extends StatelessWidget {
  const PongWarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(child: PongGame()),
      ),
    );
  }
}

class PongGame extends StatefulWidget {
  const PongGame({super.key});

  @override
  State<PongGame> createState() => _PongGameState();
}

class _PongGameState extends State<PongGame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static double canvasSize = 500;
  static const double squareSize = 25;
  static const int frameRate = 60;
  static const double minSpeed = 6.0;
  static const double maxSpeed = 10.0;

  late List<List<Color>> squares;
  late Ball ball1;
  late Ball ball2;
  int numX = (canvasSize / squareSize).floor();
  int numY = (canvasSize / squareSize).floor();

  int dayScore = 0;
  int nightScore = 0;

  final Color dayColor = const Color(0xFFD9E8E3);
  final Color dayBallColor = const Color(0xFF172B36);
  final Color nightColor = const Color(0xFF172B36);
  final Color nightBallColor = const Color(0xFFD9E8E3);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000 ~/ frameRate),
    )..addListener(updateGame);

    initGame();
    _controller.repeat();
  }

  void initGame() {
    squares = List.generate(numX, (i) {
      return List.generate(numY, (j) {
        return i < numX / 2 ? dayColor : nightColor;
      });
    });

    ball1 = Ball(
      x: canvasSize / 4,
      y: canvasSize / 2,
      dx: 3,
      dy: -3,
      color: dayBallColor,
      reverseColor: dayColor,
    );

    ball2 = Ball(
      x: 3 * canvasSize / 4,
      y: canvasSize / 2,
      dx: -3,
      dy: 3,
      color: nightBallColor,
      reverseColor: nightColor,
    );
  }

  void updateGame() {
    updateBall(ball1);
    updateBall(ball2);

    dayScore = 0;
    nightScore = 0;
    for (var row in squares) {
      for (var color in row) {
        if (color == dayColor) dayScore++;
        if (color == nightColor) nightScore++;
      }
    }

    setState(() {});
  }

  void updateBall(Ball ball) {
    ball.x += ball.dx;
    ball.y += ball.dy;

    if (ball.x <= squareSize / 2 || ball.x >= canvasSize - squareSize / 2) {
      ball.dx = -ball.dx;
    }
    if (ball.y <= squareSize / 2 || ball.y >= canvasSize - squareSize / 2) {
      ball.dy = -ball.dy;
    }

    for (double angle = 0; angle < 2 * pi; angle += pi / 4) {
      final checkX = ball.x + cos(angle) * squareSize / 2;
      final checkY = ball.y + sin(angle) * squareSize / 2;

      final i = (checkX / squareSize).floor();
      final j = (checkY / squareSize).floor();

      if (i >= 0 && i < numX && j >= 0 && j < numY) {
        if (squares[i][j] != ball.reverseColor) {
          squares[i][j] = ball.reverseColor;
          if ((cos(angle)).abs() > (sin(angle)).abs()) {
            ball.dx = -ball.dx;
          } else {
            ball.dy = -ball.dy;
          }
        }
      }
    }

    ball.dx += Random().nextDouble() * 0.1 - 0.05;
    ball.dy += Random().nextDouble() * 0.1 - 0.05;
    ball.dx = ball.dx.clamp(-maxSpeed, maxSpeed);
    ball.dy = ball.dy.clamp(-maxSpeed, maxSpeed);
    if (ball.dx.abs() < minSpeed) ball.dx = ball.dx.sign * minSpeed;
    if (ball.dy.abs() < minSpeed) ball.dy = ball.dy.sign * minSpeed;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      //       color: const Color(0xFF172B36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: canvasSize,
            height: canvasSize,
            child: CustomPaint(painter: PongPainter(squares, ball1, ball2)),
          ),
          const SizedBox(height: 16),
          Text(
            'day $dayScore | night $nightScore',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class PongPainter extends CustomPainter {
  final List<List<Color>> squares;
  final Ball ball1;
  final Ball ball2;

  PongPainter(this.squares, this.ball1, this.ball2);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final squareSize = size.width / squares.length;

    for (int i = 0; i < squares.length; i++) {
      for (int j = 0; j < squares[i].length; j++) {
        paint.color = squares[i][j];
        canvas.drawRect(
          Rect.fromLTWH(i * squareSize, j * squareSize, squareSize, squareSize),
          paint,
        );
      }
    }

    paint.color = ball1.color;
    canvas.drawCircle(Offset(ball1.x, ball1.y), squareSize / 2, paint);

    paint.color = ball2.color;
    canvas.drawCircle(Offset(ball2.x, ball2.y), squareSize / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Ball {
  double x, y, dx, dy;
  final Color color;
  final Color reverseColor;

  Ball({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.color,
    required this.reverseColor,
  });
}
