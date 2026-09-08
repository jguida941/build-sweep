import Foundation

/// Keeps inventory failures distinct from evidence that could not be classified.
nonisolated enum CargoWorkspaceScanIssue: Equatable, Sendable {
    case inventory(DirectoryInventoryIssue)
    case classification(CargoTargetRefusal)
}

nonisolated enum CargoWorkspaceScanResult: Equatable, Sendable {
    case complete(findings: [CargoTargetFinding])
    case partial(findings: [CargoTargetFinding], issues: [CargoWorkspaceScanIssue])
    case cancelled
    case failed(issue: DirectoryInventoryIssue)
}

/// Collects read-only Cargo findings without creating selection or cleanup authority.
nonisolated struct CargoWorkspaceScanner: Sendable {
    private let directoryInventory: any DirectoryInventoryReading
    private let inspector: CargoWorkspaceInspector

    init(
        directoryInventory: any DirectoryInventoryReading,
        inspector: CargoWorkspaceInspector
    ) {
        self.directoryInventory = directoryInventory
        self.inspector = inspector
    }

    func scan(
        authorizedRoot: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> CargoWorkspaceScanResult {
        switch directoryInventory.inventoryDirectories(
            under: authorizedRoot,
            shouldCancel: shouldCancel
        ) {
        case .complete(let directories):
            return inspect(
                directories: directories,
                issues: [],
                shouldCancel: shouldCancel
            )
        case .partial(let directories, let issues):
            return inspect(
                directories: directories,
                issues: issues.map(CargoWorkspaceScanIssue.inventory),
                shouldCancel: shouldCancel
            )
        case .cancelled:
            return .cancelled
        case .failed(let issue):
            return .failed(issue: issue)
        }
    }

    private func inspect(
        directories: [URL],
        issues: [CargoWorkspaceScanIssue],
        shouldCancel: @Sendable () -> Bool
    ) -> CargoWorkspaceScanResult {
        var findings: [CargoTargetFinding] = []
        var scanIssues = issues

        for directoryURL in directories {
            switch inspector.inspect(
                workspaceRoot: directoryURL,
                shouldCancel: shouldCancel
            ) {
            case .found(let finding):
                findings.append(finding)
            case .refused(let refusal):
                if refusal.reason == .unreadable {
                    scanIssues.append(.classification(refusal))
                }
            case .cancelled:
                return .cancelled
            }
        }

        if scanIssues.isEmpty {
            return .complete(findings: findings)
        }
        return .partial(findings: findings, issues: scanIssues)
    }
}
