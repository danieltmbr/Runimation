# MANDATORY RULES

- **Never implement a suggestion you have doubts about.** If something seems unclear, suboptimal, or you have an alternative in mind — stop, ask questions, and discuss it first. Do not change any code until the approach is agreed upon.
- It is always better to disagree and ask than to silently implement something on assumptions.

# Runimation

## Coding Conventions

- **Break complex functions into smaller, named helpers.** Each function should have a single clear responsibility. If a function needs a comment to explain a section, that section is a candidate for its own private helper.
- **Think systematically in small composable bits of implementations.** When you find yourself implementing repeating patterns, make them a composable component instead of a private method burried deep inside a feature. This is true for UI as well as functional components like the `RunTransformer`.
- **Don't fight the system, follow its conventions.** 
    - For UI follow Apple's SwiftUI conventions.
        - Inject data/binding thorugh the intialiser (or complex view models via Environment).
        - Inject sytling or layout specific customisations via view modifiers.
    - For others follow Apple Foundation conventions. For example don't declare new formatting interface, implement a FormatStyle if possible. 
- **Identify components based on functionality rahter than look.** Functionally identical views that have different layouts can be implemented with a shared view API but different layout style implementation. Just like how SwiftUI Picker has so many different style implementation: https://developer.apple.com/documentation/swiftui/pickerstyle Read thorugh `/.claude/docs/SwiftUI-Architecture-Proposal.pdf` and `/.claude/docs/SwiftUI-Architecture-CaseStudy.pdf` to see how to implement them.  
- **Add header comments** to implementations. Especially to reusable components.
- **Read documentations.** When learning about new APIs or design, the main source of information should be the official documentation.

## Project Overview
The main purpose of this project is simply to learn computer graphics programming in Metal in a fun way.
Learning mainly happens by implementing shader techniques from Inigo Quilez's site. 
To make it even more personal I use Strava GPX run data to feed into animation parameters to create fluid, organic visuals that respond to running metrics.

## Tech Stack
- **Language:** Swift 5.0
- **UI:** SwiftUI
- **GPU:** Metal shaders via `[[ stitchable ]]` fragment functions + `.colorEffect()` modifier
- **Build:** Xcode 16+ (no SPM, no external dependencies)
- **Targets:** iOS/iPadOS/macOS 26.2

## Key References
- [Inigo Quilez's site](https://iquilezles.org/)
- [Domain Warping](https://iquilezles.org/articles/warp/)
- [fBM](https://iquilezles.org/articles/fbm/)
- [Noise Derivatives](https://iquilezles.org/articles/morenoise/)
- [Color Palettes](https://iquilezles.org/articles/palettes/)
- [Shadertoy: Warp (4s23zz)](https://www.shadertoy.com/view/4s23zz)
- [Shadertoy: Animated Warp (lsl3RH)](https://www.shadertoy.com/view/lsl3RH)
