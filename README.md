# BuildSweep

BuildSweep is a small macOS utility built with Swift and SwiftUI for cleaning up regenerable development files.

Working across multiple projects and coding sessions can leave behind Rust `target` folders, Swift `.build` folders, Xcode build data, debug output, and other generated files. A handful of inactive projects can easily consume tens of gigabytes.

BuildSweep finds this development junk, shows how much space it uses, and lets you move selected items to Trash. If you return to a project later, its build tools can regenerate those files.

BuildSweep is currently in early development and is also a project for learning Swift and SwiftUI.
