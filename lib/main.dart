import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:rocksucks/main_character.dart';

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
    add(
      MainCharacter(mainArtboard, fragmentShader, this)
        ..size = Vector2(200, 200) // Set the size of the character
        ..position = Vector2(
          (size.x - 200) / 2, // Center horizontally
          size.y - 200, // Align to the bottom
        ),
    );

    // Add enemies with separate artboards
    addEnemies(5, riveFile, fragmentShader, this);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
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

  void addEnemies(
    int count,
    RiveFile riveFile,
    ui.FragmentShader shader,
    RockGame gameRef,
  ) async {
    for (int j = 0; j < count; j++) {
      // Create a new artboard for each enemy
      final enemyArtboard = await loadArtboard(
        riveFile,
        artboardName: 'Artboard',
      );

      final enemy =
          Enemy(enemyArtboard, shader, gameRef)
            ..size = Vector2(200, 200) // Set the size of the enemy
            ..position = Vector2(
              (size.x - 200) * (j + 1) / (count + 1), // Center horizontally
              size.y - 200, // Align to the bottom
            );

      add(enemy);
    }
  }
}
