import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame_rive/flame_rive.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:rocksucks/player.dart';

void main() async {
  // Initialize the shader before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Load the shader using the correct path and asset bundle
  final shaderProgram = await ui.FragmentProgram.fromAsset(
    'assets/shaders/rive_shader.frag',
  );

  runApp(
    GameWidget.controlled(
      gameFactory: () => RockGame(shaderProgram: shaderProgram),
    ),
  );
}

class RockGame extends FlameGame {
  final ui.FragmentProgram shaderProgram;
  late ui.FragmentShader fragmentShader;
  double time = 0;

  RockGame({required this.shaderProgram});

  @override
  Color backgroundColor() => const Color(0xFFE0E0E0); // Light gray background

  @override
  Future<void> onLoad() async {
    // Add FPS counter
    add(
      FpsTextComponent(
        position: Vector2(10, 10),
        scale: Vector2.all(1.0),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
      ),
    );

    // Initialize the fragment shader
    try {
      fragmentShader = shaderProgram.fragmentShader();
      print('Shader loaded successfully.');
    } catch (e) {
      print('Error loading shader: $e');
    }

    // Initial uniform values
    updateShaderUniforms();

    // Load the Rive file once
    final riveFile = await RiveFile.asset('assets/rocksucks.riv');

    // Create the main character with its own artboard
    final mainArtboard = await loadArtboard(riveFile, artboardName: 'Artboard');

    // Add the main character
    final playerWidth = 400.0;
    add(
      Player(mainArtboard, fragmentShader, this)
        ..size = Vector2(
          playerWidth,
          playerWidth,
        ) // Set the size of the character
        ..position = Vector2(
          (size.x - playerWidth) / 2, // Center horizontally
          size.y - playerWidth, // Align to the bottom
        ),
    );

    // Add enemies with separate artboards
    addEnemies(5, riveFile, fragmentShader, this);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
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

  @override
  void render(Canvas canvas) {
    drawLanes(canvas, size.x, size.y);

    super.render(canvas);
  }

  void addEnemies(
    int count,
    RiveFile riveFile,
    ui.FragmentShader shader,
    RockGame gameRef,
  ) async {
    final random = Random();
    for (int j = 0; j < count; j++) {
      // Create a new artboard for each enemy
      final enemyArtboard = await loadArtboard(
        riveFile,
        artboardName: 'Artboard',
      );

      final w = 100.0; // Width of the enemy
      final randomOffsetX =
          random.nextDouble() * 50 - 25; // Random offset between -25 and 25
      final randomOffsetY =
          random.nextDouble() * 50 - 25; // Random offset between -25 and 25

      final enemy =
          Enemy(enemyArtboard, shader, gameRef)
            ..size = Vector2(w, w) // Set the size of the enemy
            ..position = Vector2(
              (size.x - w) * (j + 1) / (count + 1) +
                  randomOffsetX, // Center horizontally with offset
              w + randomOffsetY, // Align to the bottom with offset
            );

      add(enemy);
    }
  }

  void drawLanes(ui.Canvas canvas, double x, double y) {
    // Define the pastel colors for each lane with enhanced saturation
    final List<Color> laneColors = [
      const Color(0xFFFFD6E0), // Pastel pink
      const Color(0xFFD6EAFF), // Pastel blue
      const Color(0xFFD6FFE1), // Pastel green
      const Color(0xFFFFF8D6), // Pastel yellow
    ];

    // Define the vanishing point (center of the screen, about 1/3 from the top)
    final vanishingPointX = x / 2;
    final vanishingPointY = y * 0.3;

    // Define the width of the road at the bottom of the screen
    final roadBottomWidth = x * 0.8;
    final roadLeftEdgeBottom = (x - roadBottomWidth) / 2;
    final roadRightEdgeBottom = roadLeftEdgeBottom + roadBottomWidth;

    // Use time variable for animated curves with multiple frequency components
    // This creates a more organic wave-like motion
    final curveTimeFactor =
        sin(time * 0.5) * 0.3 +
        sin(time * 0.2) * 0.1 +
        0.7; // Oscillates more naturally between 0.3 and 1.1

    // Simulate occasional road bumps
    final bumpEffect = sin(time * 3) > 0.9 ? sin(time * 10) * 6.0 : 0.0;

    // Draw the filled lanes with gradients
    final numLanes = 4;
    for (int i = 0; i < numLanes; i++) {
      // Calculate the lanes' boundaries
      final leftFraction = i / numLanes;
      final rightFraction = (i + 1) / numLanes;

      final leftBottomX = roadLeftEdgeBottom + (roadBottomWidth * leftFraction);
      final rightBottomX =
          roadLeftEdgeBottom + (roadBottomWidth * rightFraction);

      // Create a path for the curved lane
      final path = Path();

      // Start at the vanishing point
      path.moveTo(vanishingPointX, vanishingPointY);

      // Calculate curve control points with more dynamic curves
      final baseAmplitude = 25.0;
      final curveAmplitude =
          baseAmplitude * (i % 2 == 0 ? 1 : -1) * curveTimeFactor;
      final controlY = vanishingPointY + (y - vanishingPointY) * 0.5;

      // Add time-based wave effect to curves with multiple frequencies
      final waveEffect =
          sin(time + i * 0.7) * 10.0 +
          sin(time * 1.3 + i * 0.5) * 5.0 +
          bumpEffect; // Add bump effect

      // Left edge curve control point with enhanced dynamics
      final leftControlX =
          vanishingPointX +
          (leftBottomX - vanishingPointX) * 0.5 +
          curveAmplitude * sin(i * 0.5 + time * 0.2) +
          waveEffect;

      // Right edge curve control point with enhanced dynamics
      final rightControlX =
          vanishingPointX +
          (rightBottomX - vanishingPointX) * 0.5 +
          curveAmplitude * sin(i * 0.5 + time * 0.2) +
          waveEffect;

      // Draw the curved left edge
      path.quadraticBezierTo(leftControlX, controlY, leftBottomX, y);

      // Line to the right bottom corner
      path.lineTo(rightBottomX, y);

      // Draw the curved right edge back to vanishing point
      path.quadraticBezierTo(
        rightControlX,
        controlY,
        vanishingPointX,
        vanishingPointY,
      );

      // Close the path
      path.close();

      // Create an enhanced gradient for the lane with three color stops
      final gradient = ui.Gradient.linear(
        Offset(vanishingPointX, vanishingPointY),
        Offset((leftBottomX + rightBottomX) / 2, y),
        [
          laneColors[i].withOpacity(0.5), // Start with more transparent
          laneColors[i].withOpacity(0.8), // Middle transition
          laneColors[i], // End with full color
        ],
        [0.0, 0.7, 1.0], // Position each color stop
      );

      // Draw the filled lane with gradient
      canvas.drawPath(
        path,
        Paint()
          ..shader = gradient
          ..style = PaintingStyle.fill,
      );

      // Add pavement texture to each lane
      _drawPavementTexture(canvas, path, i);

      // Add enhanced shadow gradient along the edges for depth
      final shadowPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..shader = ui.Gradient.linear(
              Offset(vanishingPointX, vanishingPointY),
              Offset((leftBottomX + rightBottomX) / 2, y),
              [
                Colors.black.withOpacity(0.5), // Darker at vanishing point
                Colors.black.withOpacity(0.2), // Middle transition
                Colors.black.withOpacity(0.0), // Fades completely at bottom
              ],
              [0.0, 0.6, 1.0],
            );

      canvas.drawPath(path, shadowPaint);

      // Add an inner glow effect for more depth
      final innerGlowPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..shader = ui.Gradient.linear(
              Offset(vanishingPointX, vanishingPointY),
              Offset((leftBottomX + rightBottomX) / 2, y),
              [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.0)],
              [0.0, 0.5],
            );

      // Slightly smaller path for inner glow
      final innerPath = Path();
      innerPath.moveTo(vanishingPointX, vanishingPointY + 2);
      innerPath.quadraticBezierTo(
        leftControlX,
        controlY + 1,
        leftBottomX + 2,
        y - 2,
      );
      innerPath.lineTo(rightBottomX - 2, y - 2);
      innerPath.quadraticBezierTo(
        rightControlX,
        controlY + 1,
        vanishingPointX,
        vanishingPointY + 2,
      );

      canvas.drawPath(innerPath, innerGlowPaint);
    }

    // Draw horizontal connector lines with enhanced curve for more road-like appearance
    final segments = 12; // Increased segments for smoother road
    final linePaint =
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..style = PaintingStyle.stroke;

    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final segmentY = vanishingPointY + (y - vanishingPointY) * t;

      // Add a dynamic curve to the horizontal lines for enhanced 3D effect
      final curveOffset = 8.0 * sin(t * pi * 0.5 + time * 0.3) + bumpEffect * t;

      // Calculate perspective width at this y-coordinate with curve
      final segmentLeftX =
          vanishingPointX +
          (roadLeftEdgeBottom - vanishingPointX) * t -
          curveOffset * t;
      final segmentRightX =
          vanishingPointX +
          (roadRightEdgeBottom - vanishingPointX) * t +
          curveOffset * t;

      // Draw curved horizontal line
      final horizontalPath = Path();
      horizontalPath.moveTo(segmentLeftX, segmentY);

      // Add a dynamic curve to the horizontal line
      final midX = (segmentLeftX + segmentRightX) / 2;
      final curveY = segmentY + curveOffset * sin(time * 0.5);

      horizontalPath.quadraticBezierTo(midX, curveY, segmentRightX, segmentY);

      // Variable stroke width for perspective with animation effect
      final strokePulse = 0.2 * sin(time * 3 + i * 0.5);
      linePaint.strokeWidth = (1.0 + t * 1.5) * (1.0 + strokePulse);

      canvas.drawPath(horizontalPath, linePaint);
    }

