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

  // Current animation index
  int _currentIndex = 0;

  // Animation data storage
  late final List<SimpleAnimation> _animations;
  late final List<String> _animationNames = [
    'stone to scissors',
    'scissors to bag',
    'bag to stone',
  ];
  // currentAnimation() => _animations[_currentIndex];
  SimpleAnimation get currentAnimation => _animations[_currentIndex];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onLoad() {
    // Create all animations from the names list
    _animations =
        _animationNames
            .map((name) => SimpleAnimation(name, autoplay: false))
            .toList();

    // Add the first animation controller to the artboard
    // artboard.addController(_animations[_currentIndex]);

    for (final animation in _animations) {
      artboard.addController(animation);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    _currentIndex = (_currentIndex + 1) % _animations.length;

    currentAnimation.isActive = true;

    print('Animation: ${_animationNames[_currentIndex]}');
  }
}
