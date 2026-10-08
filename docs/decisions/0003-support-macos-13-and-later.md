# ADR-0003: Support macOS 13 and later

Status: Accepted

Date: 2026-09-03

## Context

The initial Xcode template inherited the development Mac's macOS 26.2 deployment target. That would
make the app needlessly specific to one current machine. BuildSweep is a Mac-native utility and
should have one explicit compatibility floor that preserves its menu-bar-first design.

The initial interface uses SwiftUI `MenuBarExtra`, `Window`, `Grid`, and `defaultSize`. Apple's
macOS 26.2 SDK declares each of these APIs available in macOS 13 or earlier, with `MenuBarExtra`,
`Window`, and `Grid` making macOS 13 the narrowest shared floor.

## Decision

BuildSweep supports macOS 13 and later. New product code must either use APIs available at that
floor or add a focused availability path whose behavior can be verified.

The product remains macOS-only. Supporting macOS 13 does not create iOS, iPadOS, Windows, or Linux
application targets.

## Alternatives

- **Keep the template's macOS 26.2 target:** easiest on the development Mac, but it excludes other
  compatible Macs for no product reason.
- **Support macOS 12 with an AppKit menu-bar fallback:** broader reach, but it creates a second shell
  path before the first workflow is mature.
- **Use a newer floor:** reduces validation work, but gives up compatible Macs without a required
  framework or product benefit.

## Consequences

- The same SwiftUI shell can run on Intel and Apple Silicon Macs that support macOS 13 or later.
- Generic release builds must compile both standard Mac architectures.
- Building against a current SDK does not prove behavior on every supported OS. Release acceptance
  still requires named older-macOS observations.
- Future framework additions must be checked against this floor instead of silently raising it.

Current requirements: [PRODUCT.md](../PRODUCT.md)

Current architecture: [ARCHITECTURE.md](../ARCHITECTURE.md)

Apple reference: [MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
