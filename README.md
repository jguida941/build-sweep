# BuildSweep

BuildSweep is a small macOS utility built with Swift and SwiftUI for reclaiming disk space used by regenerable development files.

Working across multiple repositories, coding sessions, and AI-assisted projects can quickly leave behind Rust `target` directories, Swift `.build` directories, Xcode DerivedData, debug output, and other generated build artifacts. When you regularly move between projects, inactive build files alone can consume tens of gigabytes.

BuildSweep’s purpose is simple: identify recognized build artifacts, show how much space each one uses, and let the developer choose which items to move to Trash. Selected items are moved to Trash rather than permanently deleted, and BuildSweep is designed to target files that their original build tools can regenerate when needed.

The goal is to make reclaiming development space quick and understandable without forcing developers to make rushed decisions about unfamiliar project files.

The planned interface is a lightweight native macOS menu bar utility, making it easy to inspect and reclaim development space without interrupting your workflow.

BuildSweep is currently in early development. I am building it one feature at a time as a practical way to improve my understanding of Swift, SwiftUI, and native macOS development.
