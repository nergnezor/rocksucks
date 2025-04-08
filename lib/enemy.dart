import 'dart:math' as math;
import 'package:rocksucks/player.dart';

class Enemy extends Player {
  Enemy(super.artboard, super.shader, super.gameRef) {
    scale.y = -1; // Flip the enemy vertically
  }
  @override
  void onLoad() {
    super.onLoad();
    cycleShape();
    // vSpeed = startSpeed;
    // reset(); // Set initial vertical speed
  }

  // void reset() {
  //   // _currentIndex = 1; // Start with the "bag" animation
  //   currentAnimation.isActive = true;
  //   updatePerspectiveScale();
  //   fluttering.isActive = true;
  // }

  static const double startSpeed = 100.0;
  double hSpeed = 0.0;
  double vSpeed = startSpeed;
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
      case 'closed scissors to bag':
        hSpeed =
            math.Random().nextDouble() * 100 - 50; // Random horizontal speed
        // Update the position of the enemy to fall down
        position.y += vSpeed * dt; // Adjust the speed as needed
        // Add random horizontal speed
        // Check if the enemy is out of bounds and reset its position
        if (position.y > gameRef.size.y / 2) {
          cycleShape();
          rolling.isActive = true;
          vSpeed = 0;
        }
        break;
      case 'bag to stone':
        hSpeed = 0.0;
        position.y += vSpeed * dt; // Adjust the speed as needed
        vSpeed += 1;
        updatePerspectiveScale();
        break;
    }

    // Apply horizontal movement if there is any
    if (hSpeed != 0) {
      position.x += hSpeed * dt;
    }

    // reset position if out of bounds
    if (position.y > gameRef.size.y) {
      position.y -= gameRef.size.y;
      // reset();
      gameRef.enemies.remove(this); // Remove from the list of enemies
      gameRef.remove(this); // Remove the enemy if it goes out of bounds
    }
  }
}
