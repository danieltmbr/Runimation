# Runi — App Store Roadmap

## Context

The app is currently a mix of production features, diagnostics, and shader learning experiments, all within a TabView. The vision (Docs/runi.md) calls for a focused App Store product where the **Visualiser is the root experience**, with everything else accessed from there. This roadmap breaks that transformation into phases that can be tackled one at a time across multiple sessions.

## Decisions

- **IFS branch**: Parked. It's additive and doesn't affect existing code. Will resume after restructure.
- **Demo separation**: Xcode Workspace umbrella — production app + demo app as separate projects, sharing packages.
- **Platforms**: iOS + macOS for v1. visionOS deferred.
- **Roadmap location**: `Docs/roadmap.md` in the repo (version-controlled, visible in Xcode). Claude memory pointer for auto-loading.

## Workflow Recommendations

- **`Docs/roadmap.md` is the living document.** Updated after each session with progress and decisions.
- **One sub-task per conversation.** Start in plan mode to agree on approach, then execute. Keeps context focused.
- **Branch per phase** (e.g. `phase/0-workspace`). Merge to `main` when verified.
- **Key decisions saved to Claude memory** so future sessions have context without re-reading everything.
- **Verify before advancing.** Each phase has acceptance criteria that must pass before moving on.

---

## ✅ Phase 0: Separate Demo from Production
**Goal:** Move learning/demo content out of the main app into a separate target so it can never leak into the App Store build.

### Tasks
- [x] Create a new app target (or Xcode project under a Workspace) for the Learnings/Demo app
- [x] Move all demo views: `NoiseDemoView`, `FbmDemoView`, `WarpDemoView`, `ColorsDemoView`
- [x] The demo app depends on the `Visualiser` package (same shaders, same types) — just a different UI shell
- [x] Remove the "Learnings" tab group from `ContentView.swift`
- [x] Both apps build and run independently

### Key files
- `Runimation/ContentView.swift` — Learnings tab group removed ✓
- `Packages/Visualiser/` — renamed from Animations; `AnimationState` → `VisualiserState`, `VisualisationCanvas` → `VisualiserCanvas` ✓
- `RuniDemos/` — demo views live directly in the app target (no intermediate package) ✓

### Verification
- Production app builds without any demo views ✓
- Demo app builds and can display all learning shaders ✓
- No demo code in the production target ✓

### Approach: Xcode Workspace
`Runimation.xcworkspace` containing:
- `Runimation.xcodeproj` (production app)
- `RuniDemos.xcodeproj` (demo app, uses `PBXFileSystemSynchronizedRootGroup` pointing to `RuniDemos/`)
- Both reference the shared `Packages/` folder

---

## Phase 1: App Structure — Visualiser as Root
**Goal:** Replace the TabView with the Visualiser as the app's root view. Add navigation to Playback, Library, Customisation, and Export.

### Tasks
- [ ] Replace `ContentView`'s TabView with a single full-screen `VisualiserView` as root
- [ ] Add toolbar buttons: Run Library, Customisation Panel, Export (placeholder)
- [ ] Add Playback Control Strip to the toolbar (compact: run name + play toggle)
- [ ] Platform-adaptive layout:
  - iOS: buttons in bottom toolbar, sheets for panels
  - macOS: buttons in top toolbar, sidebar/sheet for panels
  - visionOS: ornaments (future consideration)
- [ ] Wire up `RunPlayer` and `StravaClient` injection at the root level (currently in `ContentView`)
- [ ] Auto-open Run Library on first launch when no run is loaded

### Key files
- `Runimation/ContentView.swift` — complete rewrite as Visualiser root
- `Runimation/Views/Runs/VisualiserView.swift` — promote to root-level view
- New: `Runimation/Views/PlaybackControlStrip.swift`
- `Packages/RunUI/` — existing playback controls to adapt

### Verification
- App launches directly into full-screen visualisation (or Library if no run)
- All navigation accessible from root: Library, Customisation, Export placeholder
- Playback strip visible and functional
- Works on iOS and macOS (the two v1 platforms)

