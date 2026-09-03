# BuildSweep

BuildSweep is a local macOS utility being built with Swift and SwiftUI to find and remove regenerable development artifacts.

Its scanner is designed around deterministic, project-aware rules for identifying Rust `target` directories, Swift `.build` directories, Xcode DerivedData, and other generated build output. It will not classify directories by name alone. This avoids manual filesystem searches and model-token usage for a deterministic local task.

Before cleanup, BuildSweep will show each artifact’s toolchain, path, size, and classification evidence. The developer selects the exact items to move to Trash. Source code, project settings, and unverified directories remain outside the cleanup boundary.

The planned interface is a lightweight macOS menu bar utility that can reclaim development space without requiring directory searches or CLI commands.

## Status

BuildSweep is in early development and is being built one feature at a time while I learn Swift, SwiftUI, and native macOS development.

> **Development note:** Being developed agentically with Semloop and SemVariants. Testing and validation run locally, while private evidence and supporting artifacts remain local.
