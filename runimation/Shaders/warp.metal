#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

struct WarpResult {
    float f;
    float2 q;
    float2 r;
};

float fbm(float2 position, float octaves, float h);

float3 fbmd(float2 position, float octaves, float h);

float3 color(float t, float3 a, float3 b, float3 c, float3 d)
{
    return a + b * cos(6.283185 * (c * t + d));
}

float3 palette1(float t)
{
    float3 a = float3(0.8, 0.5, 0.4);
    float3 b = float3(0.2, 0.4, 0.2);
    float3 c = float3(1.0, 1.0, 1.0);
    float3 d = float3(0.0, 0.15, 0.20);

    return color(t, a, b, c, d);
}

WarpResult warp(float2 p, float octaves, float h)
{
    float2 q = float2(
                      fbm(p + float2(0.0, 0.0), octaves, h),
                      fbm(p + float2(5.2,1.3), octaves, h)
                      );
    
    float2 r = float2(
                      fbm(p + 4.0 * q + float2(1.7, 9.2), octaves, h),
                      fbm(p + 4.0 * q + float2(8.3, 2.8), octaves, h)
                      );
    
    float f = fbm(p + 4.0 * r, octaves, h);
    
    WarpResult result;
    result.f = f;
    result.q = q;
    result.r = r;
    return result;
}

[[ stitchable ]] half4 warpShader(
                                  float2 position,
                                  half4 color,
                                  float time,
                                  float octaves,
                                  float h,
                                  float scale
                                  )
{
    // Normalize position to a reasonable scale
    float2 uv = position * scale;
    WarpResult w = warp(uv, octaves, h);

    float f = clamp(w.f * 0.5 + 0.5, 0.0, 1.0);
    float2 q = w.q;
    float2 r = w.r;

    // Base color from warp amount
    float warpMag = clamp(length(q) * 0.5 + length(r) * 0.3, 0.0, 1.0);
    float3 c = palette1(warpMag);
    
    // Mix in white where second warp is strong (like his dot(n,n))
    float rS = clamp(dot(r, r) * 0.2, 0.0, 1.0);
    c = mix(c, float3(0.9, 0.95, 1.0), rS);
    
    // Add edge highlighting
    float edges = smoothstep(0.8, 1.2, abs(r.x) + abs(r.y));
    c = mix(c, float3(0.1, 0.4, 0.5), edges * 0.3);
    
    // Textrue details
    c *= 0.7 + 0.3 * f;
    
    return half4(half3(c), 1.0);
}
