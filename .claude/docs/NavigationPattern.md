# Scoped Navigation Pattern

## Why This Pattern

The app originally kept all navigation state in one `NavigationModel` owned by the app layer. Every view that had access to `NavigationModel` could read or write every property — `showLibrary`, `exportingRun`, `statsPath`, everything. As features move into dedicated Swift packages this becomes a correctness problem: an Export package shouldn't be able to toggle the library sheet, and internal "wizard step" states should be invisible outside the package that owns the journey.

The solution is an **extensible scope registry**: `NavigationModel` (in CoreUI) holds feature-specific navigation objects in an `@ObservationIgnored` dictionary. Each feature package (or the app layer, before a feature is packaged) defines its own `@Observable` scope class and extends `NavigationModel` with a computed entry point. Swift's module-level access control on the scope's properties then enforces the isolation at compile time.

---

## Package Classification

Packages are classified into three tiers. Dependencies only flow down — no package depends on a package in the same tier or above it.

### Fundamental Packages
Anything can depend on these. They have no dependencies on other Runimation packages.

| Package | Contents |
|---------|---------|
| **CoreKit** | Pure Swift utilities, shared types, no UI |
| **CoreUI** | SwiftUI infrastructure: `NavigationModel`, `@Navigation`, `Item`, `FormAdjustable`, `AdjustableForm`, `OptionList`, `OptionDetail` |

### Functional Packages
Focused, single-responsibility features. May depend on fundamental packages only.

| Package | Contents |
|---------|---------|
| **RunKit** | `RunPlayer`, `Run`, `GPX`, `RunTransformer`, `RunInterpolator`, playback logic |
| **RunUI** | Player controls, charts, transformer forms — extends `NavigationModel` with `PlayerNavigation` |
| **Animations** | Metal shaders, `Warp`, `WarpView`, `AnimationState`, palette system |
| **StravaKit** | Strava OAuth + API client |

### Feature Packages
Composed features; may depend on fundamental and functional packages, not on other feature packages.

| Package | Contents (planned) |
|---------|---------|
| **ExportPackage** | Export sheet, format selection, rendering — extends `NavigationModel` with `ExportNavigation` |
| **ImportPackage** | File import, library save dialogue — extends `NavigationModel` with `ImportNavigation` |

The app layer itself acts as the integration layer: it imports all packages, assembles `NavigationModel` by registering all scopes, and provides the environment. It may also define navigation scopes for features that haven't been packaged yet (e.g., `LibraryNavigation` lives in the app layer until a Library package exists).

---

## How the Pattern Works

### 1. CoreUI — NavigationModel (Extensible Registry)

```swift
@MainActor @Observable
public final class NavigationModel {

    // @ObservationIgnored: SwiftUI never tracks the dictionary lookup itself,
    // only the properties accessed on the returned scope object.
    @ObservationIgnored
    private var _scopes: [ObjectIdentifier: AnyObject] = [:]

    public let autoRestore: Bool  // window-level config, not feature state

    public init(autoRestore: Bool) {
        self.autoRestore = autoRestore
    }

    public func register<S: AnyObject>(_ scope: S) {
        _scopes[ObjectIdentifier(S.self)] = scope
    }

    func scope<S: AnyObject>(_ type: S.Type) -> S {
        guard let scope = _scopes[ObjectIdentifier(type)] as? S else {
            fatalError("Navigation scope \(S.self) not registered. Call register(_:) before use.")
        }
        return scope
    }
}
```

### 2. CoreUI — @Navigation Property Wrapper

```swift
@MainActor @propertyWrapper
public struct Navigation<Value>: DynamicProperty {

    @Environment(NavigationModel.self) private var model

    private let get: @MainActor (NavigationModel) -> Value
    private let set: @MainActor (NavigationModel, Value) -> Void

    /// Read-only (for constants or private(set) properties)
    public init(_ path: KeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { _, _ in }
    }

    /// Read-write — exposes Binding via $
    public init(_ path: ReferenceWritableKeyPath<NavigationModel, Value>) {
        get = { $0[keyPath: path] }
        set = { $0[keyPath: path] = $1 }
    }

    public var wrappedValue: Value {
        get { get(model) }
        nonmutating set { set(model, newValue) }
    }

    public var projectedValue: Binding<Value> {
        Binding { get(model) } set: { set(model, $0) }
    }
}
```

