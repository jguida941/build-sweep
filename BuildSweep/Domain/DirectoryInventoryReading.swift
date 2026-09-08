import Foundation

nonisolated struct DirectoryInventoryIssue: Equatable, Sendable {
    nonisolated enum Reason: Equatable, Sendable {
        case unreadable
    }

    let directoryURL: URL
    let reason: Reason
}

/// Describes what a bounded directory inventory could observe.
nonisolated enum DirectoryInventoryResult: Equatable, Sendable {
    case complete(directories: [URL])
    case partial(directories: [URL], issues: [DirectoryInventoryIssue])
    case cancelled
    case failed(issue: DirectoryInventoryIssue)
}

/// Inventories directories without deciding whether any of them are build artifacts.
nonisolated protocol DirectoryInventoryReading: Sendable {
    func inventoryDirectories(
        under authorizedRoot: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> DirectoryInventoryResult
}
