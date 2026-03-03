#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Forward declarations from other .metal files
struct WarpResult {
    float f;
    float2 q;
    float2 r;
};

float fbm(float2 position, float octaves, float h);
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

    float3 a = mix(a_cool, a_warm, energy);
    float3 b = mix(b_cool, b_warm, energy);
    float3 c = mix(c_cool, c_warm, energy);
    float3 d = mix(d_cool, d_warm, energy);

    return color(t, a, b, c, d);
}

// Domain warp driven by pace-weighted time + running direction.
//
// animTime: pace-weighted time — advances faster when the runner pushes hard.
// flowDir:  speed-weighted direction vector. Magnitude ≈ 0 at rest, ≈ 1 at max pace.
//
// The coordinate space (p) is never transformed — no translation, no stretch.
// Direction works by amplifying the component of the first warp displacement (q)
// that already happens to point in the running direction. This makes the second
// warp layer sample from more displaced positions in that direction, producing
// stronger distortion there while leaving the natural flow completely intact.
WarpResult runWarp(float2 p, float octaves, float h, float animTime, float2 flowDir) {

    // First warp layer — Inigo's opposing time signs for organic, non-repeating swirl.
    float2 q = float2(
        fbm(p + float2(0.7, 2.1) + animTime * 0.04,  octaves, h),
        fbm(p + float2(5.2, 1.3) - animTime * 0.04,  octaves, h)
    );

    // Directional distortion amplification.
    // Project q onto the running direction and boost that component.
    // Where the warp already wants to push in the running direction it pushes harder;
    // perpendicular displacement is completely unchanged.
    float mag = length(flowDir);
    if (mag > 0.05) {
        float2 rDir = flowDir / mag;
        q += rDir * dot(q, rDir) * mag * 0.7;
    }

    // Second warp layer — uses the (possibly boosted) q.
    // 1.26× ratio on the opposing sign breaks symmetry (from lsl3RH).
    float2 r = float2(
        fbm(p + 4.0*q + float2(1.7, 9.2) + animTime * 0.06,   octaves, h),
        fbm(p + 4.0*q + float2(8.3, 2.8) - animTime * 0.0756, octaves, h)
    );

    float f = fbm(p + 4.0*r, octaves, h);

    WarpResult result;
    result.f = f;
    result.q = q;
    result.r = r;
    return result;
}

[[ stitchable ]] half4 runShader(
    float2 position,
    half4 currentColor,
    float time,       // pace-weighted animation time from PlaybackEngine.animationTime
    float octaves,
    float h,          // from elevation (inverted: high elevation → lower h → rougher)
    float scale,      // zoom level
    float speed,      // 0..1 normalized speed
    float heartRate,  // 0..1 normalized heart rate
    float dirX,       // speed-weighted direction X (East+, West-)
    float dirY,       // speed-weighted direction Y (North+, South-)
    float offsetX,    // noise-space pan offset
    float offsetY
)
{
    float2 uv = position * scale + float2(offsetX, offsetY);

    // === ANIMATION ===

    // Breathing H: HR drives frequency, elevation drives base value via `h`.
    float breathRate = 0.3 + heartRate * 0.8;
    float breath = sin(time * breathRate) * 0.5 + 0.5;
    float animH = clamp(h + breath * 0.2 - 0.1, 0.0, 1.0);

    // flowDir is already speed-weighted from RunData: near-zero at rest,
    // ~unit vector at max running pace. No additional scaling needed.
    float2 flowDir = float2(dirX, dirY);

    // === WARP ===
    WarpResult w = runWarp(uv, octaves, animH, time, flowDir);

    float f = w.f * 0.5 + 0.5;
    float2 q = w.q;
    float2 r = w.r;

    // === COLORING ===
    float warpMag = clamp(length(q) * 0.5 + length(r) * 0.3, 0.0, 1.0);
    float3 c = runPalette(warpMag, heartRate);

    float rStrength = clamp(dot(r, r) * (0.2 + heartRate * 0.3), 0.0, 1.0);
    float3 highlight = mix(float3(0.9, 0.95, 1.0), float3(1.0, 0.85, 0.7), heartRate);
    c = mix(c, highlight, rStrength);

    float edges = smoothstep(0.8, 1.2, abs(r.x) + abs(r.y));
    float3 edgeColor = mix(float3(0.1, 0.4, 0.5), float3(0.5, 0.2, 0.1), heartRate);
    c = mix(c, edgeColor, edges * (0.2 + speed * 0.2));

    c *= 0.7 + 0.3 * f;
    c += sin(time * breathRate * 0.5) * 0.04;

    return half4(half3(clamp(c, 0.0, 1.0)), 1.0);
}