### 3. Feature — Scope Class + NavigationModel Extension

Every feature that owns navigation state does two things:

**A. Define an `@Observable` scope class inside the feature's module:**

```swift
// In ExportPackage (or app layer until packaged):
@MainActor @Observable
public final class ExportNavigation {
    // Public: the entry point other packages/app can trigger
    public var exportingRun: RunItem?

    // Internal: only ExportPackage views can see or set this
    var showVideoExport = false
    var showDocumentExport = false
}
```

**B. Extend `NavigationModel` with a computed entry point:**

```swift
// In ExportPackage — depends on CoreUI, so extension is valid
extension NavigationModel {
    var export: ExportNavigation {
        get { scope(ExportNavigation.self) }
        set { }  // no-op: required so Swift forms a ReferenceWritableKeyPath
    }
}
```

The **no-op setter** is critical: without it, `\.export` is a read-only `KeyPath`, and `\.export.exportingRun` cannot form a `ReferenceWritableKeyPath`. With it, Swift constructs a writable keypath — but the setter is never invoked when writing through `\.export.someProperty`, because Swift writes directly to the reference that `get` returns.

### 4. App Layer — Registration

```swift
// RuniWindow.swift
let navigation = NavigationModel(autoRestore: autoRestore)
navigation.register(ExportNavigation())
navigation.register(ImportNavigation())
navigation.register(LibraryNavigation())
navigation.register(PlayerNavigation())

// Single injection:
.environment(navigation)
```

### 5. Usage

```swift
// App layer — can only see public properties of each scope:
@Navigation(\.export.exportingRun) private var exportingRun
@Navigation(\.library.showLibrary) private var showLibrary
@Navigation(\.autoRestore) private var autoRestore  // base property on NavigationModel

// Inside ExportPackage — can also see internal properties:
@Navigation(\.export.showVideoExport) private var showVideoExport  // ✓ internal
// (This line would fail to compile in the app layer or any other package)
```

---

## Why Observation Still Works

`@Observable` tracks property access at the concrete-type level. When a view body runs and accesses `navigationModel.export.exportingRun`:

1. `navigationModel.export` calls `scope(ExportNavigation.self)`, which reads `_scopes` — but `_scopes` is `@ObservationIgnored`, so **this access is not tracked**.
2. `.exportingRun` is accessed on the concrete `ExportNavigation` instance — `@Observable` **does track this**.

Result: the view re-renders only when `ExportNavigation.exportingRun` changes. It does not re-render when other scopes are updated, and it does not re-render if scopes are registered (since that also touches `@ObservationIgnored` storage). Fine-grained observation is fully preserved. ✓

---

## End-to-End Example: Export Feature Migration

**Today (app layer):**
```
Runimation/
  Navigation/
    ExportNavigation.swift   ← scope class + NavigationModel extension (internal access modifier)
```

**When ExportPackage is created:**
```
Packages/ExportPackage/
  Sources/ExportPackage/
    Navigation/
      ExportNavigation.swift  ← same class, same extension, now truly module-isolated
      ExportSheet.swift       ← uses @Navigation(\.export.showVideoExport) — internal only
```

The app layer continues to use `@Navigation(\.export.exportingRun)` (public). The internal states `showVideoExport` and `showDocumentExport` simply stop being visible outside the package — no other code changes.

---

## Implementation Checklist for New Navigation Scopes

When adding navigation state for a new feature:

1. **Create a scope class** — `@MainActor @Observable public final class [Feature]Navigation`
   - Mark properties that external callers need as `public`
   - Leave internal journey states with no modifier (module-internal)

2. **Extend NavigationModel** — add `var [feature]: [Feature]Navigation` with get + no-op set

3. **Register at startup** — `navigationModel.register([Feature]Navigation())` in `RuniWindow.init` (or wherever the `NavigationModel` is created)

4. **Use `@Navigation`** — `@Navigation(\.[feature].[property]) private var property`
   - Prefer `ReferenceWritableKeyPath` init for mutable state
   - Use `KeyPath` init for `let` / read-only properties

5. **Never** put scopes in `NavigationModel` as stored properties — that bypasses the isolation
6. **Never** access a scope object directly from the environment without going through `NavigationModel` — the `@Navigation` wrapper is the canonical access point
