#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D uTexture;  // Input texture from Rive

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  
  // Original color from the Rive artboard - using texture() instead of texture2D()
  vec4 color = texture(uTexture, uv);

  // Return black if the current pixel is dark
  if (color.r < 0.1 && color.g < 0.1 && color.b < 0.1) {
    fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    return;
  }
  
  // Apply a wave effect based on time
  float wave = sin(uv.y * 10.0 + uTime * 2.0) * 0.5 + 0.5;
  
  // Mix the original color with a colorful gradient
  vec3 shaderColor = mix(
    vec3(0.2, 0.6, 1.0),
    vec3(1.0, 0.4, 0.7),
    wave
  );
  
  // Keep the original alpha to preserve transparency
  fragColor = vec4(mix(color.rgb, shaderColor, 0.4), color.a);
}