# BuildSweep

BuildSweep is a local macOS utility being built with Swift and SwiftUI to find and remove
regenerable development artifacts.

Build outputs and tool caches accumulate across repositories and can consume substantial disk space.
BuildSweep's planned scanner uses deterministic, project-aware rules so a developer can reclaim
that space without repeated filesystem searches or model-token usage for a deterministic local
task. A familiar directory name by itself is never enough to authorize cleanup.

The planned product shows each candidate's toolchain, location, size, and classification evidence.
The developer chooses the exact candidates to move to Trash, where they remain recoverable until the
Trash is emptied.

The first useful cleanup release prioritizes Rust, Swift, and Xcode. Python caches, Java and
Android build output, C and C++, JavaScript, and selected IDE caches follow. Virtual environments
are planned for informational inventory before any separately supported cleanup rule. Source code, workspace settings, editor rules, and user-authored IDE
configuration stay outside the cleanup boundary.

The planned native interfaces share one workflow: a menu bar control panel, Dock quick actions,
a review window, and a desktop/Notification Center widget with Scan and Review actions. Approved
locations are remembered so repeated scans do not require selecting every project again.

## Status

BuildSweep is in early development. Its first read-only slice can inspect one Cargo project chosen
through the native macOS folder picker. It recognizes the project's default `target` directory only
when the Cargo manifest, default location, and canonical cache tag are present, then shows the path,
an allocated-size estimate, and the evidence behind the result.

BuildSweep does not yet search across multiple projects or remove anything. Broader artifact
coverage, reviewed selection, revalidation, Trash movement, and receipts remain planned. The
current app targets macOS 13 and later; release validation on supported macOS versions is still
required.

## Documentation

- [Product requirements](docs/PRODUCT.md)
- [Safety model](docs/SAFETY.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Architectural decisions](docs/decisions/README.md)
