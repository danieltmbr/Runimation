#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Linear interpolation
float3 lerp(float t, float3 a, float3 b) {
    return a + t * (b - a);
}

// Quintic polynomial for smooth interpolation
float quintic(float x) {
    return x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// Hash function to generate pseudo-random values from grid coordinates
// This gives us consistent "random" values for each lattice point
float hash(float2 p) {
    float h = dot(p, float2(127.1, 311.7));
    return fract(sin(h) * 43758.5453123);
}

// Get a random color (float3) for a lattice point
float3 getLatticeColor(int2 gridPos) {
    // Generate 3 different random values for R, G, B
    float r = hash(float2(gridPos));
    float g = hash(float2(gridPos) + float2(1.0, 0.0));
    float b = hash(float2(gridPos) + float2(0.0, 1.0));
    return float3(r, g, b);
}

// 2D noise function
// useSmooth: true = quintic polynomial, false = linear
float3 noise2D(float2 position, bool useSmooth) {
    // Find which grid cell we're in
    int2 gridPos = int2(floor(position));
    
    // Get fractional part (where we are inside the cell)
    float2 fractional = fract(position);
    
    // Apply interpolation curve
    float2 interp = useSmooth ? float2(quintic(fractional.x), quintic(fractional.y)) : fractional;
    
    // Get the 4 corner colors of our grid cell
    float3 a = getLatticeColor(gridPos + int2(0, 0));
    float3 b = getLatticeColor(gridPos + int2(1, 0));
    float3 c = getLatticeColor(gridPos + int2(0, 1));
    float3 d = getLatticeColor(gridPos + int2(1, 1));
    
    // Bilinear interpolation
    // First interpolate along X axis
    float3 bottom = lerp(interp.x, a, b);
    float3 top = lerp(interp.x, c, d);
    
    // Then interpolate along Y axis
    float3 result = lerp(interp.y, bottom, top);
    
    return result;
}

[[ stitchable ]] half4 noiseShader(
                                   float2 position,
                                   half4 color,
                                   float time,
                                   float scale,
                                   float interpolationMode  // 0.0 = linear, 1.0 = smooth
                                   ) {
    // Transform to centered coordinate system (-5 to 5)
    float2 uv = position / scale;  // Normalize by a reference size
    uv -= 2.5;  // Center around (0, 0)
    
    // Determine which interpolation mode to use
    bool useSmooth = interpolationMode > 0.5;
    
    // Get noise color
    float3 col = noise2D(uv, useSmooth);
    
    // Visualize lattice points
    float2 latticePoint = round(uv); // nearest integer coordinate
    float distToLattice = length(uv - latticePoint); // distance to that point
    
    // Draw a circle with radius 0.1 (adjust to taste)
    if (distToLattice < 0.05) {
        col = float3(1.0, 0.0, 0.0);
    }
    
    return half4(half3(col), 1.0);
}

float3 noised(float2 position) {
    // Find which grid cell we're in
    float2 p = floor(position);
    // Get fractional part (where we are inside the cell)
    float2 f = fract(position);
    
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);
    
    // Get the 4 corner values of our grid cell
    float a = hash(p + float2(0, 0));
    float b = hash(p + float2(1, 0));
    float c = hash(p + float2(0, 1));
    float d = hash(p + float2(1, 1));
    
    // Bilinear interpolation: a + t * (b - a);
    // lerp(y, lerp(x, a, b), lerp(x, c, d))
    // • a + xb - xa
    // • c + xc - xd
    // lerp(y, [a + xb - xa], [c + xc - xd])
    // • (a + xb - xa) + y([c + xd - xc] - [a + xb - xa])
    // • a + xb -xa + yc + xyd - xyc - ya - xyb + xya
    // • a + x(b-a) + y(c-a) + xy(a+c-d-b)
    
    float k0 = a;
    float k1 = b-a;
    float k2 = c-a;
    float k3 = a-b-c+d;
    
    return float3(
                  // The interpolated noise value
                  -1.0 + 2.0 * (k0 + u.x * k1 + u.y * k2 + u.x * u.y * k3),
                  // Derivative for X axis
                  2.0 * du.x * (k1 + k3 * u.y),
                  // Derivative for Y axis
                  2.0 * du.y * (k2 + k3 * u.x)
                  );
}
