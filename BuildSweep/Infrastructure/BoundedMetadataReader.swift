import Foundation

nonisolated enum MetadataReadFailure: Error, Equatable, Sendable {
    case byteLimitExceeded
    case unreadable
}

/// Borrows a readable handle at its current position; the caller owns access and exclusive use.
nonisolated struct BoundedMetadataReader: Sendable {
    let maximumByteCount: Int

    init(maximumByteCount: Int = 1_048_576) {
        self.maximumByteCount = max(0, maximumByteCount)
    }

    func read(from handle: FileHandle) -> Result<Data, MetadataReadFailure> {
        var bytes = Data()
        do {
            while true {
                let remaining = maximumByteCount - bytes.count
                // Cap the request before adding the byte that distinguishes EOF from overflow.
                let requestCount = min(remaining, 65_535) + 1
                guard let chunk = try handle.read(upToCount: requestCount), !chunk.isEmpty else {
                    return .success(bytes)
                }
                guard chunk.count <= remaining else {
                    return .failure(.byteLimitExceeded)
                }
                bytes.append(chunk)
            }
        } catch {
            return .failure(.unreadable)
        }
    }
}
