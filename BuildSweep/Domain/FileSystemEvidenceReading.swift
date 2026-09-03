import Foundation

nonisolated enum FileSystemItemKind: Equatable, Sendable {
    case regularFile
    case directory
    case symbolicLink
    case other
}

nonisolated enum FileSystemEvidenceReadError: Error, Equatable, Sendable {
    case missing
    case unreadable
}

nonisolated protocol FileSystemEvidenceReading: Sendable {
    func itemKind(at url: URL) -> Result<FileSystemItemKind, FileSystemEvidenceReadError>
    func readPrefix(
        at url: URL,
        maximumByteCount: Int
    ) -> Result<Data, FileSystemEvidenceReadError>
}
