#version 460 core

precision highp float;

#include <flutter/runtime_effect.glsl>

// Uniform inputs
uniform vec2 uResolution;
uniform float uTime;
uniform sampler2D input_texture;

// Constants for edge detection and stroke
const int STROKE_RADIUS = 3;
const float ALPHA_THRESHOLD = 0.1;
// const float EDGE_NORMALIZATION = 1.0;
const float ZERO = 0.0;
const float ONE = 1.0;
const vec3 WHITE_COLOR = vec3(1.0, 1.0, 1.0);
const float SMOOTHING =3; // Controls the smoothness of the stroke

float smoothEdge(float edge, float radius) {
    // Apply smooth falloff based on distance
    return smoothstep(ZERO, radius, edge);
}

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec4 color = texture(input_texture, uv);
    
    float pixelSize = ONE / min(uResolution.x, uResolution.y);
    vec2 offset = vec2(pixelSize);
    
    float alpha = color.a;
    float edge = ZERO;
    float totalWeight = ZERO;
    
    // Sample in a circular pattern for smoother edges
    for (int x = -STROKE_RADIUS; x <= STROKE_RADIUS; x++) {
        for (int y = -STROKE_RADIUS; y <= STROKE_RADIUS; y++) {
            float dist = length(vec2(x, y));
            if (dist <= float(STROKE_RADIUS)) {
                vec2 sampleOffset = vec2(x, y) * offset;
                float neighborAlpha = texture(input_texture, uv + sampleOffset).a;
                
                // Weight the sample based on distance from center
                float weight = 1.0 - (dist / float(STROKE_RADIUS));
                weight = smoothstep(0.0, 1.0, weight);
                
                if (abs(alpha - neighborAlpha) > ALPHA_THRESHOLD) {
                    edge += weight;
                }
                totalWeight += weight;
            }
        }
    }
    
    // Normalize edge value considering total weight
    edge = edge / max(totalWeight, 1.0);
    
    // Apply additional smoothing
    edge = smoothEdge(edge * SMOOTHING, 1.0);
    
    // Mix the original color with the stroke color using smooth interpolation
    vec3 finalColor = mix(color.rgb, WHITE_COLOR, edge);
    
    // Output with smooth alpha transition
    float finalAlpha = max(color.a, smoothstep(0.0, 0.1, edge));
    fragColor = vec4(finalColor, finalAlpha);
}