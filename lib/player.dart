import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart' show TapCallbacks, TapDownEvent;
import 'package:flame/game.dart' show Vector2;
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:rocksucks/enemy.dart';
import 'package:rocksucks/main.dart';

class Player extends RiveComponent with TapCallbacks {
  final ui.FragmentShader? shader;
  double time_ = 0.0;
  final RockGame gameRef;

  Player(Artboard artboard, this.shader, this.gameRef)
    : super(artboard: artboard);

  int _currentIndex = 0;

  late final List<SimpleAnimation> shapes;
  late final List<String> _animationNames = [
    'stone to scissors',
    'closed scissors to bag',
    'bag to stone',
  ];

  SimpleAnimation scissoring = SimpleAnimation('scissoring', autoplay: false);
  SimpleAnimation rolling = SimpleAnimation('rolling', autoplay: false);
  SimpleAnimation fluttering = SimpleAnimation('fluttering', autoplay: false);

  SimpleAnimation get currentAnimation =>
      shapes[(_currentIndex) % shapes.length];
  SimpleAnimation get nextAnimation =>
      shapes[(_currentIndex + 1) % shapes.length];
  SimpleAnimation get previousAnimation =>
      shapes[(_currentIndex - 1) % shapes.length];

  @override
  void onLoad() {
    shapes =
        _animationNames
            .map((name) => SimpleAnimation(name, autoplay: false))
            .toList();

    [
      ...shapes,
      scissoring,
      rolling,
      fluttering,
    ].forEach(artboard.addController);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // drawWithShader(canvas);
  }

  void drawWithShader(ui.Canvas canvas) {
    // Save the canvas state
    // canvas.save();

    // First, render the Rive animation to a separate image that we can use as a texture
    final recorder = ui.PictureRecorder();
    final tempCanvas = Canvas(recorder);
    super.render(tempCanvas);
    final picture = recorder.endRecording();

    // Convert to an image so we can use it as a texture input for the shader
    // final image = picture.toImageSync(size.x.ceil(), size.y.ceil());

    // Clear shader uniform values from any previous frames
    shader!.setFloat(0, size.x); // uResolution.x
    shader!.setFloat(1, size.y); // uResolution.y

    // Explicitly set the sampler with proper name
    shader!.setImageSampler(
      0,
      picture.toImageSync(size.x.ceil(), size.y.ceil()),
    );

    // Create a paint with the shader
    final paint = Paint()..shader = shader!;

    // Draw a rectangle with the shader to the main canvas
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

    // Clean up resources
    // image.dispose();

    // Restore the canvas state
    // canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    cycleShape();
  }

  void cycleShape() {
    previousAnimation.reset();
    _currentIndex = (_currentIndex + 1) % shapes.length;
    // if (this is Enemy &&
    //     currentAnimation.animationName == 'stone to scissors') {
    //   _currentIndex = (_currentIndex + 1) % shapes.length;
    // }
    currentAnimation.isActive = true;
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    scissoring.isActive = !scissoring.isActive;
  }

  // bool checkCollision(Enemy enemy) {
  //   // Simple collision detection based on position and size
  //   final distance = position.distanceTo(enemy.position);
  //   // Calculate collision threshold based on the sizes of both entities
  //   final collisionThreshold =
  //       (size.x + enemy.size.x) * 0.25; // 25% of combined width
  //   return distance < collisionThreshold;
  // }

  // // Method to handle enemy interactions
  // void handleEnemyCollision(Enemy enemy) {
  //   // If player is in bag state and collides with enemy
  //   if (currentAnimation.animationName == 'closed scissors to bag') {
  //     // Shoot enemy out in the opposite direction
  //     enemy.vSpeed = -300.0; // Faster upward speed

  //     // Add some horizontal movement away from player
  //     final directionFromPlayer = (enemy.position.x - position.x);
  //     // If enemy is directly above, give it a slight push to either side
  //     enemy.hSpeed =
  //         directionFromPlayer == 0
  //             ? (math.Random().nextBool() ? 150 : -150)
  //             : directionFromPlayer *
  //                 3; // Amplify existing horizontal difference

  //     // Visual effect - make the enemy spin faster by cycling shape
  //     enemy.cycleShape();
  //   }
  // }
}
