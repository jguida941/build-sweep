import AppKit
import SwiftUI

@main
struct BuildSweepApp: App {
    @NSApplicationDelegateAdaptor(BuildSweepAppDelegate.self) private var appDelegate
    @StateObject private var scanModel = CargoWorkspaceScanModel(
        inspector: CargoWorkspaceInspector(
            classifier: CargoTargetClassifier(
                fileSystem: LocalFileSystemEvidenceReader()
            ),
            sizeMeasurer: LocalDirectorySizeMeasurer()
        )
    )

    var body: some Scene {
        Window("BuildSweep", id: "inspector") {
            ContentView(model: scanModel)
        }
        .defaultSize(width: 620, height: 520)

        MenuBarExtra("BuildSweep", systemImage: "internaldrive") {
            BuildSweepMenu()
        }
    }
}

private final class BuildSweepAppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        // The inspector may close while the menu-bar entry remains the app's persistent front door.
        false
    }
}

private struct BuildSweepMenu: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open BuildSweep") {
            openWindow(id: "inspector")
        }

        Divider()

        Button("Quit BuildSweep") {
            NSApplication.shared.terminate(nil)
        }
    }
}
