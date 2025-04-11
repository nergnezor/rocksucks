import 'dart:math' as math;
import 'dart:ui';
import 'package:rocksucks/player.dart';

class Enemy extends Player {
  Enemy(super.artboard, super.shader, super.gameRef);
  @override
  void onLoad() {
    super.onLoad();
    vSpeed = startSpeed;
    // cycleShape();
    fluttering.isActive = true;
    // rolling.isActive = true;
  }

  double startSpeed = 100.0 + math.Random().nextDouble() * 200.0;
  late double vSpeed;
  late double hSpeed = 0.0; // Horizontal speed
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
    scale.y = scaleFactor; // Maintain vertical flip with new scale
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (rolling.isActive) {
      hSpeed = 0.0;
      position.y += vSpeed * dt; // Adjust the speed as needed
      vSpeed *= 1.02; // Slow down the enemy over time

      updatePerspectiveScale();
    } else {
      hSpeed = math.Random().nextDouble() * 100 - 50; // Random horizontal speed

      // Update the position of the enemy to fall down
      position.y += vSpeed * dt; // Adjust the speed as needed

      // Check if the enemy is out of bounds and reset its position
      if (position.y > gameRef.size.y / 2) {
        fluttering.isActive = false;
        rolling.isActive = true;
        vSpeed = 10.0;
      }
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

  @override
  void render(Canvas canvas) {
    // Draw shadow
    final shadowPaint =
        Paint()..color = const Color(0xFF000000).withOpacity(0.5);

    var offset = Offset(size.x / 2, size.y / 1.5);
    if (fluttering.isActive) {
      canvas.drawCircle(
        offset + Offset(0, -position.y + gameRef.size.y / 2),
        (baseSize / 2) * (0 + position.y / gameRef.size.y),
        shadowPaint,
      );
    }
    if (rolling.isActive) {
      canvas.drawCircle(offset, baseSize / 4, shadowPaint);
    }
    super.render(canvas);
  }
}
