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

Initial coverage is planned for Rust, Swift and Xcode, C and C++, Python, Gradle and Android, and
selected IDE-generated caches. Source code, workspace settings, editor rules, and user-authored IDE
configuration stay outside the cleanup boundary.

The planned interface is a lightweight native macOS menu bar utility for reclaiming development
space without directory searches or CLI cleanup commands.

## Status

BuildSweep is in early development. The current app is an Xcode-generated SwiftUI prototype; the
scanner and cleanup workflow described above are not implemented yet. I am building it one feature
at a time while learning Swift, SwiftUI, and native macOS development.

## Documentation

- [Product requirements](docs/PRODUCT.md)
- [Safety model](docs/SAFETY.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Architectural decisions](docs/decisions/README.md)
