import Darwin
import Foundation

nonisolated struct LocalFileSystemEvidenceReader: FileSystemEvidenceReading {
    func itemKind(at url: URL) -> Result<FileSystemItemKind, FileSystemEvidenceReadError> {
        guard url.isFileURL else {
            return .failure(.unreadable)
        }

        var metadata = stat()
        let outcome = url.withUnsafeFileSystemRepresentation { representation in
            guard let representation else {
                return (status: Int32(-1), error: Int32(EINVAL))
            }

            let status = Darwin.lstat(representation, &metadata)
            return (status: status, error: status == 0 ? 0 : errno)
        }

        guard outcome.status == 0 else {
            return .failure(readError(for: outcome.error))
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

        let outcome = url.withUnsafeFileSystemRepresentation { representation in
            guard let representation else {
                return (descriptor: Int32(-1), error: Int32(EINVAL))
            }

            let descriptor = Darwin.open(representation, O_RDONLY | O_CLOEXEC | O_NOFOLLOW)
            return (descriptor: descriptor, error: descriptor >= 0 ? 0 : errno)
        }

        guard outcome.descriptor >= 0 else {
            return .failure(readError(for: outcome.error))
        }
        defer { Darwin.close(outcome.descriptor) }

        var metadata = stat()
        guard Darwin.fstat(outcome.descriptor, &metadata) == 0,
              metadata.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            return .failure(.unreadable)
        }

        guard maximumByteCount > 0 else {
            return .success(Data())
        }

        var bytes = [UInt8](repeating: 0, count: maximumByteCount)
        let bytesRead = Darwin.read(outcome.descriptor, &bytes, maximumByteCount)
        guard bytesRead >= 0 else {
            return .failure(.unreadable)
        }

        return .success(Data(bytes.prefix(Int(bytesRead))))
    }

    private func readError(for error: Int32) -> FileSystemEvidenceReadError {
        switch error {
        case ENOENT, ENOTDIR:
            return .missing
        default:
            return .unreadable
        }
    }
}
