import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart' show TapCallbacks, TapDownEvent;
import 'package:flame/game.dart' show Vector2;
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:rocksucks/main.dart';

class Enemy extends Player {
  Enemy(super.artboard, super.shader, super.gameRef) {
    // // Set the initial position of the enemy
    // position = Vector2(
    //   gameRef.size.x - size.x - 20,
    //   gameRef.size.y - size.y - 20,
    // );
    // angle = math.pi; // Rotate the enemy to face downwards
    scale.y = -1; // Flip the enemy vertically
    // artboard.
  }
  // late final List<String> _animationNames = [
  //   'stone to scissors',
  //   'closed scissors to bag',
  //   'bag to stone',
  // ];
  @override
  void onLoad() {
    super.onLoad();
    // Set the initial state to bag
    _currentIndex = 1; // Start with the "bag" animation
    currentAnimation.isActive = true;

    // TODO: Flip vertically to make a parachute of the bags
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Fall if bag
    if (currentAnimation.animationName == 'closed scissors to bag') {
      // Update the position of the enemy to fall down
      position.y += 100 * dt; // Adjust the speed as needed
    }

    // Check if the enemy is out of bounds and reset its position
    if (position.y > gameRef.size.y) {
      position.y = -size.y; // Reset to the top of the screen
      cycleShape(); // Cycle to the next shape
    }
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

    // final bounds = artboard.layoutBounds;
    var bounds = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );

    final centerOffset = Offset(size.x / -16, size.y / 10);
    bounds = bounds.shift(centerOffset);

    //  dot eyes
    final offset = Offset(0.08 * size.x, 0.05 * size.y);
    for (int i = -1; i <= 1; i += 2) {
      canvas.drawCircle(
        bounds.center + Offset(i * offset.dx, offset.dy),
        0.035 * size.x,
        Paint()..color = const Color(0xFF000000),
      );

      // specular highlight
      canvas.drawCircle(
        bounds.center +
            Offset(i * offset.dx - 0.01 * size.x, offset.dy - 0.01 * size.y),
        0.002 * size.x,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }

    // halfCircleMouth
    canvas.drawArc(
      Rect.fromCircle(
        center: bounds.center + Offset(0, -0.01 * size.y),
        radius: 0.05 * size.x,
      ),
      (3.14 * -0.6 + 0.2 * math.sin(gameRef.time * 5)),
      3.14 * 0.2,
      false,
      Paint()
        ..color = const Color(0x7F000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.01 * size.x,
    );
    //  dotNose
    canvas.drawCircle(
      bounds.center,
      0.02 * size.x,
      Paint()..color = const Color(0xCF000000),
    );
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
}
