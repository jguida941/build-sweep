import Foundation

/// A read-only finding for display before BuildSweep has a cleanup-candidate model.
nonisolated struct CargoTargetFinding: Equatable, Sendable {
    let classification: CargoTargetClassification
    let size: DirectorySizeMeasurement
}

nonisolated enum CargoWorkspaceInspectionResult: Equatable, Sendable {
    case found(CargoTargetFinding)
    case refused(CargoTargetRefusal)
    case cancelled
}

/// Joins Cargo classification and size observation without granting cleanup authority.
nonisolated struct CargoWorkspaceInspector: Sendable {
    private let classifier: CargoTargetClassifier
    private let sizeMeasurer: any DirectorySizeMeasuring

    init(
        classifier: CargoTargetClassifier,
        sizeMeasurer: any DirectorySizeMeasuring
    ) {
        self.classifier = classifier
        self.sizeMeasurer = sizeMeasurer
    }

    func inspect(
        workspaceRoot: URL,
        shouldCancel: @Sendable () -> Bool
    ) -> CargoWorkspaceInspectionResult {
        guard !shouldCancel() else {
            return .cancelled
        }

        switch classifier.classify(workspaceRoot: workspaceRoot) {
        case .refused(let refusal):
            return .refused(refusal)
        case .classified(let classification):
            guard !shouldCancel() else {
                return .cancelled
            }

            let size = sizeMeasurer.measureDirectory(
                at: classification.directoryURL,
                shouldCancel: shouldCancel
            )
            if size == .cancelled {
                return .cancelled
            }

            return .found(CargoTargetFinding(
                classification: classification,
                size: size
            ))
        }
    }
}
