import Darwin
import Foundation

nonisolated struct LocalFileSystemEvidenceReader: FileSystemEvidenceReading {
    func itemKind(at url: URL) -> Result<FileSystemItemKind, FileSystemEvidenceReadError> {
        guard url.isFileURL else {
            return .failure(.unreadable)
        }

        var metadata = stat()
        let lstatResult = url.withUnsafeFileSystemRepresentation { representation in
            guard let representation else {
                return (status: Int32(-1), errorNumber: Int32(EINVAL))
            }

            // Use lstat so a symbolic link at the final path component is reported, not followed.
            let status = Darwin.lstat(representation, &metadata)
            return (status: status, errorNumber: status == 0 ? 0 : errno)
        }

        guard lstatResult.status == 0 else {
            return .failure(readError(for: lstatResult.errorNumber))
        }

        switch metadata.st_mode & mode_t(S_IFMT) {
        case mode_t(S_IFREG):
            return .success(.regularFile)
        case mode_t(S_IFDIR):
            return .success(.directory)
        case mode_t(S_IFLNK):
            return .success(.symbolicLink)
        default:
            return .success(.other)
        }
    }

    func readPrefix(
        at url: URL,
        maximumByteCount: Int
    ) -> Result<Data, FileSystemEvidenceReadError> {
        guard url.isFileURL, maximumByteCount >= 0 else {
            return .failure(.unreadable)
        }

        let openResult = url.withUnsafeFileSystemRepresentation { representation in
            guard let representation else {
                return (descriptor: Int32(-1), errorNumber: Int32(EINVAL))
            }

            // Refuse a symbolic link at the final path component.
            let descriptor = Darwin.open(representation, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
            return (descriptor: descriptor, errorNumber: descriptor >= 0 ? 0 : errno)
        }

        guard openResult.descriptor >= 0 else {
            return .failure(readError(for: openResult.errorNumber))
        }
        defer { Darwin.close(openResult.descriptor) }

        var metadata = stat()
        // Check the opened descriptor so replacing the path cannot bypass the regular-file rule.
        guard Darwin.fstat(openResult.descriptor, &metadata) == 0,
              metadata.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            return .failure(.unreadable)
        }

        guard maximumByteCount > 0 else {
            return .success(Data())
        }

        var bytes = [UInt8](repeating: 0, count: maximumByteCount)
        let bytesRead = Darwin.read(openResult.descriptor, &bytes, maximumByteCount)
        guard bytesRead >= 0 else {
            return .failure(.unreadable)
        }

        return .success(Data(bytes.prefix(Int(bytesRead))))
    }

    private func readError(for errorNumber: Int32) -> FileSystemEvidenceReadError {
        switch errorNumber {
        case ENOENT, ENOTDIR:
            return .missing
        default:
            return .unreadable
        }
    }
}
