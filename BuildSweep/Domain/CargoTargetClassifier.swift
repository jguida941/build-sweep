import Foundation

/// The observations that justify recognizing a directory as Cargo build output.
///
/// Keeping these observations in the result lets the interface explain a classification. Evidence
/// supports a read-only finding; it does not grant permission to remove the directory.
nonisolated enum CargoTargetEvidence: Equatable, Sendable {
    case cargoManifestAtWorkspaceRoot
    case defaultTargetDirectoryAtWorkspaceRoot
    case canonicalCacheDirectoryTag
}

/// A read-only classifier finding, deliberately smaller than a cleanup candidate.
///
/// Stable filesystem identity, size, scan identity, and authorized-root relationship belong to the
/// later candidate-building stage, where they can be captured from one scan snapshot.
nonisolated struct CargoTargetClassification: Equatable, Sendable {
    let directoryURL: URL
    let evidence: [CargoTargetEvidence]
}

/// Identifies the exact required observation that prevented classification.
///
/// A typed refusal keeps missing, unreadable, linked, malformed, and wrong-kind evidence from being
/// collapsed into either an unexplained omission or a false safe result.
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

/// Recognizes only Cargo's default `<workspace>/target` layout.
///
/// The supplied workspace root is already authorized by a higher layer. This classifier neither
/// discovers roots nor authorizes cleanup; it only decides whether the expected Cargo relationship
/// is supported by current filesystem evidence.
nonisolated struct CargoTargetClassifier: Sendable {
    // Cargo places this standard prefix in cache directories. Requiring it prevents a directory
    // named `target` from being treated as generated output based on its name alone.
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

        // Only the identifying prefix is relevant to classification; arbitrary cache-tag contents
        // do not need to be loaded into memory.
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
