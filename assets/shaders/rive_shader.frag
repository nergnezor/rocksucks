#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D input_texture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  // Sample the texture at the current UV coordinates
  vec4 color = texture(input_texture, uv);

  // Edge detection: compare the alpha of neighboring pixels
  float pixelSize = 1.0 / min(uResolution.x, uResolution.y);
  vec2 offset = vec2(pixelSize);

  float alpha = color.a;
  float edge = 0.0;

const int stroke = 1; // Stroke width
  // Check a stroke-pixel radius for center-aligned edges
  for (int x = -stroke; x <= stroke; x++) {
    for (int y = -stroke; y <= stroke; y++) {
      float neighborAlpha = texture(input_texture, uv + vec2(x, y) * offset).a;
      if (abs(alpha - neighborAlpha) > 0.1) {
        edge = 1.0;
      }
    }
  }

  // Antialiasing: smooth the edges using a gradient
  float smoothEdge = smoothstep(0.0, 1.0, edge);

  // Apply a white stroke to center-aligned edges
  vec3 strokeColor = vec3(1.0, 1.0, 1.0);

  // Mix the original color with the stroke color
  vec3 finalColor = mix(color.rgb, strokeColor, smoothEdge);

  fragColor = vec4(finalColor, max(color.a, smoothEdge));
}