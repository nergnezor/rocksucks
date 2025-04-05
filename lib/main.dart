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
    fragmentShader = shaderProgram.fragmentShader();

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
    fragmentShader.setFloat(2, time);
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
        // First, save the canvas state
        canvas.save();

        // Create a recorder for the main artboard rendering
        final recorder = ui.PictureRecorder();
        final layerCanvas = Canvas(recorder);

        // Normal Rive rendering to capture the entire artboard
        super.render(layerCanvas);
        final picture = recorder.endRecording();

        // Create a new recorder just for the shape mask
        final maskRecorder = ui.PictureRecorder();
        final maskCanvas = Canvas(maskRecorder);

        // Get bounds of the artboard for sizing
        final bounds = Rect.fromLTWH(0, 0, size.x, size.y);

        // Render the entire artboard
        final fullImage = picture.toImageSync(size.x.ceil(), size.y.ceil());

        // Apply shader only to the visible parts by using a blend mode
        final shaderInstance = this.shader!;
        shaderInstance.setImageSampler(0, fullImage);

        // Set up paint with the shader
        final paint = Paint()..shader = shaderInstance;

        // First draw the normal image
        canvas.drawImage(fullImage, Offset.zero, Paint());

        // Now overlay the shader only on non-transparent parts
        // This way, only the visible shapes get the shader
        paint.blendMode = BlendMode.srcIn;
        canvas.drawRect(bounds, paint);

        // Clean up resources
        fullImage.dispose();
        canvas.restore();
      } catch (e) {
        print('Shader error: $e');
        // Fallback to regular rendering
        super.render(canvas);
      }
    } else {
      // Fall back to normal rendering if shader is not available
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
