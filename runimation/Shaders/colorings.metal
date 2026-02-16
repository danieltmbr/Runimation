#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Forward declaration
float3 noised(float2 position);

float fbm(float2 position, float octaves, float h);

float3 fbmd(float2 position, float octaves, float h);

// Color palette function from Inigo's article
// https://iquilezles.org/articles/palettes/
float3 palette(float t, float3 a, float3 b, float3 c, float3 d)
{
    return a + b * cos(6.28318 * (c * t + d));
}

// Ice palette preset
float3 icePalette(float t)
{
    float3 a = float3(0.5, 0.5, 0.5);
    float3 b = float3(0.5, 0.5, 0.5);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.0, 0.33, 0.67);
    return palette(t, a, b, c, d);
}

// Cyan/white palette
float3 cyanPalette(float t)
{
    float3 a = float3(0.5, 0.7, 0.8);
    float3 b = float3(0.3, 0.4, 0.5);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.0, 0.25, 0.5);
    return palette(t, a, b, c, d);
}

// Warm palette for contrast
float3 warmPalette(float t)
{
    float3 a = float3(0.8, 0.5, 0.4);
    float3 b = float3(0.2, 0.4, 0.2);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.0, 0.15, 0.20);
    return palette(t, a, b, c, d);
}

float3 customPalette(float t)
{
    float3 a = float3(0.725, 0.042, 0.422);
    float3 b = float3(0.613, 0.993, 0.521);
    float3 c = float3(0.774, 0.756, 0.143);
    float3 d = float3(5.663, 2.549, 2.688);
    
    return palette(t, a, b, c, d);
}

// TECHNIQUE 1: Color based on derivatives
[[ stitchable ]] half4 derivativeColorShader(
                                             float2 position,
                                             half4 color,
                                             float time,
                                             float octaves,
                                             float h,
                                             float scale
                                             ) {
    float2 uv = position * scale;
    
    // Get fbm with derivatives
    float3 result = fbmd(uv, octaves, h);
    float value = result.x;
    float2 derivatives = result.yz;
    
    // Gradient strength (how fast the noise is changing)
    float gradientStrength = length(derivatives);
    
    // Map to [0, 1] for coloring
    value = value * 0.5 + 0.5;
    gradientStrength = clamp(gradientStrength * 0.5, 0.0, 1.0);
    
    // Base color from value
    float3 baseColor = icePalette(value);
    
    // Modulate by gradient strength to highlight edges/details
    float3 finalColor = baseColor * (0.6 + 0.4 * gradientStrength);
    
    return half4(half3(finalColor), 1.0);
}

// TECHNIQUE 2: Multiple layers with different palettes
[[ stitchable ]] half4 multiLayerColorShader(
                                             float2 position,
                                             half4 color,
                                             float time,
                                             float octaves,
                                             float h,
                                             float scale
                                             ) {
    float2 uv = position * scale;
    
    // First layer - larger features
    float pattern1 = fbm(uv, octaves, h);
    
    // Second layer - offset and different scale
    float pattern2 = fbm(uv * 1.5 + float2(5.2, 1.3), max(1.0, octaves - 2.0), h);
    
    // Map to [0, 1]
    pattern1 = pattern1 * 0.5 + 0.5;
    pattern2 = pattern2 * 0.5 + 0.5;
    
    // Two different color palettes
    float3 color1 = icePalette(pattern1);
    float3 color2 = cyanPalette(pattern2);
    
    // Blend based on first pattern
    float3 finalColor = mix(color1, color2, pattern1 * 0.6);
    
    return half4(half3(finalColor), 1.0);
}

// TECHNIQUE 3: Color based on warping amount
[[ stitchable ]] half4 warpColorShader(
                                       float2 position,
                                       half4 color,
                                       float time,
                                       float octaves,
                                       float h,
                                       float scale
                                       ) {
    float2 p = position * scale;
    
    // First warp
    float2 q = float2(
                      fbm(p, octaves, h),
                      fbm(p + float2(5.2, 1.3), octaves, h)
                      );
    
    // Second warp (warp the warp!)
    float2 r = float2(
                      fbm(p + 4.0 * q + float2(1.7, 9.2), octaves, h),
                      fbm(p + 4.0 * q + float2(8.3, 2.8), octaves, h)
                      );
    
    // Color based on warping amount
    float warpAmount = length(q) * 0.5 + length(r) * 0.3;
    warpAmount = clamp(warpAmount, 0.0, 1.0);
    
    // Get base color from warp amount
    float3 baseColor = icePalette(warpAmount);
    
    // Add fine detail texture
    float detail = fbm(p + r, min(octaves + 2.0, 12.0), min(h + 0.1, 1.0));
    detail = detail * 0.5 + 0.5;
    
    // Modulate color with detail
    float3 finalColor = baseColor * (0.7 + 0.3 * detail);
    
    return half4(half3(finalColor), 1.0);
}

// BONUS: Animated version (for Strava visualization)
[[ stitchable ]] half4 animatedWarpShader(
                                          float2 position,
                                          half4 color,
                                          float time,
                                          float octaves,
                                          float h,
                                          float scale
                                          ) {
    float2 p = position * scale;
    
    // Animate by offsetting the noise domain over time
    float2 timeOffset = float2(time * 0.1, time * 0.15);
    
    // Warping with animation
    float2 q = float2(
                      fbm(p + timeOffset, octaves, h),
                      fbm(p + timeOffset + float2(5.2, 1.3), octaves, h)
                      );
    
    float2 r = float2(
                      fbm(p + 4.0 * q + timeOffset * 0.5, octaves, h),
                      fbm(p + 4.0 * q + timeOffset * 0.5 + float2(1.7, 9.2), octaves, h)
                      );
    
    float warpAmount = length(q) * 0.5 + length(r) * 0.3;
    warpAmount = clamp(warpAmount, 0.0, 1.0);
    
    float3 finalColor = icePalette(warpAmount);
    
    return half4(half3(finalColor), 1.0);
}
