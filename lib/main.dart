import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:rocksucks/player.dart';

void main() async {
  // Initialize the shader before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Load the shader using the correct path and asset bundle
  final shaderProgram = await ui.FragmentProgram.fromAsset(
    'assets/shaders/rive_shader.frag',
  );

  runApp(
    GameWidget.controlled(
      gameFactory: () => RockGame(shaderProgram: shaderProgram),
    ),
  );
}

class RockGame extends FlameGame {
  final ui.FragmentProgram shaderProgram;
  late ui.FragmentShader fragmentShader;
  double time = 0;

  RockGame({required this.shaderProgram});

  @override
  Color backgroundColor() => const Color(0xFFE0E0E0); // Light gray background

  @override
  Future<void> onLoad() async {
    // Add FPS counter
    add(
      FpsTextComponent(
        position: Vector2(10, 10),
        scale: Vector2.all(1.0),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );

    // Initialize the fragment shader
    try {
      fragmentShader = shaderProgram.fragmentShader();
      print('Shader loaded successfully.');
    } catch (e) {
      print('Error loading shader: $e');
    }

    // Initial uniform values
    updateShaderUniforms();

    // Load the Rive file once
    final riveFile = await RiveFile.asset('assets/rocksucks.riv');

    // Create the main character with its own artboard
    final mainArtboard = await loadArtboard(riveFile, artboardName: 'Artboard');

    // Add the main character
    final playerWidth = 400.0;
    add(
      Player(mainArtboard, fragmentShader, this)
        ..size = Vector2(
          playerWidth,
          playerWidth,
        ) // Set the size of the character
        ..position = Vector2(
          (size.x - playerWidth) / 2, // Center horizontally
          size.y - playerWidth, // Align to the bottom
        ),
    );

    // Add enemies with separate artboards
    addEnemies(5, riveFile, fragmentShader, this);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      updateShaderUniforms();
    }
  }

  void updateShaderUniforms() {
    // Update resolution when the game size changes
    fragmentShader.setFloat(0, size.x); // uResolution.x
    fragmentShader.setFloat(1, size.y); // uResolution.y
    fragmentShader.setFloat(2, time); // uTime
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Update the time uniform in the shader
    time += dt;
  }

  @override
  void render(Canvas canvas) {
    drawLanes(canvas, size.x, size.y);

    super.render(canvas);
  }

  void addEnemies(
    int count,
    RiveFile riveFile,
    ui.FragmentShader shader,
    RockGame gameRef,
  ) async {
    final random = Random();
    for (int j = 0; j < count; j++) {
      // Create a new artboard for each enemy
      final enemyArtboard = await loadArtboard(
        riveFile,
        artboardName: 'Artboard',
      );

      final w = 100.0; // Width of the enemy
      final randomOffsetX =
          random.nextDouble() * 50 - 25; // Random offset between -25 and 25
      final randomOffsetY =
          random.nextDouble() * 50 - 25; // Random offset between -25 and 25

      final enemy =
          Enemy(enemyArtboard, shader, gameRef)
            ..size = Vector2(w, w) // Set the size of the enemy
            ..position = Vector2(
              (size.x - w) * (j + 1) / (count + 1) +
                  randomOffsetX, // Center horizontally with offset
              w + randomOffsetY, // Align to the bottom with offset
            );

      add(enemy);
    }
  }

