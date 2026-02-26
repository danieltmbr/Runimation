# MANDATORY RULES

- **Never implement a suggestion you have doubts about.** If something seems unclear, suboptimal, or you have an alternative in mind — stop, ask questions, and discuss it first. Do not change any code until the approach is agreed upon.
- It is always better to disagree and ask than to silently implement something on assumptions.

# Runimation

## Project Overview
An interactive SwiftUI + Metal shader app implementing Inigo Quilez's **domain warping** technique. The long-term goal is to feed **Strava GPX run data** into animation parameters to create fluid, organic visuals that respond to running data.

## Tech Stack
- **Language:** Swift 5.0
- **UI:** SwiftUI
- **GPU:** Metal shaders via `[[ stitchable ]]` fragment functions + `.colorEffect()` modifier
- **Build:** Xcode 16+ (no SPM, no external dependencies)
- **Targets:** iOS/iPadOS/macOS 26.2

## Key Concepts Implemented
- **Value noise** with quintic polynomial smoothing (C² continuity at cell boundaries)
- **Analytical derivatives** via chain rule (noised returns `float3(value, dx, dy)`)
- **fBM** with configurable octaves and H (roughness) parameter, rotation matrix between octaves to break grid alignment
- **Domain warping** — two layers of fBM displacement creating fluid-like visuals
- **Cosine color palettes** (Inigo's `a + b * cos(2π(c*t + d))` technique)
- **Warp-magnitude coloring** — color driven by displacement amount, with Manhattan distance edge detection

## Roadmap

### Warp fine tuning
1. **Inigo's organic animation** — opposing time directions for inner/outer warps, position-dependent ripples (`sin(freq * time + length(q) * 4.0)`)
2. **Detuned fBM** with rotation matrix between octaves (2.02x frequency instead of 2.0x)
3. **Inigo's lighting approach** — finite difference normals, Laplacian edge detection, diffuse + ambient lighting

### Strava GPX Integration
Map run data to shader parameters:
- **Speed** → warp strength / turbulence
- **Elevation change** → H parameter (roughness)
- **Direction changes** → rotation/offset of noise domain
- **Distance along route** → time/animation offset

### Image processing
Allow to get a photo from library and extract main color components that will color the warping.

## Coding Conventions

- **Break complex functions into smaller, named helpers.** Each function should have a single clear responsibility. If a function needs a comment to explain a section, that section is a candidate for its own private helper.

## Key References
- [Domain Warping](https://iquilezles.org/articles/warp/)
- [fBM](https://iquilezles.org/articles/fbm/)
- [Noise Derivatives](https://iquilezles.org/articles/morenoise/)
- [Color Palettes](https://iquilezles.org/articles/palettes/)
- [Shadertoy: Warp (4s23zz)](https://www.shadertoy.com/view/4s23zz)
- [Shadertoy: Animated Warp (lsl3RH)](https://www.shadertoy.com/view/lsl3RH)
