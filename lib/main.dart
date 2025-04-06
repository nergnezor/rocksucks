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

    // Check for collisions between player and enemies
    final player = children.whereType<Player>().firstOrNull;
    if (player != null && !(player is Enemy)) {
      final enemies = children.whereType<Enemy>().toList();
      for (final enemy in enemies) {
        // Check if player collides with enemy
        if (player.checkCollision(enemy)) {
          // Handle the collision based on player's current state
          player.handleEnemyCollision(enemy);
        }
      }
    }
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
    // Define the pastel colors for each lane with enhanced saturation
    final List<Color> laneColors = [
      const ui.Color.fromARGB(255, 86, 78, 80), // Pastel pink
      const Color(0xFFD6EAFF), // Pastel blue
      const Color(0xFFD6FFE1), // Pastel green
      const ui.Color.fromARGB(255, 219, 217, 208), // Pastel yellow
    ];

    // Define the vanishing point (center of the screen, about 1/3 from the top)
    final vanishingPointX = x / 2;
    final vanishingPointY = y * 0.3;

    // Define the width of the road at the bottom of the screen
    final roadBottomWidth = x * 0.8;
    final roadLeftEdgeBottom = (x - roadBottomWidth) / 2;
    final roadRightEdgeBottom = roadLeftEdgeBottom + roadBottomWidth;
    final roadTopWidth =
        roadBottomWidth * 0.5; // Width at the top of the screen
    final roadLeftEdgeTop = (x - roadTopWidth) / 2;
    final roadRightEdgeTop = roadLeftEdgeTop + roadTopWidth;
    final roadHeight = y * 0.7; // Height of the road

    final roadTopY = y - roadHeight; // Y position of the top edge of the road

    final roadBottomY =
        y -
        roadHeight +
        roadHeight * 0.8; // Y position of the bottom edge of the road
    final roadTopLeft = Offset(roadLeftEdgeTop, roadTopY);
    final roadTopRight = Offset(roadRightEdgeTop, roadTopY);
    final roadBottomLeft = Offset(roadLeftEdgeBottom, roadBottomY);
    final roadBottomRight = Offset(roadRightEdgeBottom, roadBottomY);
    final roadPath =
        Path()
          ..moveTo(roadTopLeft.dx, roadTopLeft.dy)
          ..lineTo(roadTopRight.dx, roadTopRight.dy)
          ..lineTo(roadBottomRight.dx, roadBottomRight.dy)
          ..lineTo(roadBottomLeft.dx, roadBottomLeft.dy)
          ..close();

    final roadTopCenter = Offset(
      (roadLeftEdgeTop + roadRightEdgeTop) / 2,
      roadTopY,
    );

    // Draw the road with a gradient
    final roadPaint =
        Paint()
          ..shader = ui.Gradient.linear(
            roadTopCenter,
            Offset(roadRightEdgeBottom, roadBottomY),
            laneColors,
            [
              0.0,
              0.5,
              0.66,
              1.0,
            ], // Four evenly spaced color stops to match the four colors
          );
    canvas.drawPath(roadPath, roadPaint);
  }
}
