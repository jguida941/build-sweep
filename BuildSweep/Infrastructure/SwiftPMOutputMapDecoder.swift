import Foundation

nonisolated enum SwiftPMOutputMapFailure: Error, Equatable, Sendable {
    case byteLimitExceeded
    case invalidFormat
    case unsupportedEntry
}

/// Decodes declared per-source object paths without validating or opening them.
nonisolated struct SwiftPMOutputMapDecoder: Sendable {
    let maximumByteCount: Int

    init(maximumByteCount: Int = 1_048_576) {
        self.maximumByteCount = max(0, maximumByteCount)
    }

    func decode(_ data: Data) -> Result<[SwiftPMObjectReference], SwiftPMOutputMapFailure> {
        guard data.count <= maximumByteCount else {
            return .failure(.byteLimitExceeded)
        }
        guard let entries = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return .failure(.invalidFormat)
        }

        // The empty key describes whole-module outputs, not a source file.
        guard entries[""]?["object"] == nil else {
            return .failure(.unsupportedEntry)
        }

        var references: [SwiftPMObjectReference] = []
        for sourcePath in entries.keys.sorted() where !sourcePath.isEmpty {
            guard let objectPath = entries[sourcePath]?["object"], !objectPath.isEmpty else {
                return .failure(.unsupportedEntry)
            }
            references.append(SwiftPMObjectReference(
                sourcePath: sourcePath,
                objectPath: objectPath
            ))
        }
        return .success(references)
    }
}
