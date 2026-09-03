import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: CargoWorkspaceScanModel
    @State private var isChoosingProject = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            Divider()

            ScrollView {
                stateContent
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
            Label(
                "Read-only inspection. Nothing can be removed in this version.",
                systemImage: "eye"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 420)
        .fileImporter(
            isPresented: $isChoosingProject,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: handleImport
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("BuildSweep")
                    .font(.largeTitle.bold())
                Text("Inspect one Cargo project’s build output.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if case .scanning = model.state {
                Button("Cancel", role: .cancel) {
                    model.cancelInspection()
                }
            } else {
                chooseProjectButton
            }
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        switch model.state {
        case .ready:
            readyView
        case .scanning(let workspaceURL):
            scanningView(workspaceURL: workspaceURL)
        case .found(let workspaceURL, let finding):
            CargoTargetFindingView(
                workspaceURL: workspaceURL,
                finding: finding
            )
        case .refused(_, let refusal):
            CargoTargetRefusalView(refusal: refusal)
        case .accessDenied(let workspaceURL):
            messageView(
                title: "Access needed",
                symbol: "lock",
                message: "BuildSweep could not read \(workspaceURL.lastPathComponent). Choose it again and approve read access."
            )
        case .cancelled:
            messageView(
                title: "Inspection cancelled",
                symbol: "xmark.circle",
                message: "No result was created, and nothing was changed."
            )
        case .importFailed(let message):
            messageView(
                title: "Couldn’t choose that project",
                symbol: "exclamationmark.triangle",
                message: message
            )
        }
    }

    private var readyView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Choose a Cargo project", systemImage: "folder")
                .font(.title2.bold())
            Text(
                "Select the folder that contains Cargo.toml. BuildSweep will check only its default target directory."
            )
            .foregroundStyle(.secondary)
            chooseProjectButton
        }
        .padding(.vertical, 12)
    }

    private func scanningView(workspaceURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView()
                .controlSize(.large)
                .accessibilityLabel("Inspecting Cargo project")
            Text("Inspecting \(workspaceURL.lastPathComponent)…")
                .font(.title2.bold())
            Text("Checking Cargo evidence and estimating allocated storage.")
                .foregroundStyle(.secondary)
            PathText(url: workspaceURL)
        }
        .padding(.vertical, 12)
    }

    private func messageView(
        title: String,
        symbol: String,
        message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.title2.bold())
            Text(message)
                .foregroundStyle(.secondary)
            chooseProjectButton
        }
        .padding(.vertical, 12)
    }

    private var chooseProjectButton: some View {
        Button("Choose Cargo Project…") {
            isChoosingProject = true
        }
        .keyboardShortcut("o", modifiers: .command)
        .accessibilityLabel("Choose Cargo Project")
        .accessibilityHint("Opens the system folder chooser.")
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let workspaceURL = urls.first else {
                return
            }
            model.inspect(workspaceURL: workspaceURL)
        case .failure(let error):
            let cocoaError = error as NSError
            guard !(
                cocoaError.domain == NSCocoaErrorDomain
                    && cocoaError.code == NSUserCancelledError
            ) else {
                return
            }
            model.reportImportFailure(error)
        }
    }
}

private struct CargoTargetFindingView: View {
    let workspaceURL: URL
    let finding: CargoTargetFinding

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Supported Cargo build output", systemImage: "shippingbox")
                .font(.title2.bold())

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                GridRow {
                    Text("Type")
                        .foregroundStyle(.secondary)
                    Text("Cargo target")
                }
                GridRow {
                    Text(sizeLabel)
                        .foregroundStyle(.secondary)
                    Text(sizeValue)
                        .fontWeight(.semibold)
                }
                GridRow {
                    Text("Project")
                        .foregroundStyle(.secondary)
                    Text(workspaceURL.lastPathComponent)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Location")
                    .font(.headline)
                PathText(url: finding.classification.directoryURL)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Why BuildSweep recognizes it")
                    .font(.headline)
                ForEach(
                    Array(finding.classification.evidence.enumerated()),
                    id: \.offset
                ) { _, evidence in
                    Label(evidence.displayName, systemImage: "checkmark")
                }
            }

            Text(sizeExplanation)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var sizeLabel: String {
        switch finding.size {
        case .complete:
            "Estimated size"
        case .partial:
            "Partial estimate"
        case .unavailable:
            "Size"
        case .cancelled:
            "Size"
        }
    }

    private var sizeValue: String {
        switch finding.size {
        case .complete(let byteCount), .partial(let byteCount):
            ByteCountFormatter.string(
                fromByteCount: Int64(clamping: byteCount),
                countStyle: .file
            )
        case .unavailable:
            "Unavailable"
        case .cancelled:
            "Cancelled"
        }
    }

    private var sizeExplanation: String {
        switch finding.size {
        case .complete:
            "The estimate uses allocated filesystem blocks. APFS sharing can make the space eventually reclaimed differ."
        case .partial:
            "Some entries could not be measured or were outside the selected filesystem, so this estimate is incomplete."
        case .unavailable:
            "BuildSweep recognized the target but could not measure its storage."
        case .cancelled:
            "The size calculation was cancelled."
        }
    }
}

private struct CargoTargetRefusalView: View {
    let refusal: CargoTargetRefusal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("No supported Cargo target", systemImage: "questionmark.folder")
                .font(.title2.bold())
            Text(
                "BuildSweep could not verify \(refusal.evidence.displayName) because \(refusal.reason.displayExplanation)."
            )
            .foregroundStyle(.secondary)
            PathText(url: refusal.location)
        }
        .padding(.vertical, 12)
    }
}

private struct PathText: View {
    let url: URL

    var body: some View {
        Text(url.path)
            .font(.system(.callout, design: .monospaced))
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .accessibilityLabel("Path")
            .accessibilityValue(url.path)
    }
}

private extension CargoTargetEvidence {
    var displayName: String {
        switch self {
        case .cargoManifestAtWorkspaceRoot:
            "Cargo.toml is at the project root"
        case .defaultTargetDirectoryAtWorkspaceRoot:
            "target is in Cargo’s default location"
        case .canonicalCacheDirectoryTag:
            "Cargo’s canonical cache tag is present"
        }
    }
}

private extension CargoTargetRefusal.Evidence {
    var displayName: String {
        switch self {
        case .workspaceRoot:
            "the selected project folder"
        case .cargoManifest:
            "Cargo.toml at the project root"
        case .targetDirectory:
            "the default target directory"
        case .cacheDirectoryTag:
            "Cargo’s cache tag"
        }
    }
}

private extension CargoTargetRefusal.Reason {
    var displayExplanation: String {
        switch self {
        case .missing:
            "it is missing"
        case .unreadable:
            "it could not be read"
        case .wrongType:
            "it is not the required file or folder"
        case .symbolicLink:
            "it is a symbolic link"
        case .invalidSignature:
            "its signature does not match Cargo’s canonical cache tag"
        }
    }
}

#Preview("Ready") {
    ContentView(
        model: CargoWorkspaceScanModel(
            inspector: CargoWorkspaceInspector(
                classifier: CargoTargetClassifier(
                    fileSystem: LocalFileSystemEvidenceReader()
                ),
                sizeMeasurer: LocalDirectorySizeMeasurer()
            )
        )
    )
}
