import Darwin
import Foundation

/// Estimates allocated storage without reading file contents, excluding entries observed as links.
/// Path-based metadata reads are not protected against concurrent ancestor replacement.
nonisolated struct LocalDirectorySizeMeasurer: DirectorySizeMeasuring {
    func measureDirectory(
        at directoryURL: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> DirectorySizeMeasurement {
        guard !shouldCancel() else {
            return .cancelled
        }

        let rootURL = directoryURL.standardizedFileURL
        guard
            let rootMetadata = metadata(at: rootURL),
            fileType(of: rootMetadata) == mode_t(S_IFDIR)
        else {
            return .unavailable
        }

        var encounteredIncompleteObservation = false
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: nil,
            options: [],
            errorHandler: { _, _ in
                encounteredIncompleteObservation = true
                return true
            }
        ) else {
            return .unavailable
        }

        var allocatedByteCount: UInt64 = 0
        var observedFiles = Set<FileIdentity>()

        for case let itemURL as URL in enumerator {
            if shouldCancel() {
                return .cancelled
            }

            guard let itemMetadata = metadata(at: itemURL) else {
                encounteredIncompleteObservation = true
                enumerator.skipDescendants()
                continue
            }

            // A mounted filesystem can look like an ordinary child directory while widening the
            // scan beyond the selected volume. Exclude it and report that the estimate is partial.
            guard itemMetadata.st_dev == rootMetadata.st_dev else {
                encounteredIncompleteObservation = true
                enumerator.skipDescendants()
                continue
            }

            let itemType = fileType(of: itemMetadata)
            // Enumeration already excludes links; pruning here can skip a real sibling.
            if itemType == mode_t(S_IFLNK) {
                continue
            }
            guard itemType == mode_t(S_IFREG) else {
                continue
            }

            // Multiple hard-link paths refer to the same allocation and must be counted once.
            let identity = FileIdentity(
                device: UInt64(itemMetadata.st_dev),
                inode: UInt64(itemMetadata.st_ino)
            )
            guard observedFiles.insert(identity).inserted else {
                continue
            }

            guard itemMetadata.st_blocks >= 0 else {
                encounteredIncompleteObservation = true
                continue
            }

            // Darwin reports st_blocks in 512-byte units. APFS sharing can still make the eventual
            // space reclaimed differ, so the UI deliberately calls this an estimate.
            let (itemByteCount, itemOverflowed) = UInt64(itemMetadata.st_blocks)
                .multipliedReportingOverflow(by: 512)
            let (newTotal, totalOverflowed) = allocatedByteCount
                .addingReportingOverflow(itemByteCount)
            guard !itemOverflowed, !totalOverflowed else {
                encounteredIncompleteObservation = true
                continue
            }
            allocatedByteCount = newTotal
        }

        if encounteredIncompleteObservation {
            return .partial(allocatedByteCount: allocatedByteCount)
        }
        return .complete(allocatedByteCount: allocatedByteCount)
    }

    private func metadata(at url: URL) -> stat? {
        var itemMetadata = stat()
        let result = url.withUnsafeFileSystemRepresentation { path in
            guard let path else {
                return Int32(-1)
            }
            return lstat(path, &itemMetadata)
        }
        return result == 0 ? itemMetadata : nil
    }

    private func fileType(of metadata: stat) -> mode_t {
        metadata.st_mode & mode_t(S_IFMT)
    }
}

nonisolated private struct FileIdentity: Hashable, Sendable {
    let device: UInt64
    let inode: UInt64
}
