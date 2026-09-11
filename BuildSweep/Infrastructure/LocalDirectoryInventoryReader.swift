import Darwin
import Foundation

/// Supplies filesystem directories to scanners without owning classification policy.
nonisolated struct LocalDirectoryInventoryReader: DirectoryInventoryReading {
    private let maximumEntries: Int
    private let directoryFlags = O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC

    init(maximumEntries: Int = 100_000) {
        precondition(maximumEntries >= 0)
        self.maximumEntries = maximumEntries
    }

    func inventoryDirectories(
        under authorizedRoot: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> DirectoryInventoryResult {
        guard !shouldCancel() else { return .cancelled }
        let rootURL = authorizedRoot.standardizedFileURL
        let rootIssue = DirectoryInventoryIssue(directoryURL: rootURL, reason: .unreadable)
        guard rootURL.isFileURL else { return .failed(issue: rootIssue) }
        let rootDescriptor = rootURL.withUnsafeFileSystemRepresentation { path in
            path.map { Darwin.open($0, directoryFlags) } ?? -1
        }
        guard rootDescriptor >= 0 else { return .failed(issue: rootIssue) }
        defer { Darwin.close(rootDescriptor) }
        guard let rootMetadata = metadata(descriptor: rootDescriptor) else {
            return .failed(issue: rootIssue)
        }

        var directories: [URL] = []
        var issues: [DirectoryInventoryIssue] = []
        var pending = [PendingDirectory(url: rootURL, components: [])]
        var observedEntries = 0
        while let directory = pending.popLast() {
            guard !shouldCancel() else { return .cancelled }
            let descriptor: Int32
            switch openDirectory(directory.components, under: rootDescriptor, device: rootMetadata.st_dev) {
            case .opened(let opened): descriptor = opened
            case .outsideVolume: continue
            case .unreadable(let observedDirectory):
                if observedDirectory { directories.append(directory.url) }
                issues.append(DirectoryInventoryIssue(directoryURL: directory.url, reason: .unreadable))
                continue
            }
            directories.append(directory.url)
            guard let stream = Darwin.fdopendir(descriptor) else {
                Darwin.close(descriptor)
                issues.append(DirectoryInventoryIssue(directoryURL: directory.url, reason: .unreadable))
                continue
            }
            // The stream owns its descriptor, including on cancellation and limit returns.
            defer { Darwin.closedir(stream) }
            while true {
                errno = 0
                guard let entry = Darwin.readdir(stream) else {
                    if errno != 0 {
                        issues.append(DirectoryInventoryIssue(directoryURL: directory.url, reason: .unreadable))
                    }
                    break
                }
                let name = withUnsafePointer(to: &entry.pointee.d_name) { pointer in
                    pointer.withMemoryRebound(to: CChar.self, capacity: Int(entry.pointee.d_namlen) + 1) {
                        String(validatingUTF8: $0)
                    }
                }
                if name == "." || name == ".." { continue }
                guard !shouldCancel() else { return .cancelled }
                guard observedEntries < maximumEntries else {
                    issues.append(DirectoryInventoryIssue(directoryURL: directory.url, reason: .entryLimitReached))
                    return .partial(directories: directories, issues: issues)
                }
                observedEntries += 1
                guard let name, !name.isEmpty, !name.contains("/") else {
                    issues.append(DirectoryInventoryIssue(directoryURL: directory.url, reason: .unreadable))
                    continue
                }
                let itemURL = directory.url.appendingPathComponent(name, isDirectory: true)
                var itemMetadata = stat()
                let status = name.withCString {
                    Darwin.fstatat(descriptor, $0, &itemMetadata, AT_SYMLINK_NOFOLLOW)
                }
                guard status == 0 else {
                    issues.append(DirectoryInventoryIssue(directoryURL: itemURL, reason: .unreadable))
                    continue
                }
                guard itemMetadata.st_mode & mode_t(S_IFMT) == mode_t(S_IFDIR),
                      itemMetadata.st_dev == rootMetadata.st_dev else { continue }
                pending.append(PendingDirectory(url: itemURL, components: directory.components + [name]))
            }
        }
        guard !shouldCancel() else { return .cancelled }
        if issues.contains(rootIssue) { return .failed(issue: rootIssue) }
        return issues.isEmpty ? .complete(directories: directories) : .partial(directories: directories, issues: issues)
    }

    private struct PendingDirectory {
        let url: URL
        let components: [String]
    }

    private enum DirectoryOpenResult {
        case opened(Int32)
        case outsideVolume
        case unreadable(observedDirectory: Bool)
    }

    private func openDirectory(_ components: [String], under root: Int32, device: dev_t) -> DirectoryOpenResult {
        var descriptor = Darwin.openat(root, ".", directoryFlags)
        guard descriptor >= 0 else { return .unreadable(observedDirectory: false) }
        for (index, component) in components.enumerated() {
            // A single relative component cannot traverse an unchecked ancestor link.
            let child = component.withCString { Darwin.openat(descriptor, $0, directoryFlags) }
            guard child >= 0 else {
                // A directory may be observable even when its contents cannot be opened.
                var observed = stat()
                let status = component.withCString {
                    Darwin.fstatat(descriptor, $0, &observed, AT_SYMLINK_NOFOLLOW)
                }
                Darwin.close(descriptor)
                let isDirectory = status == 0 && observed.st_mode & mode_t(S_IFMT) == mode_t(S_IFDIR)
                if isDirectory && observed.st_dev != device { return .outsideVolume }
                return .unreadable(observedDirectory: isDirectory && index == components.count - 1)
            }
            Darwin.close(descriptor)
            descriptor = child
            guard let observed = metadata(descriptor: descriptor) else {
                Darwin.close(descriptor)
                return .unreadable(observedDirectory: false)
            }
            guard observed.st_dev == device else {
                Darwin.close(descriptor)
                return .outsideVolume
            }
        }
        return .opened(descriptor)
    }

    private func metadata(descriptor: Int32) -> stat? {
        var observed = stat()
        return Darwin.fstat(descriptor, &observed) == 0 ? observed : nil
    }
}
