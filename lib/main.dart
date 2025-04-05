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
    'closed scissors to bag',
    'bag to stone',
  ];

  SimpleAnimation scissoring = SimpleAnimation('scissoring', autoplay: false);

  SimpleAnimation get currentAnimation =>
      _animations[(_currentIndex) % _animations.length];
  SimpleAnimation get nextAnimation =>
      _animations[(_currentIndex + 1) % _animations.length];
  SimpleAnimation get previousAnimation =>
      _animations[(_currentIndex - 1) % _animations.length];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onLoad() {
    _animations =
        _animationNames
            .map((name) => SimpleAnimation(name, autoplay: false))
            .toList();

    for (final animation in _animations) {
      artboard.addController(animation);
    }
    // Add the scissoring animation to the artboard
    artboard.addController(scissoring);
  }

  @override
  void onTapDown(TapDownEvent event) {
    previousAnimation.reset();

    _currentIndex = (_currentIndex + 1) % _animations.length;

    currentAnimation.isActive = true;
  }

  @override
  void onLongTapDown(TapDownEvent event) {
    // _animations.first.reset();
    // _animations.first.isActive = true;
    // _animations.first.isActive = false;
    // currentAnimation.isActive = false;
    // _animations.first.isActive = false;
    scissoring.isActive = !scissoring.isActive;
  }
}
