import Combine
import Foundation

nonisolated enum CargoWorkspaceScanState: Equatable, Sendable {
    case ready
    case scanning(workspaceURL: URL)
    case found(workspaceURL: URL, finding: CargoTargetFinding)
    case refused(workspaceURL: URL, refusal: CargoTargetRefusal)
    case accessDenied(workspaceURL: URL)
    case cancelled(workspaceURL: URL)
    case importFailed(message: String)
}

/// Owns one user-started inspection and publishes only state that the view can render.
@MainActor
final class CargoWorkspaceScanModel: ObservableObject {
    @Published private(set) var state: CargoWorkspaceScanState = .ready

    private let inspector: CargoWorkspaceInspector
    private var activeScanID: UUID?
    private var scanTask: Task<Void, Never>?

    init(inspector: CargoWorkspaceInspector) {
        self.inspector = inspector
    }

    func inspect(workspaceURL: URL) {
        cancelCurrentTask()

        let selectedURL = workspaceURL.standardizedFileURL
        guard selectedURL.startAccessingSecurityScopedResource() else {
            state = .accessDenied(workspaceURL: selectedURL)
            return
        }

        let scanID = UUID()
        let inspector = self.inspector
        activeScanID = scanID
        state = .scanning(workspaceURL: selectedURL)

        // Classification and byte counting can visit many filesystem entries, so they must not run
        // on the main actor that keeps the window responsive.
        scanTask = Task.detached(priority: .userInitiated) { [weak self] in
            defer {
                selectedURL.stopAccessingSecurityScopedResource()
            }

            let result = inspector.inspect(
                workspaceRoot: selectedURL,
                shouldCancel: { Task.isCancelled }
            )
            await self?.finish(
                result,
                workspaceURL: selectedURL,
                scanID: scanID
            )
        }
    }

    func cancelInspection() {
        guard case .scanning(let workspaceURL) = state else {
            return
        }

        cancelCurrentTask()
        state = .cancelled(workspaceURL: workspaceURL)
    }

    func reportImportFailure(_ error: Error) {
        cancelCurrentTask()
        state = .importFailed(
            message: "The project chooser could not finish: \(error.localizedDescription)"
        )
    }

    private func finish(
        _ result: CargoWorkspaceInspectionResult,
        workspaceURL: URL,
        scanID: UUID
    ) {
        // Ignore a stale task that finishes after the user starts or cancels another inspection.
        guard activeScanID == scanID else {
            return
        }

        activeScanID = nil
        scanTask = nil

        switch result {
        case .found(let finding):
            state = .found(workspaceURL: workspaceURL, finding: finding)
        case .refused(let refusal):
            state = .refused(workspaceURL: workspaceURL, refusal: refusal)
        case .cancelled:
            state = .cancelled(workspaceURL: workspaceURL)
        }
    }

    private func cancelCurrentTask() {
        scanTask?.cancel()
        scanTask = nil
        activeScanID = nil
    }
}
