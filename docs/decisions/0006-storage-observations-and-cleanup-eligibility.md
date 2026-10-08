# ADR-0006: Separate storage observations from cleanup eligibility

Status: Accepted

Date: 2026-09-20

## Context

Development storage includes build output, shared caches, temporary working copies and retained
results. A classifier-only view can conceal large unsupported items. Conversely, equal contents or
an old directory name cannot determine whether a path is needed by a project or preserves unique
history. A clean working tree does not settle the purpose of ignored data.

## Decision

Extend the planned storage view with qualified informational observations and read-only duplicate
comparison. Keep them separate from supported artifacts and selectable cleanup candidates. Add
project/tool use and recovery evidence only for explicitly supported layouts, with unknowns visible.
Duplicate removal requires its own supported rule; existing source and record exclusions remain.

Retain the shared inventory, command owner and Trash pipeline. Do not execute arbitrary projects,
build a second scanner, or automatically replace independent files with links. General archival and
compaction remain deferred. This is a design decision, not delivered functionality.

## Alternatives

- Showing only recognized artifacts obscures unsupported storage and incomplete coverage.
- Treating content matches as removable ignores required paths, metadata and future independent writes.
- Guessing use from age, process absence or an unrestricted source search cannot establish recovery.
- Copying complete trees for each scan would add to the storage problem the application addresses.

## Consequences

Selection cannot be constructed from informational rows. Bound comparison work, preserve incomplete outcomes and
revalidate any future kept/removed relationship before effects. Show allocation estimates without
promising exclusive recovery: [Apple File System](https://developer.apple.com/documentation/foundation/about-apple-file-system)
supports storage sharing between clones.

Current requirements: [PRODUCT.md](../PRODUCT.md)

Current safety laws: [SAFETY.md](../SAFETY.md)

Current component boundaries: [ARCHITECTURE.md](../ARCHITECTURE.md)
