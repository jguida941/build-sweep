import Foundation

/// Evidence supporting a read-only Cargo target classification.
///
/// This evidence explains the finding but does not authorize removal.
nonisolated enum CargoTargetEvidence: Equatable, Sendable {
    case cargoManifestAtWorkspaceRoot
    case defaultTargetDirectoryAtWorkspaceRoot
    case canonicalCacheDirectoryTag
}

/// A read-only finding that is deliberately smaller than a cleanup candidate.
///
/// Candidate-building captures stable identity, size, scan identity, and the authorized-root
/// relationship from one scan snapshot.
nonisolated struct CargoTargetClassification: Equatable, Sendable {
    let directoryURL: URL
    let evidence: [CargoTargetEvidence]
}

/// Identifies the required observation that prevented classification.
///
/// Typed reasons keep unsafe states distinct and fail closed.
nonisolated struct CargoTargetRefusal: Equatable, Sendable {
    enum Evidence: Equatable, Sendable {
        case workspaceRoot
        case cargoManifest
        case targetDirectory
        case cacheDirectoryTag
    }

    enum Reason: Equatable, Sendable {
        case missing
        case unreadable
        case wrongType
        case symbolicLink
        case invalidSignature
    }

    let evidence: Evidence
    let location: URL
    let reason: Reason
}

/// Forces callers to handle both supported evidence and a fail-closed refusal.
nonisolated enum CargoTargetClassificationResult: Equatable, Sendable {
    case classified(CargoTargetClassification)
    case refused(CargoTargetRefusal)
}

/// Recognizes Cargo's default `<workspace>/target` layout.
///
/// The caller supplies an already-authorized workspace root. This classifier neither discovers
/// roots nor authorizes cleanup.
nonisolated struct CargoTargetClassifier: Sendable {
    // Cargo writes this standard prefix to its target cache tag. A matching directory name alone
    // is not enough evidence.
    private static let canonicalCacheTagSignature = Data(
        "Signature: 8a477f597d28d172789f06886806bc55".utf8
    )

    // Depending on observations rather than concrete macOS APIs keeps classification policy
    // independent of the UI and allows the filesystem mechanism to be tested separately.
    private let fileSystem: any FileSystemEvidenceReading

    init(fileSystem: any FileSystemEvidenceReading) {
        self.fileSystem = fileSystem
    }

    func classify(workspaceRoot: URL) -> CargoTargetClassificationResult {
        let rootURL = workspaceRoot.standardizedFileURL

        // Derive fixed children from the authorized root instead of searching for familiar names.
        let manifestURL = rootURL
            .appendingPathComponent("Cargo.toml", isDirectory: false)
            .standardizedFileURL
        let targetURL = rootURL
            .appendingPathComponent("target", isDirectory: true)
            .standardizedFileURL
        let cacheTagURL = targetURL
            .appendingPathComponent("CACHEDIR.TAG", isDirectory: false)
            .standardizedFileURL

        if let refusal = refusalForRequiredItem(
            at: rootURL,
            evidence: .workspaceRoot,
            expectedKind: .directory
        ) {
            return .refused(refusal)
        }

        if let refusal = refusalForRequiredItem(
            at: manifestURL,
            evidence: .cargoManifest,
            expectedKind: .regularFile
        ) {
            return .refused(refusal)
        }

        if let refusal = refusalForRequiredItem(
            at: targetURL,
            evidence: .targetDirectory,
            expectedKind: .directory
        ) {
            return .refused(refusal)
        }

        if let refusal = refusalForCacheTag(at: cacheTagURL) {
            return .refused(refusal)
        }

        return .classified(CargoTargetClassification(
            directoryURL: targetURL,
            evidence: [
                .cargoManifestAtWorkspaceRoot,
                .defaultTargetDirectoryAtWorkspaceRoot,
                .canonicalCacheDirectoryTag,
            ]
        ))
    }

    private func refusalForRequiredItem(
        at url: URL,
        evidence: CargoTargetRefusal.Evidence,
        expectedKind: FileSystemItemKind
    ) -> CargoTargetRefusal? {
        let reason: CargoTargetRefusal.Reason

        switch fileSystem.itemKind(at: url) {
        case .failure(.missing):
            reason = .missing
        case .failure(.unreadable):
            reason = .unreadable
        case .success(.symbolicLink):
            reason = .symbolicLink
        case .success(let actualKind) where actualKind == expectedKind:
            return nil
        case .success:
            reason = .wrongType
        }

        return CargoTargetRefusal(
            evidence: evidence,
            location: url,
            reason: reason
        )
    }

    private func refusalForCacheTag(at cacheTagURL: URL) -> CargoTargetRefusal? {
        if let refusal = refusalForRequiredItem(
            at: cacheTagURL,
            evidence: .cacheDirectoryTag,
            expectedKind: .regularFile
        ) {
            return refusal
        }

        // Read only the identifying prefix; remaining cache-tag bytes do not affect classification.
        switch fileSystem.readPrefix(
            at: cacheTagURL,
            maximumByteCount: Self.canonicalCacheTagSignature.count
        ) {
        case .failure(.missing):
            return CargoTargetRefusal(
                evidence: .cacheDirectoryTag,
                location: cacheTagURL,
                reason: .missing
            )
        case .failure(.unreadable):
            return CargoTargetRefusal(
                evidence: .cacheDirectoryTag,
                location: cacheTagURL,
                reason: .unreadable
            )
        case .success(Self.canonicalCacheTagSignature):
            return nil
        case .success:
            return CargoTargetRefusal(
                evidence: .cacheDirectoryTag,
                location: cacheTagURL,
                reason: .invalidSignature
            )
        }
    }
}
