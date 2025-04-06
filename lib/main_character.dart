import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/events.dart' show TapCallbacks, TapDownEvent;
import 'package:flame/game.dart' show Vector2;
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:rocksucks/main.dart';

class MainCharacter extends RiveComponent with TapCallbacks {
  final ui.FragmentShader? shader;
  double time_ = 0.0;
  final RockGame gameRef;

  MainCharacter(Artboard artboard, this.shader, this.gameRef)
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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Calculate the maximum width as one-third of the smallest axis
    final maxWidth = size.x < size.y ? size.x / 3 : size.y / 3;

    // Set the size of the character
    this.size = Vector2(maxWidth, maxWidth);

    // Position the character in the middle bottom of the screen
    position = Vector2(
      (size.x - this.size.x) / 2, // Center horizontally
      size.y - this.size.y, // Align to the bottom
    );
  }

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
    // canvas.restore();

    drawFace(canvas, size);
  }

  void drawFace(Canvas canvas, Vector2 size) {
    if (currentAnimation.animationName == 'stone to scissors') return;

    // final bounds = artboard.layoutBounds;
    var bounds = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );

    final centerOffset = Offset(-20, 20);
    bounds = bounds.shift(centerOffset);

    //  dot eyes
    final offset = Offset(0.08 * size.x, -0.05 * size.y);
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
        0.001 * size.x,
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }

    // halfCircleMouth
    canvas.drawArc(
      Rect.fromCircle(
        center: bounds.center + Offset(0, 0.1 * size.y),
        radius: 0.1 * size.x,
      ),
      (3.14 * 0.2 + 0.2 * math.sin(gameRef.time * 2)),
      3.14 * 0.6,
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
