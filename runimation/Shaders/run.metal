#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Forward declarations from warp.metal
struct WarpResult {
    float f;
    float2 q;
    float2 r;
};

WarpResult warp(float2 p, float octaves, float h, float time);

float3 color(float t, float3 a, float3 b, float3 c, float3 d);

// Heart-rate-driven palette: interpolates from cool (rest) to warm (exertion)
float3 runPalette(float t, float energy) {
    // Cool palette (low HR) — blues and teals
    float3 a_cool = float3(0.5, 0.6, 0.7);
    float3 b_cool = float3(0.3, 0.3, 0.4);
    float3 c_cool = float3(1.0, 1.0, 1.0);
    float3 d_cool = float3(0.0, 0.25, 0.5);

    // Warm palette (high HR) — reds and golds
    float3 a_warm = float3(0.8, 0.5, 0.4);
    float3 b_warm = float3(0.3, 0.4, 0.2);
    float3 c_warm = float3(1.0, 1.0, 1.0);
    float3 d_warm = float3(0.0, 0.10, 0.20);

    // Blend palette coefficients based on energy (heart rate)
    float3 a = mix(a_cool, a_warm, energy);
    float3 b = mix(b_cool, b_warm, energy);
    float3 c = mix(c_cool, c_warm, energy);
    float3 d = mix(d_cool, d_warm, energy);

    return color(t, a, b, c, d);
}

// Rotation matrix helper
float2x2 runRotate2D(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2x2(c, -s, s, c);
}

[[ stitchable ]] half4 runShader(
    float2 position,
    half4 currentColor,
    float time,       // animation elapsed seconds
    float octaves,    // fixed (e.g. 6)
    float h,          // from elevation (inverted: high elevation = low h = rough)
    float scale,      // zoom
    float speed,      // 0..1 normalized speed
    float heartRate,  // 0..1 normalized heart rate
    float dirX,       // -1..1 run direction X (East+, West-)
    float dirY,       // -1..1 run direction Y (North+, South-)
    float offsetX,    // pan/zoom offset in noise space
    float offsetY     // pan/zoom offset in noise space
)
{
    float2 uv = position * scale + float2(offsetX, offsetY);

    // === ANIMATION ===
    // 1. Slow domain rotation — makes the entire pattern swirl visibly
    //    Speed controls rotation rate: faster running = faster rotation
    float rotRate = 0.06 + speed;
    uv = runRotate2D(time * rotRate) * uv;

    // 2. Multi-frequency organic drift (like the complexAnimationShader)
    //    with directional bias from running direction
    float2 runDir = float2(dirX, dirY);
    float2 drift = float2(
        sin(time * 0.20) * 0.5 + sin(time * 0.07) * 0.25,
        cos(time * 0.25) * 0.4 + cos(time * 0.09) * 0.2
    );
    // Directional push: running direction biases the drift oscillation
    drift += runDir * (0.3 + speed * 0.8) * sin(time * 0.15 + 1.0);
    // Perpendicular oscillation for organic feel
    drift += float2(-runDir.y, runDir.x) * sin(time * 0.3) * 0.2;

    // 3. Breathing H parameter — linked to heart rate
    float breathRate = 0.3 + heartRate * 0.8;
    float breath = sin(time * breathRate) * 0.5 + 0.5;
    float animH = clamp(h + breath * 0.2 - 0.1, 0.0, 1.0);

    // === WARP ===
    WarpResult w = warp(uv + drift, octaves, animH, time);

    float f = w.f * 0.5 + 0.5;
    float2 q = w.q;
    float2 r = w.r;

    // === COLORING ===
    // Base color from warp magnitude, palette driven by heart rate
    float warpMag = clamp(length(q) * 0.5 + length(r) * 0.3, 0.0, 1.0);
    float3 c = runPalette(warpMag, heartRate);

    // Highlights — shift from cool white to warm orange with HR
    float rStrength = clamp(dot(r, r) * (0.2 + heartRate * 0.3), 0.0, 1.0);
    float3 highlight = mix(float3(0.9, 0.95, 1.0), float3(1.0, 0.85, 0.7), heartRate);
    c = mix(c, highlight, rStrength);

    // Edge highlighting — intensity responds to speed
    float edges = smoothstep(0.8, 1.2, abs(r.x) + abs(r.y));
    float3 edgeColor = mix(float3(0.1, 0.4, 0.5), float3(0.5, 0.2, 0.1), heartRate);
    c = mix(c, edgeColor, edges * (0.2 + speed * 0.2));

    // Texture detail
    c *= 0.7 + 0.3 * f;

    // Subtle global brightness pulse
    c += sin(time * breathRate * 0.5) * 0.04;

    return half4(half3(clamp(c, 0.0, 1.0)), 1.0);
}
