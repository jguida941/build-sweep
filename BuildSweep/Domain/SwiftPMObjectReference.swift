import Foundation

/// Paths declared by compiler metadata, with no filesystem or cleanup authority.
nonisolated struct SwiftPMObjectReference: Equatable, Sendable {
    let sourcePath: String
    let objectPath: String
}