  void drawLanes(ui.Canvas canvas, double x, double y) {
    // Define the pastel colors for each lane
    final List<Color> laneColors = [
      const Color(0xFFFFD6E0), // Pastel pink
      const Color(0xFFD6EAFF), // Pastel blue
      const Color(0xFFD6FFE1), // Pastel green
      const Color(0xFFFFF8D6), // Pastel yellow
    ];

    // Define the vanishing point (center of the screen, about 1/3 from the top)
    final vanishingPointX = x / 2;
    final vanishingPointY = y * 0.3;

    // Define the width of the road at the bottom of the screen
    final roadBottomWidth = x * 0.8;
    final roadLeftEdgeBottom = (x - roadBottomWidth) / 2;
    final roadRightEdgeBottom = roadLeftEdgeBottom + roadBottomWidth;

    // Draw the filled lanes with gradients
    final numLanes = 4;
    for (int i = 0; i < numLanes; i++) {
      // Calculate the lanes' boundaries
      final leftFraction = i / numLanes;
      final rightFraction = (i + 1) / numLanes;

      final leftBottomX = roadLeftEdgeBottom + (roadBottomWidth * leftFraction);
      final rightBottomX =
          roadLeftEdgeBottom + (roadBottomWidth * rightFraction);

      // Create a path for the curved lane
      final path = Path();

      // Start at the vanishing point
      path.moveTo(vanishingPointX, vanishingPointY);

      // Calculate curve control points
      final curveAmplitude =
          20.0 * (i % 2 == 0 ? 1 : -1); // Alternate curve direction
      final controlY = vanishingPointY + (y - vanishingPointY) * 0.5;

      // Left edge curve control point
      final leftControlX =
          vanishingPointX +
          (leftBottomX - vanishingPointX) * 0.5 +
          curveAmplitude * sin(i * 0.5);

      // Right edge curve control point
      final rightControlX =
          vanishingPointX +
          (rightBottomX - vanishingPointX) * 0.5 +
          curveAmplitude * sin(i * 0.5);

      // Draw the curved left edge
      path.quadraticBezierTo(leftControlX, controlY, leftBottomX, y);

      // Line to the right bottom corner
      path.lineTo(rightBottomX, y);

      // Draw the curved right edge back to vanishing point
      path.quadraticBezierTo(
        rightControlX,
        controlY,
        vanishingPointX,
        vanishingPointY,
      );

      // Close the path
      path.close();

      // Create a gradient for the lane
      final gradient = ui.Gradient.linear(
        Offset(vanishingPointX, vanishingPointY),
        Offset((leftBottomX + rightBottomX) / 2, y),
        [
          laneColors[i].withOpacity(0.7), // Start with semi-transparent color
          laneColors[i], // End with full color
        ],
      );

      // Draw the filled lane with gradient
      canvas.drawPath(
        path,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );

      // Add shadow gradient along the edges for depth
      final shadowPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..shader = ui.Gradient.linear(
              Offset(vanishingPointX, vanishingPointY),
              Offset((leftBottomX + rightBottomX) / 2, y),
              [Colors.black.withOpacity(0.4), Colors.black.withOpacity(0.1)],
            );

      canvas.drawPath(path, shadowPaint);
    }

    // Draw horizontal connector lines for more road-like appearance
    final segments = 10;
    final linePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke;

    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final segmentY = vanishingPointY + (y - vanishingPointY) * t;

      // Add a slight curve to the horizontal lines for 3D effect
      final curveOffset = 5.0 * sin(t * pi * 0.5);

      // Calculate perspective width at this y-coordinate with curve
      final segmentLeftX =
          vanishingPointX +
          (roadLeftEdgeBottom - vanishingPointX) * t -
          curveOffset * t;
      final segmentRightX =
          vanishingPointX +
          (roadRightEdgeBottom - vanishingPointX) * t +
          curveOffset * t;

      // Draw curved horizontal line
      final horizontalPath = Path();
      horizontalPath.moveTo(segmentLeftX, segmentY);

      // Add a slight curve to the horizontal line
      final midX = (segmentLeftX + segmentRightX) / 2;
      final curveY = segmentY + curveOffset;

      horizontalPath.quadraticBezierTo(midX, curveY, segmentRightX, segmentY);

      linePaint.strokeWidth =
          1.0 + t * 1.5; // Gradually increase stroke width for perspective
      canvas.drawPath(horizontalPath, linePaint);
    }
  }
}
