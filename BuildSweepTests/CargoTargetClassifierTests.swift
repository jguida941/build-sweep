import XCTest
@testable import BuildSweep

final class CargoTargetClassifierTests: XCTestCase {
    func testRefusesSameNamedTargetWithoutCargoCacheTag() throws {
        let workspaceURL = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspaceURL) }

        try Data("[package]\nname = \"Example\"\n".utf8)
            .write(to: workspaceURL.appendingPathComponent("Cargo.toml"))
        try FileManager.default.createDirectory(
            at: workspaceURL.appendingPathComponent("target", isDirectory: true),
            withIntermediateDirectories: false
        )

        let result = CargoTargetClassifier(fileSystem: LocalFileSystemEvidenceReader())
            .classify(workspaceRoot: workspaceURL)

        XCTAssertEqual(
            result,
            .refused(CargoTargetRefusal(
                evidence: .cacheDirectoryTag,
                location: workspaceURL
                    .appendingPathComponent("target", isDirectory: true)
                    .appendingPathComponent("CACHEDIR.TAG")
                    .standardizedFileURL,
                reason: .missing
            )),
            "A same-named target without Cargo's cache tag must be refused."
        )
    }

    func testClassifiesDefaultCargoTargetWhenRequiredEvidenceIsPresent() throws {
        let workspaceURL = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: workspaceURL) }

        try Data("[package]\nname = \"Example\"\n".utf8)
            .write(to: workspaceURL.appendingPathComponent("Cargo.toml"))
        let targetURL = workspaceURL
            .appendingPathComponent("target", isDirectory: true)
            .standardizedFileURL
        try FileManager.default.createDirectory(
            at: targetURL,
            withIntermediateDirectories: false
        )
        try Data("Signature: 8a477f597d28d172789f06886806bc55\n".utf8)
            .write(to: targetURL.appendingPathComponent("CACHEDIR.TAG"))

        let result = CargoTargetClassifier(fileSystem: LocalFileSystemEvidenceReader())
            .classify(workspaceRoot: workspaceURL)

        XCTAssertEqual(
            result,
            .classified(CargoTargetClassification(
                directoryURL: targetURL,
                evidence: [
                    .cargoManifestAtWorkspaceRoot,
                    .defaultTargetDirectoryAtWorkspaceRoot,
                    .canonicalCacheDirectoryTag,
                ]
            )),
            "A default Cargo target with all required evidence must be classified."
        )
    }

    private func makeWorkspace() throws -> URL {
        let workspaceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BuildSweepTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workspaceURL,
            withIntermediateDirectories: false
        )
        return workspaceURL.standardizedFileURL
    }
}
