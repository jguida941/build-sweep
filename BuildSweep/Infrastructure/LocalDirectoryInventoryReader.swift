import Darwin
import Foundation

/// Supplies filesystem directories to scanners without owning classification policy.
nonisolated struct LocalDirectoryInventoryReader: DirectoryInventoryReading {
    private let maximumEntries: Int

    init(maximumEntries: Int = 100_000) {
        precondition(maximumEntries >= 0)
        self.maximumEntries = maximumEntries
    }

    func inventoryDirectories(
        under authorizedRoot: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> DirectoryInventoryResult {
        guard !shouldCancel() else {
            return .cancelled
        }

        let rootURL = authorizedRoot.standardizedFileURL
        let rootIssue = DirectoryInventoryIssue(directoryURL: rootURL, reason: .unreadable)
        guard
            rootURL.isFileURL,
            let rootMetadata = metadata(at: rootURL),
            fileType(of: rootMetadata) == mode_t(S_IFDIR)
        else {
            return .failed(issue: rootIssue)
        }

        var directories: [URL] = []
        var issues: [DirectoryInventoryIssue] = []
        var pendingDirectories = [rootURL]
        var observedEntries = 0
        while let directoryURL = pendingDirectories.popLast() {
            guard !shouldCancel() else {
                return .cancelled
            }

            // A queued directory may have changed since its parent was inspected.
            guard
                let directoryMetadata = metadata(at: directoryURL),
                fileType(of: directoryMetadata) == mode_t(S_IFDIR)
            else {
                issues.append(DirectoryInventoryIssue(directoryURL: directoryURL, reason: .unreadable))
                continue
            }
            guard directoryMetadata.st_dev == rootMetadata.st_dev else {
                continue
            }
            directories.append(directoryURL)

            let children: [URL]
            do {
                // Shallow lists keep a failed entry from pruning an unrelated branch.
                children = try FileManager.default.contentsOfDirectory(
                    at: directoryURL,
                    includingPropertiesForKeys: [],
                    options: []
                )
            } catch {
                issues.append(DirectoryInventoryIssue(directoryURL: directoryURL, reason: .unreadable))
                continue
            }

            for itemURL in children {
                guard !shouldCancel() else {
                    return .cancelled
                }
                // Count every child, including files and excluded entries, across the walk.
                guard observedEntries < maximumEntries else {
                    issues.append(
                        DirectoryInventoryIssue(directoryURL: directoryURL, reason: .entryLimitReached)
                    )
                    return .partial(directories: directories, issues: issues)
                }
                observedEntries += 1
                guard let itemMetadata = metadata(at: itemURL) else {
                    issues.append(
                        DirectoryInventoryIssue(
                            directoryURL: itemURL.standardizedFileURL,
                            reason: .unreadable
                        )
                    )
                    continue
                }

                // Only real directories on the authorized volume may enter the worklist.
                guard
                    fileType(of: itemMetadata) == mode_t(S_IFDIR),
                    itemMetadata.st_dev == rootMetadata.st_dev
                else {
                    continue
                }
                pendingDirectories.append(itemURL.standardizedFileURL)
            }
        }

        guard !shouldCancel() else {
            return .cancelled
        }
        if issues.contains(rootIssue) {
            return .failed(issue: rootIssue)
        }
        if issues.isEmpty {
            return .complete(directories: directories)
        }
        return .partial(directories: directories, issues: issues)
    }

    private func metadata(at url: URL) -> stat? {
        var itemMetadata = stat()
        let result = url.withUnsafeFileSystemRepresentation { path in
            guard let path else {
                return Int32(-1)
            }
            // Inspect the entry itself so a symbolic link is not reported as its target.
            return Darwin.lstat(path, &itemMetadata)
        }
        return result == 0 ? itemMetadata : nil
    }

    private func fileType(of metadata: stat) -> mode_t {
        metadata.st_mode & mode_t(S_IFMT)
    }
}
