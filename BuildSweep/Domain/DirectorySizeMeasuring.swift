import Foundation

/// The best read-only size observation available for one classified directory.
///
/// A partial or unavailable measurement remains useful for inspection, but it must not be promoted
/// to cleanup authority.
nonisolated enum DirectorySizeMeasurement: Equatable, Sendable {
    case complete(allocatedByteCount: UInt64)
    case partial(allocatedByteCount: UInt64)
    case unavailable
    case cancelled
}

/// Measures storage without deciding whether a directory is safe to clean.
nonisolated protocol DirectorySizeMeasuring: Sendable {
    func measureDirectory(
        at directoryURL: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> DirectorySizeMeasurement
}
