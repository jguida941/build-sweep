import Darwin
import Foundation

/// Supplies filesystem directories to scanners without owning classification policy.
nonisolated struct LocalDirectoryInventoryReader: DirectoryInventoryReading {
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

        var issues: [DirectoryInventoryIssue] = []
        guard let enumerator = FileManager.default.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [],
            options: [],
            errorHandler: { url, _ in
                issues.append(
                    DirectoryInventoryIssue(
                        directoryURL: url.standardizedFileURL,
                        reason: .unreadable
                    )
                )
                return true
            }
        ) else {
            return .failed(issue: rootIssue)
        }

        // Enumeration omits the selected directory, which may itself be a workspace.
        var directories = [rootURL]
        for case let itemURL as URL in enumerator {
            guard !shouldCancel() else {
                return .cancelled
            }

            guard let itemMetadata = metadata(at: itemURL) else {
                issues.append(
                    DirectoryInventoryIssue(
                        directoryURL: itemURL.standardizedFileURL,
                        reason: .unreadable
                    )
                )
                enumerator.skipDescendants()
                continue
            }

            guard fileType(of: itemMetadata) == mode_t(S_IFDIR) else {
                enumerator.skipDescendants()
                continue
            }

            // A directory on another device is outside this scan's volume boundary.
            guard itemMetadata.st_dev == rootMetadata.st_dev else {
                enumerator.skipDescendants()
                continue
            }

            directories.append(itemURL.standardizedFileURL)
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