---

## Phase 2: Playback UX
**Goal:** Implement the two-tier playback UI: compact Control Strip (always visible) and detailed Control Panel (on tap).

### Tasks
- [ ] **Control Strip** (toolbar): current run name + play/pause toggle. Minimal footprint.
- [ ] **Control Panel** (sheet/popover on tap): progress slider, elapsed time, duration picker, loop toggle, rewind. Resembles a media player.
- [ ] Platform adaptation:
  - iOS: Strip in bottom toolbar, Panel as `.sheet` or `.bottomSheet`
  - macOS: Strip in top toolbar, Panel as popover or panel
- [ ] Reuse/adapt existing RunUI controls: `PlayToggle`, `ProgressSlider`, `LoopToggle`, `RewindButton`, `ElapsedTimeLabel`, `DurationPicker`
- [ ] Existing `PlaybackControlsStyle` system may need new styles or refactoring

### Key files
- `Packages/RunUI/Sources/RunUI/Player/Views/PlaybackControls/` — existing styles
- `Packages/RunUI/Sources/RunUI/Player/Controls/` — existing control views
- New or adapted: `CompactPlaybackControlsStyle` → Control Strip style
- New or adapted: `RegularPlaybackControlsStyle` → Control Panel style

### Verification
- Strip shows run name + play toggle, always visible
- Tapping strip opens Control Panel with all secondary controls
- Controls work: play/pause, seek, loop, rewind, duration change

---

## Phase 3: Run Library
**Goal:** Unified run list with Strava + GPX support, proper empty state, and streamlined run selection.

### Tasks
- [ ] Redesign `StravaRunsView` as a unified "Run Library" (or build new)
- [ ] Run selection = load into player + dismiss library (primary action)
- [ ] Run detail = secondary action (simple metrics, not the full metrics view)
- [ ] Empty state: Strava connect CTA + GPX import explanation + file browser button
- [ ] GPX drag-and-drop support (macOS/iPadOS)
- [ ] GPX file picker (iOS file browser via `UIDocumentPickerViewController` / `.fileImporter`)
- [ ] Auto-open on first launch when player has no run

### Key files
- `Runimation/Views/Strava/StravaRunsView.swift` — currently Strava-only, needs to become unified
- `Packages/StravaKit/` — Strava API client (already works)
- `Packages/CoreKit/Sources/CoreKit/GPX.swift` — GPX parser (already works)
- New: `Runimation/Views/Library/RunLibraryView.swift`

### Verification
- Library shows all available runs (Strava + imported GPX)
- Tapping a run loads it and returns to visualiser
- GPX files can be imported via drag-and-drop and file picker
- Empty state prompts Strava connection

---

## Phase 4: Customisation Panel
**Goal:** Consolidated panel for tuning the visualisation and data processing pipeline.

### Tasks
- [ ] Customisation Panel accessible from root toolbar button
- [ ] Contains:
  - Visualisation picker (Warp, IFS, Path, etc.)
  - Visualisation Adjustment Form (via `FormAdjustable` — already exists)
  - Data Processing Pipeline settings (transformers + interpolator — already exists in `SignalProcessingContent`)
- [ ] Platform adaptation:
  - iOS: sheet
  - macOS: trailing sidebar (inspector) or sheet
- [ ] Refactor existing `PlayerInspectorView`/`PlayerSheetView` to fit new structure

### Key files
- `Runimation/Views/Runs/Visualisation/Inspector/` — existing inspector views
- `Packages/Animations/Sources/Animations/VisualisationPicker.swift`
- `Packages/Animations/Sources/Animations/Visualisations/*/Form.swift` — per-visualisation forms
- `Runimation/Views/Runs/Visualisation/Inspector/SignalProcessing/`

### Verification
- Customisation panel opens from root
- Can switch visualisation type
- Can adjust visualisation parameters
- Can modify data processing pipeline
- Changes reflect immediately in the visualiser

---

## Phase 5: Persistence (SwiftData)
**Goal:** Persist runs and visualisation settings. Required before App Store release.

