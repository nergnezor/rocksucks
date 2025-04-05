import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const GameWidget.controlled(gameFactory: RiveExampleGame.new));
}

class RiveExampleGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    final skillsArtboard = await loadArtboard(
      RiveFile.asset('assets/rocksucks.riv'),
      artboardName: 'Artboard',
    );
    add(SkillsAnimationComponent(skillsArtboard));
  }
}

// Enum to track the current animation state
enum AnimationState { scissors, bag, stone }

class SkillsAnimationComponent extends RiveComponent with TapCallbacks {
  SkillsAnimationComponent(Artboard artboard) : super(artboard: artboard);

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
