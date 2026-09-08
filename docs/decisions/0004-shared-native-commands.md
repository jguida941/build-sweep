# ADR-0004: Share commands across native entry points

Status: Accepted

Date: 2026-09-08

## Context

The menu-bar-first shell in ADR-0001 provides a convenient entry but currently only opens the Cargo
inspector. Useful maintenance also needs quick scan actions, readable comparison, and a glanceable
widget. Independent state in each surface would make cancellation, permissions, and results diverge.

## Decision

Extend [ADR-0001](0001-menu-bar-first-interface.md) with one startup-owned command layer shared by
the main window, menu bar, Dock menu, and WidgetKit routing. Keep ordinary Dock presence. Use a
native compact menu panel for status and frequent actions, and the main window for detailed review,
permission changes, and cleanup confirmation. Start the widget with the medium family and Scan and
Review actions; the app owns actual scanning and all filesystem authority.

This accepts a design direction. The additional commands and widget are not yet implemented.

## Alternatives

- Separate workflow models per interface make permission and freshness decisions inconsistent.
- A menu with only Open and Quit does not provide useful maintenance actions.
- Putting the complete cleanup review inside a widget makes exact selection difficult to inspect.

## Consequences

Initialize shared state before cold-launch commands arrive. Coalesce equivalent scan requests and
preserve snapshot age through cancellation. Share only a qualified summary with the widget, with
availability paths for the macOS 13 app floor. Verify actual widget packaging, keyboard access,
VoiceOver, and window activation before describing those surfaces as supported.

Apple provides the native [menu panel](https://developer.apple.com/documentation/swiftui/menubarextra),
[Dock menu](https://developer.apple.com/design/human-interface-guidelines/dock-menus), and
[widget](https://developer.apple.com/design/human-interface-guidelines/widgets) roles. BuildSweep's
specific command set and medium-widget priority are product choices.

Current requirements: [PRODUCT.md](../PRODUCT.md)

Current boundaries: [ARCHITECTURE.md](../ARCHITECTURE.md)