### Tasks
- [ ] Define SwiftData models:
  - `PersistedRun`: run metadata + segments (from GPX/Strava)
  - `PersistedVisualisation`: run-specific visualisation config (Codable JSON blob)
  - `PersistedPipeline`: transformer + interpolator chain config
- [ ] Add `Codable` conformance to all `Visualisation` types (`Warp`, `IFS`, `RunPath`)
- [ ] Add `Codable` conformance to all `RunTransformer` and `RunInterpolator` types
- [ ] Migrate from in-memory `RunPlayer.setRun(track:)` to SwiftData-backed loading
- [ ] State restoration: on launch, restore last-played run + visualisation settings
- [ ] Run Library reads from SwiftData (Strava fetch → persist → display from DB)
- [ ] Consider migration strategy for future schema changes

### Key files
- New: `Runimation/Model/` — SwiftData models
- `Packages/Animations/Sources/Animations/Visualisations/` — add Codable
- `Packages/RunKit/Sources/RunKit/` — add Codable to transformers/interpolators
- `Runimation/Views/Library/RunLibraryView.swift` — switch to SwiftData queries

### Verification
- Runs persist across app launches
- Visualisation settings restore when reopening a run
- Pipeline settings restore
- Strava-fetched runs are saved locally
- GPX-imported runs are saved locally

---

## Phase 6: Export & Share
**Goal:** Allow users to export their visualisation as a video and share it.

### Tasks
- [ ] Record visualisation playback to video using `AVAssetWriter` + Metal texture capture
- [ ] Export UI: progress indicator during recording, save/share on completion
- [ ] iOS: `UIActivityViewController` share sheet
- [ ] macOS: `NSSavePanel` for file save + share
- [ ] Consider resolution/duration options

### Key files
- New: video recording infrastructure (Metal texture → pixel buffer → AVAssetWriter)
- New: export UI view

### Verification
- Can export a full playback as .mp4
- Video looks identical to on-screen rendering
- Share sheet works on iOS, save panel works on macOS

---

## Phase 7: Polish & App Store Submission
**Goal:** Final polish pass and submission.

### Tasks
- [ ] App icon (already have `Icon.icon/`)
- [ ] Launch screen
- [ ] App Store metadata: screenshots, description, keywords, category
- [ ] Accessibility audit (VoiceOver, Dynamic Type where applicable)
- [ ] Performance profiling on target devices
- [ ] Error handling: network failures, invalid GPX, Strava auth edge cases
- [ ] Edge cases: no network, empty runs, very short/long runs
- [ ] Privacy: App Tracking Transparency if needed, privacy policy
- [ ] TestFlight beta
- [ ] App Store submission

### Verification
- Runs smoothly on oldest supported devices
- No crashes in normal usage flows
- Accessible
- App Store review guidelines met

---

## Future (Post-v1)

These are documented in `Docs/runi.md` but not in scope for the initial release:

- **Run-to-Visualisation wiring UI** — let users customise which metric drives which shader parameter
- **Concatenate/Merge runs** — multi-run visualisations, playlists
- **Composable visualisations** — swap shader pipeline components (noise type, distortion, etc.)
- **Collaboration** — CloudKit sharing of runs between users
- **Favourites & Playlists** — enabled by persistence
- **`.runi` file sharing** — export visualisation config as data file

---

## Progress Log

_Updated after each session. Format: `[date] Phase X.Y — what was done`_

[2026-03-23] Roadmap created. Decisions: IFS branch parked, workspace approach for demo separation, iOS+macOS v1.
[2026-03-24] Phase 0 complete — Runimation.xcworkspace + RuniDemos.xcodeproj created. AnimationsDemos package eliminated; demo views live directly in the RuniDemos app target. Animations package renamed to Visualiser (AnimationState → VisualiserState, VisualisationCanvas → VisualiserCanvas). Learnings tab removed from production ContentView. Swift 6 concurrency warnings fixed in all demo views (TimelineView pattern, @State extracted to locals before .visualEffect). Branch: phase/0-workspace.