    // Draw lane markers/dividers with pulsing animations
    _drawLaneMarkers(
      canvas,
      x,
      y,
      vanishingPointX,
      vanishingPointY,
      roadLeftEdgeBottom,
      roadRightEdgeBottom,
    );

    // Add occasional roadside objects
    _drawRoadsideObjects(
      canvas,
      x,
      y,
      vanishingPointX,
      vanishingPointY,
      roadLeftEdgeBottom,
      roadRightEdgeBottom,
    );
  }

  // Helper method to draw pavement texture
  void _drawPavementTexture(Canvas canvas, Path lanePath, int laneIndex) {
    // Create a clipPath to restrict drawing to the lane area
    canvas.save();
    canvas.clipPath(lanePath);

    // Create a subtle dotted texture pattern
    final dotPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.05)
          ..style = PaintingStyle.fill;

    // Use different texture patterns for each lane
    final random = Random(laneIndex);
    final dotCount = 100 + laneIndex * 50; // More dots for higher lane indices

    for (int i = 0; i < dotCount; i++) {
      final dotSize = random.nextDouble() * 2.0 + 1.0;
      final x = random.nextDouble() * size.x;
      final y = random.nextDouble() * size.y;

      // Only draw dots that will be visible (closer to the bottom)
      if (y > size.y * 0.4) {
        canvas.drawCircle(Offset(x, y), dotSize, dotPaint);
      }
    }

    canvas.restore();
  }

  // Helper method to draw lane markers/dividers
  void _drawLaneMarkers(
    Canvas canvas,
    double x,
    double y,
    double vanishingPointX,
    double vanishingPointY,
    double roadLeftEdgeBottom,
    double roadRightEdgeBottom,
  ) {
    final roadWidth = roadRightEdgeBottom - roadLeftEdgeBottom;
    final numLanes = 4;

    // Create paint for lane markers
    final markerPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    // Draw lane dividers
    for (int i = 1; i < numLanes; i++) {
      final fraction = i / numLanes;
      final bottomX = roadLeftEdgeBottom + (roadWidth * fraction);

      final markerPath = Path();
      markerPath.moveTo(vanishingPointX, vanishingPointY);

      // Calculate control point for the curve
      final controlX = vanishingPointX + (bottomX - vanishingPointX) * 0.5;
      final controlY = vanishingPointY + (y - vanishingPointY) * 0.5;

      // Animate with time for a slight wave effect
      final waveOffset = sin(time * 2 + i) * 5.0;

      // Draw the dashed line
      final dashCount = 10;
      for (int j = 0; j < dashCount; j++) {
        final t1 = j / dashCount;
        final t2 = (j + 0.5) / dashCount; // Half length of a dash

        // Only draw if this is a dash, not a gap
        if (j % 2 == 0) {
          // Calculate points along the quadratic curve
          final x1 = _calculateQuadraticPoint(
            vanishingPointX,
            controlX + waveOffset,
            bottomX,
            t1,
          );
          final y1 = _calculateQuadraticPoint(vanishingPointY, controlY, y, t1);
          final x2 = _calculateQuadraticPoint(
            vanishingPointX,
            controlX + waveOffset,
            bottomX,
            t2,
          );
          final y2 = _calculateQuadraticPoint(vanishingPointY, controlY, y, t2);

          // Draw the dash
          canvas.drawLine(
            Offset(x1, y1),
            Offset(x2, y2),
            markerPaint..strokeWidth = 1.0 + t1 * 3.0, // Perspective width
          );
        }
      }
    }
  }

  // Helper for calculating points along a quadratic Bezier curve
  double _calculateQuadraticPoint(double p0, double p1, double p2, double t) {
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
  }

  // Helper to draw occasional roadside objects in the distance
  void _drawRoadsideObjects(
    Canvas canvas,
    double x,
    double y,
    double vanishingPointX,
    double vanishingPointY,
    double roadLeftEdgeBottom,
    double roadRightEdgeBottom,
  ) {
    // Only draw objects occasionally based on time
    if (sin(time * 0.5) > 0.7) {
      final random = Random((time * 10).toInt());
      final objectSize = 10.0 + random.nextDouble() * 20.0;

      // Decide which side to draw the object (left or right)
      final isLeftSide = random.nextBool();

      // Calculate position based on perspective
      final distanceFactor =
          0.2 + random.nextDouble() * 0.3; // Between 0.2-0.5 down the road
      final objectY = vanishingPointY + (y - vanishingPointY) * distanceFactor;

      // Calculate X position based on the side of the road
      final roadWidth = roadRightEdgeBottom - roadLeftEdgeBottom;
      final perspectiveRoadWidth = roadWidth * distanceFactor;
      final perspectiveRoadLeft = vanishingPointX - (perspectiveRoadWidth / 2);
      final perspectiveRoadRight = vanishingPointX + (perspectiveRoadWidth / 2);

      final objectX =
          isLeftSide
              ? perspectiveRoadLeft - objectSize * distanceFactor
              : perspectiveRoadRight + objectSize * distanceFactor;

      // Draw a simple shape representing a roadside object
      final objectPaint =
          Paint()
            ..color = Color(0xFF555555)
            ..style = PaintingStyle.fill;

      // Draw different types of roadside objects
      final objectType = random.nextInt(3);
      switch (objectType) {
        case 0: // Tree-like shape
          final treePath = Path();
          treePath.moveTo(objectX, objectY);
          treePath.lineTo(objectX - objectSize * 0.5, objectY + objectSize);
          treePath.lineTo(objectX + objectSize * 0.5, objectY + objectSize);
          treePath.close();
          canvas.drawPath(treePath, objectPaint);

          // Tree trunk
          canvas.drawRect(
            Rect.fromLTWH(
              objectX - objectSize * 0.1,
              objectY + objectSize,
              objectSize * 0.2,
              objectSize * 0.5,
            ),
            objectPaint,
          );
          break;

        case 1: // Sign-like shape
          canvas.drawRect(
            Rect.fromLTWH(
              objectX - objectSize * 0.5,
              objectY - objectSize * 0.5,
              objectSize,
              objectSize,
            ),
            objectPaint,
          );

          // Sign post
          canvas.drawRect(
            Rect.fromLTWH(
              objectX - objectSize * 0.1,
              objectY + objectSize * 0.5,
              objectSize * 0.2,
              objectSize * 0.8,
            ),
            objectPaint,
          );
          break;

        case 2: // Rock-like shape
          final rockPath = Path();
          rockPath.addOval(
            Rect.fromCenter(
              center: Offset(objectX, objectY + objectSize * 0.7),
              width: objectSize * 1.2,
              height: objectSize,
            ),
          );
          canvas.drawPath(rockPath, objectPaint);
          break;
      }
    }
  }
}
