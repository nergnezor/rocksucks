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
  float alphaN = texture(input_texture, uv + vec2(0.0, offset.y)).a;
  float alphaE = texture(input_texture, uv + vec2(offset.x, 0.0)).a;
  float alphaS = texture(input_texture, uv + vec2(0.0, -offset.y)).a;
  float alphaW = texture(input_texture, uv + vec2(-offset.x, 0.0)).a;

  // Determine if the current pixel is an edge
  float isEdge = step(0.1, alpha) * (1.0 - step(0.1, alphaN) * step(0.1, alphaE) * step(0.1, alphaS) * step(0.1, alphaW));

  // Apply a white stroke to edges
  vec3 strokeColor = vec3(1.0, 1.0, 1.0);

  // Mix the original color with the stroke color
  vec3 finalColor = mix(color.rgb, strokeColor, isEdge);

  fragColor = vec4(finalColor, color.a);
}