# RunStorage Design Discussion

_Recorded 2026-04-06. Context: Phase 7 app structure cleanup, after extracting `RunLibrary` into RunKit with `ActivityTracker` and `RunStorage` protocols._

---

## The Problem

`RunLibrary` lives in RunKit and can't access `RunRecord` (an app-level SwiftData `@Model`). It goes through `RunStorage` as a surrogate. Every piece of data it needs from a record becomes a separate protocol method, producing a proliferation of fine-grained queries:

```swift
// Reads
func exists(source: ActivitySource) -> Bool
func name(for id: UUID) -> String?
func trackData(for id: UUID) -> Data?
func origin(for id: UUID) -> RunOrigin?
func lastPlayedID() -> UUID?

// Writes
func storeTrackData(_ data: Data, for id: UUID)
func updateDistance(_ distance: Double, for id: UUID)
func markAsPlayed(id: UUID)
func delete(id: UUID)
func ids(fromTracker trackerID: String) -> [UUID]
```

The question: is there a better design that reduces this surface without introducing other problems?

---

## Options Explored

### Option A — `StoredRunSummary` struct

Consolidate the three co-called read methods (`name`, `trackData`, `origin`) into one struct:

```swift
public struct StoredRunSummary: Sendable {
    public let name: String
    public let source: RunOrigin
    public let trackData: Data?
}

// RunStorage
func summary(for id: UUID) -> StoredRunSummary?
```

`loadRun` then makes a single storage call instead of up to three:

```swift
guard let summary = storage.summary(for: entry.id) else { throw LoadError.notFound }
if let data = summary.trackData {
    return try parseAndCache(data: data, name: summary.name, id: entry.id)
}
let track = try await fetchTrack(for: summary.source)
```

**Net result:** 3 read methods → 1. Write side unchanged. Small, safe, low-risk.

**Verdict:** Good first step, but doesn't address the write side (`storeTrackData`, `updateDistance`) and doesn't fundamentally change the architecture.

---

### Option B — Generic `RunLibrary<Record: LibraryRecord>`

Introduce a `LibraryRecord` protocol that `RunRecord` conforms to. `RunLibrary` becomes generic and holds/mutates records directly:

```swift
public protocol LibraryRecord: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var source: RunOrigin { get }
    var trackData: Data? { get set }
    var distance: Double { get set }
}

public final class RunLibrary<Record: LibraryRecord> {
    func loadRun(for record: Record) async throws -> Run {
        if let data = record.trackData {
            return try parseAndCache(data: data, name: record.name, id: record.id)
        }
        let track = try await fetchTrack(for: record.source)
        record.trackData = try JSONEncoder().encode(track.points)
        let run = runParser.run(from: track, id: record.id)
        record.distance = run.distance
        cache[record.id] = run
        return run
    }
}
```

`RunStorage` becomes a simple CRUD factory returning `Record` objects. Nearly all the fine-grained read/write methods disappear.

**The catch — `LibraryState` breaks:**

`LibraryState` in RunUI reads `RunLibrary` from the environment:

```swift
public struct LibraryState<Value>: DynamicProperty {
    @Environment(RunLibrary.self)
    private var library
    ...
}
```

With a generic library it needs the concrete `Record` type:

```swift
public struct LibraryState<Record: LibraryRecord, Value>: DynamicProperty {
    @Environment(RunLibrary<Record>.self)
    private var library
    ...
}
```

But `RunRecord` is an app type — it can't appear in RunUI. `LibraryState` would have to move back to the app. Every RunUI view using `@LibraryState` would be locked to the app target. Every `@Environment(RunLibrary.self)` call becomes `@Environment(RunLibrary<RunRecord>.self)`.

Type-erasing with `AnyRunLibrary` could paper over this, but then you have two environment objects — a typed one for mutations, an erased one for reads — and the design becomes messier than what it replaced.

**Verdict:** Architecturally clean in isolation, but the generic parameter bleeds upward through `LibraryState`, every control view, every environment read in RunUI. The friction isn't worth it for a single-app project.

---

### Option C — `StoredRun` class-constrained protocol (preferred)

Don't make `RunLibrary` generic. Instead, give `RunStorage` methods that return opaque objects `RunLibrary` can read *and mutate* directly:

```swift
// RunKit
public protocol StoredRun: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var source: RunOrigin { get }
    var trackData: Data? { get set }
    var distance: Double { get set }
}

public protocol RunStorage: AnyObject {
    func exists(source: ActivitySource) -> Bool
    func run(for id: UUID) -> (any StoredRun)?
    func insert(...) -> any StoredRun
    func all(fromTracker trackerID: String) -> [any StoredRun]
    func lastPlayed() -> (any StoredRun)?
}
```

In the app, `RunRecord` conforms to `StoredRun` — no structural changes needed, all the properties already exist:

```swift
extension RunRecord: StoredRun {}
```

`RunLibrary.loadRun` becomes:

