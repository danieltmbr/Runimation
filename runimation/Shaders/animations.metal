#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Forward declarations
struct WarpResult {
    float f;
    float2 q;
    float2 r;
};

WarpResult warp(float2 p, float octaves, float h, float time);

float3 palette1(float t);

// Rotation matrix helper
float2x2 rotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2x2(c, -s, s, c);
}

// ANIMATION TECHNIQUE 1: Circular Camera Motion
// Instead of linear sliding, orbit around a center point
[[ stitchable ]] half4 orbitalAnimationShader(
                                              float2 position,
                                              half4 color,
                                              float time,
                                              float octaves,
                                              float h,
                                              float scale
                                              )
{
    float2 uv = position * scale;
    
    // Circular motion instead of linear
    float angle = time * 0.3;
    float radius = 0.5;
    float2 offset = float2(cos(angle), sin(angle)) * radius;
    
    WarpResult w = warp(uv + offset, octaves, h, time);
    
    // Standard coloring
    float warpMag = clamp(length(w.q) * 0.5 + length(w.r) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    float r_strength = clamp(dot(w.r, w.r) * 0.4, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), r_strength);
    
    float edges = smoothstep(0.8, 1.2, abs(w.r.x) + abs(w.r.y));
    c = mix(c, float3(0.4, 0.1, 0.15), edges * 0.3);
    
    float detail = w.f * 0.5 + 0.5;
    c *= 0.8 + 0.2 * detail;
    
    return half4(half3(c), 1.0);
}

// ANIMATION TECHNIQUE 2: Breathing/Pulsing
// Animate the H parameter and scale to create "breathing" effect
[[ stitchable ]] half4 breathingAnimationShader(
                                                float2 position,
                                                half4 color,
                                                float time,
                                                float octaves,
                                                float h,
                                                float scale
                                                )
{
    float2 uv = position * scale;
    
    // Pulsing parameters
    float breath = sin(time * 0.2) * 0.5 + 0.5;  // 0 to 1
    float animatedH = h + breath * 0.3 - 0.15;   // oscillate ±0.15
    animatedH = clamp(animatedH, 0.0, 1.0);
    
    // Also pulse the scale slightly
    // float scaleBreath = 1.0 + sin(time * 0.3) * 0.02;  // 0.9 to 1.1
    
    WarpResult w = warp(uv, octaves, animatedH, time);
    
    // Standard coloring
    float warpMag = clamp(length(w.q) * 0.5 + breath * 0.2 + length(w.r + breath * 0.2) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    float r_strength = clamp(dot(w.r, w.r) * 0.4 + breath * 0.2, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), r_strength);
    
    float edges = smoothstep(0.8, 1.2, abs(w.r.x) + abs(w.r.y));
    c = mix(c, float3(0.4, 0.1, 0.15), edges * 0.3);
    
    float detail = w.f * 0.5 + 0.5;
    c *= 0.8 + 0.2 * detail;
    
    return half4(half3(c), 1.0);
}

// ANIMATION TECHNIQUE 3: Flowing/Drifting
// Non-linear movement with varying speeds in different directions
[[ stitchable ]] half4 flowingAnimationShader(
                                              float2 position,
                                              half4 color,
                                              float time,
                                              float octaves,
                                              float h,
                                              float scale
                                              )
{
    float2 uv = position * scale;
    
    // Non-linear drift using different frequencies
    float2 drift = float2(
                          sin(time * 0.13) * 0.5,
                          cos(time * 0.17) * 0.3
                          );
    
    // Add slower large-scale movement
    drift += float2(
                    sin(time * 0.05) * 0.2,
                    cos(time * 0.07) * 0.15
                    );
    
    WarpResult w = warp(uv + drift, octaves, h, time);
    
    // Standard coloring
    float warpMag = clamp(length(w.q) * 0.5 + length(w.r) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    float r_strength = clamp(dot(w.r, w.r) * 0.4, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), r_strength);
    
    float edges = smoothstep(0.8, 1.2, abs(w.r.x) + abs(w.r.y));
    c = mix(c, float3(0.4, 0.1, 0.15), edges * 0.3);
    
    float detail = w.f * 0.5 + 0.5;
    c *= 0.8 + 0.2 * detail;
    
    return half4(half3(c), 1.0);
}

// ANIMATION TECHNIQUE 4: Rotating Domain
// Slowly rotate the entire noise domain
[[ stitchable ]] half4 rotatingAnimationShader(
                                               float2 position,
                                               half4 color,
                                               float time,
                                               float octaves,
                                               float h,
                                               float scale
                                               )
{
    float2 uv = position * scale;
    
    // Rotate the domain slowly
    float angle = time * 0.1;
    float2x2 rotation = rotate2D(angle);
    uv = rotation * uv;
    
    WarpResult w = warp(uv, octaves, h, time);
    
    // Standard coloring
    float warpMag = clamp(length(w.q) * 0.5 + length(w.r) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    float r_strength = clamp(dot(w.r, w.r) * 0.4, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), r_strength);
    
    float edges = smoothstep(0.8, 1.2, abs(w.r.x) + abs(w.r.y));
    c = mix(c, float3(0.4, 0.1, 0.15), edges * 0.3);
    
    float detail = w.f * 0.5 + 0.5;
    c *= 0.8 + 0.2 * detail;
    
    return half4(half3(c), 1.0);
}

// ANIMATION TECHNIQUE 5: Complex Combined
// Combine rotation, drift, and parameter animation for rich motion
[[ stitchable ]] half4 complexAnimationShader(
                                              float2 position,
                                              half4 color,
                                              float time,
                                              float octaves,
                                              float h,
                                              float scale
                                              )
{
    float2 uv = position * scale;
    
    // Slow rotation
    float angle = time * 0.08;
    float2x2 rotation = rotate2D(angle);
    uv = rotation * uv;
    
    // Organic drift
    float2 drift = float2(
                          sin(time * 0.13) * 0.3 + sin(time * 0.05) * 0.15,
                          cos(time * 0.17) * 0.25 + cos(time * 0.07) * 0.1
                          );
    
    // Breathing H parameter
    float breath = sin(time * 0.4) * 0.5 + 0.5;
    float animatedH = h + breath * 0.2 - 0.1;
    animatedH = clamp(animatedH, 0.0, 1.0);
    
    WarpResult w = warp(uv + drift, octaves, animatedH, time);
    
    // Standard coloring
    float warpMag = clamp(length(w.q) * 0.5 + length(w.r) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    float r_strength = clamp(dot(w.r, w.r) * 0.4, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), r_strength);
    
    float edges = smoothstep(0.8, 1.2, abs(w.r.x) + abs(w.r.y));
    c = mix(c, float3(0.4, 0.1, 0.15), edges * 0.3);
    
    float detail = w.f * 0.5 + 0.5;
    c *= 0.8 + 0.2 * detail;
    
    return half4(half3(c), 1.0);
}

// BONUS: Inigo-style with detuned octaves
// This would require modifying your fbm function, but here's the concept:
/*
 float fbmDetuned(float2 p, float octaves, float h) {
 const float2x2 m = float2x2(0.80, 0.60, -0.60, 0.80);  // rotation matrix
 
 float g = exp2(-h);
 float a = 1.0;
 float t = 0.0;
 
 for(int i = 0; i < octaves; i++) {
 float3 n = noised(p);
 t += a * n.x;
 
 // Rotate and detune instead of exact doubling
 p = m * p * 2.02;  // 2.02 instead of 2.0
 a *= g;
 }
 return t;
 }
 */
