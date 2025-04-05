import 'dart:ui' as ui;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';

void main() async {
  // Initialize the shader before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Load the shader using the correct path and asset bundle
  final shaderProgram = await ui.FragmentProgram.fromAsset(
    'assets/shaders/rive_shader.frag',
  );

  runApp(
    GameWidget.controlled(
      gameFactory: () => RiveExampleGame(shaderProgram: shaderProgram),
    ),
  );
}

class RiveExampleGame extends FlameGame {
  final ui.FragmentProgram shaderProgram;
  late ui.FragmentShader fragmentShader;
  double time = 0;

  RiveExampleGame({required this.shaderProgram});

  @override
  Future<void> onLoad() async {
    // Initialize the fragment shader
    try {
      fragmentShader = shaderProgram.fragmentShader();
      print('Shader loaded successfully.');
    } catch (e) {
      print('Error loading shader: $e');
    }

    // Initial uniform values
    updateShaderUniforms();

    final skillsArtboard = await loadArtboard(
      RiveFile.asset('assets/rocksucks.riv'),
      artboardName: 'Artboard',
    );

    add(SkillsAnimationComponent(skillsArtboard, shader: fragmentShader));
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
}

// Enum to track the current animation state
enum AnimationState { scissors, bag, stone }

class SkillsAnimationComponent extends RiveComponent with TapCallbacks {
  final ui.FragmentShader? shader;

  SkillsAnimationComponent(Artboard artboard, {this.shader})
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
    this.size = size;
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
    if (shader != null) {
      try {
        // Save the canvas state
        canvas.save();

        // First, render the Rive animation to a separate image that we can use as a texture
        final recorder = ui.PictureRecorder();
        final tempCanvas = Canvas(recorder);
        super.render(tempCanvas);
        final picture = recorder.endRecording();

        // Convert to an image so we can use it as a texture input for the shader
        final image = picture.toImageSync(size.x.ceil(), size.y.ceil());

        // Clear shader uniform values from any previous frames
        shader!.setFloat(0, size.x); // uResolution.x
        shader!.setFloat(1, size.y); // uResolution.y

        // Explicitly set the sampler with proper name
        shader!.setImageSampler(0, image);

        // Create a paint with the shader
        final paint = Paint()..shader = shader!;

        // Draw a rectangle with the shader to the main canvas
        canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);

        // Clean up resources
        image.dispose();

        // Restore the canvas state
        canvas.restore();
      } catch (e) {
        print('Error applying shader: $e');
        // Fallback to regular rendering
        super.render(canvas);
      }
    } else {
      // Regular rendering
      super.render(canvas);
    }
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
