import RunKit
import SwiftData
import SwiftUI

/// A property wrapper that provides an auto-updating list of `RunItem` values
/// backed by SwiftData.
///
/// Wraps `@Query<RunRecord>` so that views work with the safe, Sendable
/// `RunItem` type rather than the `@Model` reference type directly.
/// The list updates automatically whenever the underlying store changes,
/// using the same mechanism as `@Query`.
///
/// Usage:
/// ```swift
/// @RunLibraryQuery var items: [RunItem]
/// ```
///
@propertyWrapper
struct RunLibraryQuery: DynamicProperty {

    @Query(sort: \RunRecord.date, order: .reverse)
    private var records: [RunRecord]

    var wrappedValue: [RunItem] {
        records.map { $0.item }
    }
}