```swift
public func loadRun(for entry: RunEntry) async throws -> Run {
    guard let stored = storage.run(for: entry.id) else { throw LoadError.notFound }
    if let data = stored.trackData {
        return try parseAndCache(data: data, name: stored.name, id: entry.id)
    }
    let track = try await fetchTrack(for: stored.source)
    stored.trackData = try JSONEncoder().encode(track.points)  // direct mutation
    let run = runParser.run(from: track, id: entry.id)
    stored.distance = run.distance                              // direct mutation
    cache[entry.id] = run
    return run
}
```

`storeTrackData`, `updateDistance`, `name(for:)`, `trackData(for:)`, `origin(for:)` all disappear from `RunStorage`. No generics. `LibraryState` is completely untouched. `RunLibrary` stays `RunLibrary`.

**Swift 6 note:** Mutating a `@Model` object through `any StoredRun` is safe here — both `RunLibrary` and the `ModelContext` are `@MainActor`, and `StoredRun: AnyObject` means mutation is a reference operation on the same actor.

**Verdict:** Best standalone fix. Eliminates almost all fine-grained methods without introducing generics or moving `LibraryState`.

---

### Option D — Persistence in its own package (or CoreKit)

Move `RunEntry`, `RunOrigin`, `ActivitySource`, and the `StoredRun` protocol into a shared package that RunKit can depend on.

**Version 1: New `PersistenceKit`**

```
CoreKit           ← no deps        [GPX, Option, utilities]
PersistenceKit    ← CoreKit        [RunEntry, RunOrigin, ActivitySource, StoredRun protocol]
RunKit            ← PersistenceKit [RunLibrary, RunPlayer, Run]
App               ← RunKit         [RunRecord: StoredRun]
```

`PersistenceKit` holds only the protocol contract — not the SwiftData implementation. `RunRecord` stays in the app; it just conforms to `StoredRun` from `PersistenceKit`. No SwiftData enters any package.

**Version 2: Fold into CoreKit**

`RunEntry`, `RunOrigin`, `ActivitySource`, `StoredRun` move to CoreKit. RunKit already depends on CoreKit — no new edges in the dependency graph.

**Appeal:** These types feel like primitives. `RunOrigin` is similar in spirit to `GPX.Track` — a value describing the provenance of data. Moving them lower tightens the layering story.

**The real blocker — `RunRecord` is not portable:**

`RunRecord` has four app-specific fields that reference config types from Visualiser and RunUI:

```swift
var visualisationConfigData: Data?
var transformersConfigData: Data?
var interpolatorConfigData: Data?
var playDuration: TimeInterval?
```

A `RunRecord` defined in a shared package would be missing these fields. You'd need two separate `@Model` types, which breaks `@Query` (which operates on a single concrete type) and the SwiftData store schema. SwiftData `@Model` cannot be extended with stored properties from outside its definition. This is a hard blocker.

**Secondary concerns:**

- Adding SwiftData as a transitive dependency of RunKit forces every consumer (test targets, CLI tools, other platforms) to link against SwiftData even if they never touch persistence.
- CoreKit is currently framework-agnostic (Foundation + CoreGraphics only). Pulling domain concepts like "activity source" or "stored run" into it blurs its identity.

**Verdict:** Moving the *protocol* types (`RunEntry`, `RunOrigin`, `ActivitySource`, `StoredRun`) to a new package or CoreKit is architecturally sound — but blocked in practice by `RunRecord`'s app-specific config fields making a shared `@Model` impossible. File for later if a second app ever needs to share RunKit with a different persistence model.

---

## Comparison

| | Protocol methods removed | Generics | New packages | `LibraryState` impact |
|---|---|---|---|---|
| **A** `StoredRunSummary` | 3 → 1 (reads only) | None | None | None |
| **B** Generic `RunLibrary<Record>` | Nearly all | Everywhere | None | Breaks, moves to app |
| **C** `StoredRun` protocol | Nearly all | None | None | **None** |
| **D** Persistence package | Depends on C | None | 1 new | None |

---

## Recommendation

**Implement Option C next.** It gives most of the benefit of the generic approach with none of the cascade. `StoredRun` is a 6-line protocol; `RunRecord`'s conformance is implicit (properties already exist); `LibraryState` and all RunUI views are untouched.

**Keep Option D in mind** for a future structural pass — specifically if a second app ever needs to share RunKit with a different persistence backend. At that point, extracting `RunEntry`, `RunOrigin`, `ActivitySource`, and `StoredRun` into a shared package would give the package graph a cleaner layering. Blocked until `RunRecord`'s app-specific config fields can be cleanly separated from its core identity.

**Option B** (generic library) becomes interesting again only if `RunLibraryView` ever moves to RunUI — at which point the view also needs the `LibraryRecord` protocol and the generics friction is already being paid anyway. Still blocked by `@Query` requiring a concrete SwiftData type.
