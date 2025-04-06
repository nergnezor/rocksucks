import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart' show TapCallbacks, TapDownEvent;
import 'package:flame/game.dart' show Vector2;
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:rocksucks/main.dart';

class Enemy extends Player {
  Enemy(super.artboard, super.shader, super.gameRef) {
    scale.y = -1; // Flip the enemy vertically
  }
  @override
  void onLoad() {
    super.onLoad();
    _currentIndex = 1; // Start with the "bag" animation
    currentAnimation.isActive = true;
  }

  double hSpeed = 0.0;
  double vSpeed = 100.0;
  double baseSize = 100.0; // Base size to scale from

  // Calculate scale factor based on y position
  void updatePerspectiveScale() {
    // Get the screen height for calculation
    final screenHeight = gameRef.size.y;

    // Calculate scale factor based on y position (0.7 to 1.5 range)
    // The deeper the enemy is in the scene, the larger it should appear
    double scaleFactor = 0.7 + (position.y / screenHeight) * 0.8;

    // Apply scale while keeping vertical flip (-1)
    scale.x = scaleFactor;
    scale.y = -scaleFactor; // Maintain vertical flip with new scale
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fall if bag
    switch (currentAnimation.animationName) {
      case 'stone to scissors':
        hSpeed = 0.0;
        break;
      case 'closed scissors to bag':
        hSpeed =
            math.Random().nextDouble() * 100 - 50; // Random horizontal speed
        // Update the position of the enemy to fall down
        position.y += vSpeed * dt; // Adjust the speed as needed
        // Add random horizontal speed
        // Check if the enemy is out of bounds and reset its position
        if (position.y > gameRef.size.y / 2) {
          // position.y = size.y; // Reset to the top of the screen
          // vSpeed *= -1; // Reverse the vertical speed
          vSpeed /= 2; // Reverse the vertical speed
          cycleShape();
        }
        break;
      case 'bag to stone':
        hSpeed = 0.0;
        position.y += vSpeed * dt; // Adjust the speed as needed
        break;
    }

    // Apply horizontal movement if there is any
    if (hSpeed != 0) {
      position.x += hSpeed * dt;
    }

    // Update scale based on perspective
    updatePerspectiveScale();
  }
}

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

    [...shapes, scissoring].forEach(artboard.addController);
  }

  @override
  void render(Canvas canvas) {
    // Save the canvas state
    canvas.save();

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
    canvas.restore();

    if (this is Enemy) {
      // Draw the face on top of the shader
      drawFace(canvas, size);
    }
  }

  void drawFace(Canvas canvas, Vector2 size) {
    if (currentAnimation.animationName == 'stone to scissors') return;

    // Save the canvas state for rotation
    canvas.save();

    var bounds = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );

    // Calculate roll angle based on time - creates a rolling effect
    final rollAngle = gameRef.time * 2.0; // Controls rotation speed

    // Apply rolling transformation to simulate forward rolling (not sideways)
    canvas.translate(size.x / 2, size.y / 2); // Move to center

    // Instead of rotating around z-axis, we simulate x-axis rotation with scaling
    // This creates the illusion of forward rolling rather than sideways
    final scaleY =
        1.0 +
        0.2 * math.sin(rollAngle); // Vertical scaling to simulate forward roll
    canvas.scale(1.0, scaleY);

    // Apply a small z-rotation to add some natural movement
    canvas.rotate(
      rollAngle * 0.2,
    ); // Reduced rotation for slight sideways movement

    canvas.translate(-size.x / 2, -size.y / 2); // Move back

    // Calculate vertical bouncing to simulate ball movement
    final bounceOffset =
        math.sin(rollAngle) * size.y * 0.05; // Increased bounce effect

    final centerOffset = Offset(
      size.x / -16 +
          math.cos(rollAngle) * size.x * 0.02, // Horizontal oscillation
      size.y / 10 + bounceOffset, // Add bounce effect
    );
    bounds = bounds.shift(centerOffset);

    //  dot eyes
    final offset = Offset(0.08 * size.x, 0.05 * size.y);
    for (int i = -1; i <= 1; i += 2) {
      // Calculate eye position with slight wiggle based on roll
      final eyeOffset = Offset(
        i * offset.dx + math.cos(rollAngle + i) * size.x * 0.01,
        offset.dy + math.sin(rollAngle * 1.5) * size.y * 0.01,
      );

      // Adjust eye position based on roll angle to enhance forward rolling illusion
      final adjustedEyeOffset = Offset(
        eyeOffset.dx,
        eyeOffset.dy -
            math.sin(rollAngle) * size.y * 0.03, // Eyes move up/down with roll
      );

      canvas.drawCircle(
        bounds.center + adjustedEyeOffset,
        0.035 * size.x,
        Paint()..color = const Color(0xFF000000),
      );

      // specular highlight
      canvas.drawCircle(
        bounds.center +
            adjustedEyeOffset +
            Offset(-0.01 * size.x, -0.01 * size.y),
        0.002 * size.x,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }

    // halfCircleMouth that changes shape as it rolls
    final mouthAngle = 3.14 * -0.6 + 0.3 * math.sin(rollAngle * 0.8);
    final mouthWidth = 3.14 * (0.2 + 0.1 * math.cos(rollAngle));

    // Adjust mouth position based on roll angle
    final mouthYOffset =
        math.sin(rollAngle) * size.y * 0.04; // Mouth moves up/down with roll

    canvas.drawArc(
      Rect.fromCircle(
        center: bounds.center + Offset(0, -0.01 * size.y + mouthYOffset),
        radius: 0.05 * size.x,
      ),
      mouthAngle,
      mouthWidth,
      false,
      Paint()
        ..color = const Color(0x7F000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.01 * size.x,
    );

    // Restore the canvas state
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    cycleShape();
  }

  void cycleShape() {
    previousAnimation.reset();
    _currentIndex = (_currentIndex + 1) % shapes.length;
    currentAnimation.isActive = true;
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    scissoring.isActive = !scissoring.isActive;
  }

  bool checkCollision(Enemy enemy) {
    // Simple collision detection based on position and size
    final distance = position.distanceTo(enemy.position);
    // Calculate collision threshold based on the sizes of both entities
    final collisionThreshold =
        (size.x + enemy.size.x) * 0.25; // 25% of combined width
    return distance < collisionThreshold;
  }

  // Method to handle enemy interactions
  void handleEnemyCollision(Enemy enemy) {
    // If player is in bag state and collides with enemy
    if (currentAnimation.animationName == 'closed scissors to bag') {
      // Shoot enemy out in the opposite direction
      enemy.vSpeed = -300.0; // Faster upward speed

      // Add some horizontal movement away from player
      final directionFromPlayer = (enemy.position.x - position.x);
      // If enemy is directly above, give it a slight push to either side
      enemy.hSpeed =
          directionFromPlayer == 0
              ? (math.Random().nextBool() ? 150 : -150)
              : directionFromPlayer *
                  3; // Amplify existing horizontal difference

      // Visual effect - make the enemy spin faster by cycling shape
      enemy.cycleShape();
    }
  }
}
