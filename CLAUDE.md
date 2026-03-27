# MANDATORY RULES

- **Never implement a suggestion you have doubts about.** If something seems unclear, suboptimal, or you have an alternative in mind — stop, ask questions, and discuss it first. Do not change any code until the approach is agreed upon.
- It is always better to disagree and ask than to silently implement something on assumptions.
- **Planning is a discussion**: Don't start to write a full plan and burn tokens without first having a few back and forth discussion to understand each other better. Especially when you see my prompts have doubts, uncertainties or questions in them. First discuss them by providing several options to those unpolished ideas.

# Runimation

## Coding Conventions

- **Break complex functions into smaller, named helpers.** Each function should have a single clear responsibility. If a function needs a comment to explain a section, that section is a candidate for its own private helper.
- **Never write free-standing global functions as helpers.** All helper functions belong inside the type they serve as `private` (or `private extension`) members. A global free function is only appropriate when it genuinely belongs to no type (which is rare).
- **Avoid enums for namespace or for complex entities.** Don't create enums with no cases and only static methods. That is probably an entity for a specific purpose that will be injected into another object as a dependency. Every dependency should have a well defined responsibility / functionality and implemented accordingly as a struct / actor / class. Also an enum with several cases and computed properties that depend on the enum case itself, should probably be a Struct instead with all the properties stored and perhaps a `Kind`/`Style`/`Type` enum that is just another property of the struct.
- **Think systematically in small composable bits of implementations.** When you find yourself implementing repeating patterns, make them a composable component instead of a private method burried deep inside a feature. This is true for UI as well as functional components like the `RunTransformer`.
- **Don't fight the system, follow its conventions.**
    - For UI follow Apple's SwiftUI conventions.
        - Inject data/binding thorugh the intialiser (or complex view models via Environment).
        - Inject sytling or layout specific customisations via view modifiers.
        - **Communicate between views via state bindings, never via callback closures.** Closures in an initialiser (`onRunLoaded: () -> Void`, `onShowStats: (Entry) -> Void`) are UIKit-style event delegation — they break the declarative model and tie the child to the parent's internal logic. Instead, expose a `@Binding` for state the parent owns and the child mutates (e.g. `isPresented: Bool`), and use `NavigationLink(value:)` with `.navigationDestination` for navigation. The only acceptable callbacks in a SwiftUI view initialiser are completion handlers on transient *control* views (e.g. `onPlayed` on `PlayRunButton`) that signal a momentary event with no associated state to share.
    - For others follow Apple Foundation conventions. For example don't declare new formatting interface, implement a FormatStyle if possible. 
- **Identify components based on functionality rahter than look.** Functionally identical views that have different layouts can be implemented with a shared view API but different layout style implementation. Just like how SwiftUI Picker has so many different style implementation: https://developer.apple.com/documentation/swiftui/pickerstyle Read thorugh `/.claude/docs/SwiftUI-Architecture-Proposal.pdf` and `/.claude/docs/SwiftUI-Architecture-CaseStudy.pdf` to see how to implement them.
- **Reusable views with non-trivial layout must use the Style protocol pattern.** If a view is intended to be reused and has more than a single-element layout, do not put the layout directly in `body`. Instead define a `[Name]Style` protocol with a `[Name]StyleConfiguration` and a `makeBody(configuration:)` method, then implement concrete styles as separate types. The view itself only reads state and forwards a configuration to the active style. Existing examples in the codebase: `PlaybackControlsStyle`, `RunInfoViewStyle`, `ProgressSliderStyle`. If you are about to implement a reusable view and have not yet defined its `Style` protocol, stop and define it first.

  The five concrete rules for every implementation — violating any one of these is wrong:
  1. **API is a thin pass-through.** `ProgressSlider`, `RunInfoView` etc. own no interaction state. Their `body` is a single line: `style.makeBody(configuration: configuration)`. All they do is read environment/player state and build the configuration.
  2. **`makeBody` delegates to a private View.** Never put layout inline in `makeBody`. It must construct and return a `private struct [Name]View: View` that lives in the same file. That private View is where `@State`, `@Environment`, layout, and gestures live.
  3. **Interaction state lives in the private View, not the API.** `@State var isDragging`, `@State var localValue` etc. belong in the style's private View implementation. Use `@State` + `.onChange` — never callback closures (`onDragBegan`, `onDragChanged`) which are UIKit-style event handling and fight SwiftUI's declarative model.
  4. **Configuration contains only data.** A binding for the value the style reads/writes, and action closures (`seek`, `toggle`) for side effects. No drag lifecycle callbacks. No state. No view logic.
  5. **Styles have no `public init()`.** They are only reachable through the static protocol accessors (e.g. `.system`, `.minimal`). This keeps instantiation controlled and the API clean.
- **Actions are thin, single-responsibility wrappers over model functionality.** Each `Action` struct captures exactly one operation from the model layer (e.g. `DeleteRunAction` wraps `library.delete(_:)`). They have a single stored closure, a designated init that takes that closure, and convenience inits for the default no-op and the library-bound real implementation. Actions must not orchestrate multiple model calls, hold multiple dependencies, or contain business logic — that is what control views are for.
- **Control views compose features from individual actions.** When a UI gesture requires coordinating multiple actions or model calls (e.g. save config → load run → set player → restore config → mark playing), implement a dedicated control view (e.g. `PlayRunButton`) that reads all needed environment values and orchestrates the flow internally. This keeps individual actions clean and makes the composition explicit at the view layer.
- **Add header comments** to implementations. Especially to reusable components.
- **Read documentations.** When learning about new APIs or design, the main source of information should be the official documentation.
- **Always read a file in full before modifying it.** Do not rely on memory or earlier reads from the same session — re-read immediately before every edit. Skipping this step causes incorrect edits and wastes time.


## Project Overview
The main purpose of this project is simply to learn computer graphics programming in Metal in a fun way.
Learning mainly happens by implementing shader techniques from Inigo Quilez's site. 
To make it even more personal I use Strava GPX run data to feed into animation parameters to create fluid, organic visuals that respond to running metrics.

## Tech Stack
- **Language:** Swift 6.0
- **UI:** SwiftUI
- **GPU:** Metal shaders via `[[ stitchable ]]` fragment functions + `.colorEffect()` modifier
- **Build:** Xcode 26+ (no SPM, no external dependencies)
- **Targets:** iOS/iPadOS/macOS 26.2

## Key References
- [Inigo Quilez's site](https://iquilezles.org/)
- [Domain Warping](https://iquilezles.org/articles/warp/)
- [fBM](https://iquilezles.org/articles/fbm/)
- [Noise Derivatives](https://iquilezles.org/articles/morenoise/)
- [Color Palettes](https://iquilezles.org/articles/palettes/)
- [Shadertoy: Warp (4s23zz)](https://www.shadertoy.com/view/4s23zz)
- [Shadertoy: Animated Warp (lsl3RH)](https://www.shadertoy.com/view/lsl3RH)
