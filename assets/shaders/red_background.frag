#version 460 core

precision mediump float;

// Uniforms provided by the game
uniform vec2 resolution;  // screen resolution
uniform float time;       // game time for animation

// Define output variable for fragment color (required in GLSL 460)
out vec4 fragColor;

void main() {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // Create a pulsating effect with varying intensity
    float pulsate = 0.7 + 0.3 * sin(time * 1.5);
    
    // Add some subtle movement with circular waves
    float dist = length(uv - vec2(0.5, 0.5)) * 5.0;
    float wave = sin(dist - time * 2.0) * 0.1;
    
    // Base red color with variation
    float redIntensity = 0.7 + wave;
    redIntensity *= pulsate;
    
    // Clamp the red value to avoid overflow
    redIntensity = clamp(redIntensity, 0.0, 1.0);
    
    // Create a dark red to bright red gradient
    vec3 color = vec3(redIntensity, 0.1 * redIntensity, 0.1 * redIntensity);
    
    // Add vignette effect (darker around the edges)
    float vignette = 1.0 - length(uv - vec2(0.5, 0.5)) * 1.2;
    vignette = clamp(vignette, 0.0, 1.0);
    color *= vignette;
    
    // Output to screen with full opacity
    fragColor = vec4(color, 1.0);
}