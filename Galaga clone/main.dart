import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(home: GalagaGame()));

class GalagaGame extends StatefulWidget {
  @override
  _GalagaGameState createState() => _GalagaGameState();
}

class _GalagaGameState extends State<GalagaGame> {
  double playerX = 0.0;
  List<Offset> bullets = [];
  List<Enemy> enemies = [];
  List<Offset> stars = [];
  bool gameWon = false;
  bool gameOver = false;
  Timer? gameLoop;
  Timer? enemyStepTimer;
  Timer? colorCycleTimer;
  int lives = 3;

  double dx = 0.01;
  double direction = 1;
  double stepDownAmount = 0.05;

  final List<Color> vibgyor = [
    Colors.purple,
    Colors.indigo,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
  ];
  int currentColorIndex = 0;

  @override
  void initState() {
    super.initState();
    generateStars();
    resetGame();
    startGameLoop();
  }

  void generateStars() {
    final random = Random();
    stars = List.generate(100, (_) {
      double x = random.nextDouble() * 2 - 1;
      double y = random.nextDouble() * 2 - 1;
      return Offset(x, y);
    });
  }

  void resetGame() {
    bullets.clear();
    enemies = [];

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 6; col++) {
        double x = -0.9 + col * 0.32;
        double y = -0.9 + row * 0.2;
        enemies.add(Enemy(Offset(x, y), vibgyor[(row * 6 + col) % vibgyor.length]));
      }
    }

    playerX = 0.0;
    lives = 3;
    gameWon = false;
    gameOver = false;
    currentColorIndex = 0;

    gameLoop?.cancel();
    enemyStepTimer?.cancel();
    colorCycleTimer?.cancel();
    startGameLoop();
  }

  void startGameLoop() {
    gameLoop = Timer.periodic(Duration(milliseconds: 30), (_) {
      setState(() {
        updateBullets();
        moveEnemiesHorizontally();
        checkCollisions();

        if (enemies.any((e) => e.position.dy >= 0.85)) {
          gameOver = true;
          gameLoop?.cancel();
          enemyStepTimer?.cancel();
          colorCycleTimer?.cancel();
        } else if (enemies.isEmpty && !gameWon) {
          gameWon = true;
          gameLoop?.cancel();
          enemyStepTimer?.cancel();
          colorCycleTimer?.cancel();
        }
      });
    });

    enemyStepTimer = Timer.periodic(Duration(seconds: 3), (_) {
      setState(() {
        moveEnemiesDown();
      });
    });

    colorCycleTimer = Timer.periodic(Duration(milliseconds: 400), (_) {
      setState(() {
        currentColorIndex = (currentColorIndex + 1) % vibgyor.length;
        enemies = enemies.map((e) => Enemy(e.position, vibgyor[currentColorIndex])).toList();
      });
    });
  }

  void shoot() {
    bullets.add(Offset(playerX, 0.88));
  }

  void updateBullets() {
    bullets = bullets.map((b) => Offset(b.dx, b.dy - 0.05)).where((b) => b.dy > -1).toList();
  }

  void moveEnemiesHorizontally() {
    if (enemies.isEmpty) return;
    double leftMost = enemies.map((e) => e.position.dx).reduce(min);
    double rightMost = enemies.map((e) => e.position.dx).reduce(max);

    if (rightMost + dx * direction + 0.1 > 1 || leftMost + dx * direction < -1) {
      direction *= -1;
    }

    enemies = enemies
        .map((e) => Enemy(Offset(e.position.dx + dx * direction, e.position.dy), e.color))
        .toList();
  }

  void moveEnemiesDown() {
    enemies = enemies
        .map((e) => Enemy(Offset(e.position.dx, e.position.dy + stepDownAmount), e.color))
        .toList();
  }

  void checkCollisions() {
    List<Offset> remainingBullets = [];

    for (var bullet in bullets) {
      bool hit = false;
      for (var enemy in enemies) {
        if (enemy.hitTest(bullet)) {
          enemies.remove(enemy);
          hit = true;
          break;
        }
      }
      if (!hit) remainingBullets.add(bullet);
    }

    bullets = remainingBullets;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ...stars.map((star) {
            double sx = (star.dx + 1) / 2 * screenSize.width;
            double sy = (star.dy + 1) / 2 * screenSize.height;
            return Positioned(
              left: sx,
              top: sy,
              child: Container(
                width: 2,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),

          ...bullets.map((b) {
            double bx = (b.dx + 1) / 2 * screenSize.width;
            double by = (b.dy + 1) / 2 * screenSize.height;
            return Positioned(
              left: bx - 2,
              top: by - 10,
              child: Container(width: 4, height: 10, color: Colors.white),
            );
          }).toList(),

          ...enemies.map((enemy) {
            double ex = (enemy.position.dx + 1) / 2 * screenSize.width;
            double ey = (enemy.position.dy + 1) / 2 * screenSize.height;
            return Positioned(
              left: ex,
              top: ey,
              child: CustomPaint(
                size: Size(50, 50),
                painter: EnemyPainter(enemy.color),
              ),
            );
          }).toList(),

          Positioned(
            bottom: 20,
            left: ((playerX + 1) / 2 * screenSize.width) - 20,
            child: CustomPaint(
              size: Size(40, 40),
              painter: SpaceshipPainter(),
            ),
          ),

          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                playerX += details.delta.dx / screenSize.width * 2;
                playerX = playerX.clamp(-1.0, 1.0);
              });
            },
            onTap: shoot,
          ),

          Positioned(
            top: 10,
            left: 10,
            child: Text('Lives: $lives', style: TextStyle(color: Colors.white)),
          ),

          if (gameWon || gameOver)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    gameWon ? 'You Win!' : 'Game Over',
                    style: TextStyle(color: Colors.white, fontSize: 32),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        resetGame();
                      });
                    },
                    child: Text('Start Again'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class Enemy {
  Offset position;
  final Color color;
  final Size size = Size(0.12, 0.08);

  Enemy(this.position, this.color);

  bool hitTest(Offset bullet) {
    return (bullet.dx > position.dx &&
        bullet.dx < position.dx + size.width &&
        bullet.dy > position.dy &&
        bullet.dy < position.dy + size.height);
  }
}

class SpaceshipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.cyanAccent;

    Path ship = Path();
    ship.moveTo(size.width / 2, 0); 
    ship.lineTo(0, size.height);
    ship.lineTo(size.width, size.height);
    ship.close();

    canvas.drawPath(ship, paint);

    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.1, size.height * 0.6, size.width * 0.2, 10), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.7, size.height * 0.6, size.width * 0.2, 10), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EnemyPainter extends CustomPainter {
  final Color color;
  EnemyPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = color;
    final eyePaint = Paint()..color = Colors.white;
    final wingPaint = Paint()..color = Colors.grey.shade300;
    final antennaPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: size.width * 0.4, height: size.height * 0.6),
      bodyPaint,
    );

    // wings
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - size.width * 0.25, centerY), width: size.width * 0.25, height: size.height * 0.5),
      wingPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + size.width * 0.25, centerY), width: size.width * 0.25, height: size.height * 0.5),
      wingPaint,
    );

    canvas.drawCircle(Offset(centerX - 4, centerY - 6), 2.5, eyePaint);
    canvas.drawCircle(Offset(centerX + 4, centerY - 6), 2.5, eyePaint);

    canvas.drawLine(Offset(centerX - 4, centerY - size.height * 0.35), Offset(centerX - 8, centerY - size.height * 0.45), antennaPaint);
    canvas.drawLine(Offset(centerX + 4, centerY - size.height * 0.35), Offset(centerX + 8, centerY - size.height * 0.45), antennaPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

