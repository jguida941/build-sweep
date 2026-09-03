# ADR-0001: Use a menu-bar-first application shell

Status: Accepted

Date: 2026-09-03

## Context

BuildSweep is intended for a short, recurring maintenance task during development. A conventional
always-open document window would give the product more visual weight than its primary workflow
requires. Some result, confirmation, permission, and receipt states may still need more space than a
small menu bar presentation can provide.

## Decision

Use a native macOS menu-bar-first application shell. The menu bar entry is the stable starting point;
the app may present a larger native window or scene when a task needs durable space, comparison, or
accessibility that a compact presentation cannot provide.

The first implementation must use supported Apple APIs and preserve keyboard and VoiceOver access.
The exact `SwiftUI`/AppKit composition is an implementation decision until a focused prototype and
current platform guidance establish it.

## Alternatives

- **Window-only app:** familiar and spacious, but less suited to a quick utility used between coding
  tasks.
- **Menu-bar-only popover:** compact, but too restrictive if it prevents clear evidence review,
  confirmation, receipts, or accessible navigation.
- **Command-line-first product:** deterministic scanning could be shared with a CLI later, but a CLI
  does not satisfy the intended native review experience.

## Consequences

- The app shell stays thin; scanning and cleanup logic remain outside presentation code.
- Compact and expanded states must share one application workflow rather than becoming separate
  control paths.
- Window activation, menu bar behavior, accessibility, and app lifecycle require real macOS
  observation before the interface is user-accepted.

Current requirements: [PRODUCT.md](../PRODUCT.md)

Current boundaries: [ARCHITECTURE.md](../ARCHITECTURE.md)
