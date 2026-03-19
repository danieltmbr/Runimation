#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

float noise_hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

[[ stitchable ]] half4 gradientShader(
                                      float2 position,
                                      half4 currentColor,
                                      float time,
                                      float2 size,
                                      float scale,
                                      float2 offset
                                      ) {
    float2 uv = float2(position.x/size.x, -position.y/size.y);
    
    float3 purple = float3(0.5, 0.2, 0.9);
    float3 yellow = float3(0.9, 0.9, 0.2);
    
    float3 gradient = mix(purple, yellow, uv.x);
    
    return half4(half3(gradient), 1);
}

float expBlob(float2 pos, float2 center, float strength) {
    float2 d = pos - center;
    return exp2(dot(d, d) * -strength);
}

float stepBlob(float2 pos, float2 center, float radius, float softness) {
    float d = length(pos - center);
    return 1 - smoothstep(radius, radius + softness, d);
}

[[ stitchable ]] half4 blobShader(
                                  float2 position,
                                  half4 currentColor,
                                  float time,
                                  float2 size,
                                  float scale,
                                  float2 offset,
                                  float mode,
                                  float saturate,
                                  float light,
                                  float noise
                                  ) {
    float2 uv = float2(position.x/size.x, position.y/size.y);
    float t = time * 0.36;
    
    float3 red = float3(1.0, 0.1, 0.23);
    float3 purple = float3(0.5, 0.2, 0.95);
    float3 yellow = float3(0.9, 0.9, 0.2);
    float3 pink = float3(1.0, 0.2, 0.65);
    
    float2 p1 = float2(0.20 + 0.15 * sin(t * 1.1 + 3411), 0.25 + 0.09 * cos(t * 1.3 + 324));
    float2 p2 = float2(0.55 + 0.08 * sin(t * 0.9 + 5234), 0.30 + 0.13 * cos(t * 0.6 + 635));
    float2 p3 = float2(0.75 + 0.02 * sin(t * 1.2 + 6543), 0.75 + 0.06 * cos(t * 0.8 + 123));
    float2 p4 = float2(0.30 + 0.10 * sin(t * 0.7 + 987),  0.80 + 0.16 * cos(t * 1.1 + 547));
    
    float b1 = 0;
    float b2 = 0;
    float b3 = 0;
    float b4 = 0;
    
    if (mode == 0) {
        b1 = stepBlob(uv, p1, 0.35 + 0.02 * sin(t * 1.2 + 6543), 0.25 + 0.10 * sin(t * 0.7 + 987));
        b2 = stepBlob(uv, p2, 0.40 + 0.08 * sin(t * 0.9 + 5234), 0.30 + 0.16 * cos(t * 1.1 + 547));
        b3 = stepBlob(uv, p3, 0.45 + 0.06 * cos(t * 0.8 + 123), 0.35 + 0.13 * cos(t * 0.6 + 635));
        b4 = stepBlob(uv, p4, 0.30 + 0.13 * cos(t * 0.6 + 635), 0.25 + 0.15 * sin(t * 1.1 + 3411));
    } else {
        b1 = pow(expBlob(uv, p1, 12 + 3 * sin(t * 1.2 + 6543)), 2.0);
        b2 = pow(expBlob(uv, p2, 15 + cos(t * 1.1 + 547)), 2.0);
        b3 = pow(expBlob(uv, p3, 10 + 4 * cos(t * 0.8 + 123)), 2.0);
        b4 = pow(expBlob(uv, p4, 9 + 2 * sin(t * 1.1 + 3411)), 2.0);
    }

    float total = b1 + b2 + b3 + b4;
    float3 color = (b3*red + b2*purple + b1*yellow + b4*pink) / total;
    
    if (saturate) {
        float luminance = dot(color, float3(0.299, 0.587, 0.114));
        color = mix(float3(luminance), color, 1.25);
    }
    
    if (light) {
        float2 lightPos = float2(0.35, 0.25);
        float highlight = 1.0 - smoothstep(0.0, 0.45, distance(uv, lightPos));
        color += 0.18 * highlight;
        
        float2 p = uv - float2(0.38, 0.22);
        p.x *= 2.5;
        float streak = 1.0 - smoothstep(0.0, 0.18, length(p));
        color += 0.12 * streak;
        
        color = mix(color, float3(1.0), 0.10);
        
        float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
        float rim = 1.0 - smoothstep(0.0, 0.08, edge);
        color += 0.08 * rim;
    }
    
    if (noise) {
        float n = noise_hash(uv) - 0.5;
        color += n * 0.025;
    }
    
    return half4(half3(color), 1.0);
}
