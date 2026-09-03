# Product requirements

Status: early product definition. These requirements describe intended behavior, not current
implementation.

## North Star

BuildSweep should make reclaiming developer disk space safer and easier to understand than manual
deletion: every proposed artifact is evidence-backed, every cleanup choice remains with the
developer, and every effect is recoverable and honestly reported.

Five principles decide product tradeoffs:

1. Evidence before action.
2. Developer review before filesystem effects.
3. Local, deterministic core behavior.
4. Native macOS clarity and accessibility.
5. Honest limits and incremental support instead of broad cleanup claims.

## How the North Star is used

This document and the linked safety and architecture documents describe BuildSweep's current
intended behavior. They guide implementation, but their presence is not evidence that a capability
works. Each development slice should connect one requirement and its safety laws to the smallest
real user-observable behavior and its ordinary product tests.

When a real product observation contradicts an assumption here, update the owning document and, for
a consequential decision, add or supersede an architectural decision record. Do not preserve stale
documentation to make an implementation appear conformant, and do not silently change product
meaning only in code or tests.

## Product outcome

BuildSweep helps a developer recover disk space used by regenerable build artifacts while keeping
the decision understandable and reversible.

The primary journey is:

1. The developer chooses where BuildSweep may inspect.
2. BuildSweep scans those locations using supported, deterministic classifiers.
3. BuildSweep presents typed candidates with size, location, toolchain, and classification evidence.
4. The developer selects the exact candidates to remove.
5. BuildSweep revalidates the selection, moves accepted items to Trash, and reports each outcome.

The [safety model](SAFETY.md) governs what may become a candidate or reach Trash. The
[architecture](ARCHITECTURE.md) defines the component boundaries that enforce this journey.

## Requirements

- **PRD-001 — Local operation:** Scanning, classification, selection, and cleanup run locally on the
  Mac. Core cleanup behavior does not require a cloud service or AI model.
- **PRD-002 — Authorized scope:** The developer can see and control the roots BuildSweep will scan.
- **PRD-003 — Supported classification:** BuildSweep presents only artifacts for which a supported
  classifier has sufficient project or toolchain evidence.
- **PRD-004 — Explainable results:** Every candidate shows its artifact type, path, size, and the
  evidence used to classify it.
- **PRD-005 — Explicit selection:** No candidate is removed until the developer selects that exact
  item and confirms the operation.
- **PRD-006 — Recoverable cleanup:** Accepted items are moved to the macOS Trash and receive a
  per-item result. BuildSweep does not permanently erase them.
- **PRD-007 — Honest state:** Empty results, denied access, cancellation, stale candidates, and
  partial failures are distinguishable from success.
- **PRD-008 — Native access:** The primary interface supports keyboard operation, VoiceOver, and
  macOS accessibility settings appropriate to the implemented controls and states.
- **PRD-009 — Responsive work:** Long scans and size calculations do not block the interface and can
  be cancelled without turning incomplete observations into cleanup candidates.

## Planned artifact coverage

Coverage is admitted incrementally. An item in this table is planned, not implemented, until its
classifier and product tests land.

| Family | Planned artifacts | Minimum evidence direction |
| --- | --- | --- |
| Rust | Cargo `target` output | A related Cargo project plus build-output evidence |
| Swift | SwiftPM `.build` output | A related Swift package plus SwiftPM build metadata |
| Xcode | DerivedData for a project or workspace | Xcode-derived metadata that binds output to its source project |
| C and C++ | Verified CMake build trees | CMake-generated metadata, not a directory name alone |
| Python | Bytecode and supported test, type-checker, and linter caches | Tool-specific cache structure within an authorized project |
| Gradle and Android | Supported generated build output | A related Gradle/Android project plus generated-output evidence |
| IDEs | Selected regenerable caches and indexes | A supported IDE-owned cache location or marker with explicit exclusions |

Adding a family requires an update to this table, the safety model, implementation, and focused
product tests. Similar-looking source or configuration directories are never admitted by analogy.

## Release stages

1. **Foundation:** native app shell, public requirements, safety boundaries, test target, and core
   domain types.
2. **Read-only scan:** authorized-root selection and evidence-backed discovery for the first Rust,
   SwiftPM, and Xcode classifiers. No cleanup is enabled in this stage.
3. **Reviewed cleanup:** exact selection, pre-operation revalidation, Trash-only movement, and
   per-item receipts.
4. **Coverage expansion:** additional language and IDE families, each admitted independently.
5. **Release readiness:** complete supported-state handling, accessibility review, performance and
   cancellation checks, packaging, and a user-accepted native experience.

Each stage must be usable and honestly labeled. Planned coverage must not appear as supported in the
app or public release notes before it is implemented and tested.

## Non-goals

BuildSweep is not:

- a general-purpose disk cleaner;
- a permanent-deletion or secure-erasure tool;
- a source-code, dependency, workspace-setting, or editor-configuration cleaner;
- a replacement for a build tool's own clean command;
- an automatic background deletion service;
- a runtime AI classifier for deciding whether a path is safe;
- a promise that every developer cache or every version of a supported tool is recognized.

## Product completion

Use these terms without collapsing one into another:

- **planned:** the capability appears in product or architecture documents;
- **implemented:** production code exists in the current checkout;
- **test-exercised:** named product tests executed against that checkout;
- **user-accepted:** the declared user task and visual question were accepted on a named build and
  macOS environment;
- **release-accepted:** every requirement in the capability's declared release stage has the
  required implementation, test, safety, accessibility, and user evidence.

A capability is complete only when its public requirement and safety laws are implemented, its
ordinary product tests pass, its relevant UI states are observable, and remaining limits are stated.
The current prototype does not yet meet those conditions for any cleanup capability.

## Product success signals

Release planning should measure candidate precision on declared fixtures, dangerous near-miss
refusals, scan time and cancellation, independently observed Trash outcomes, unresolved partial
failures, task completion with keyboard and VoiceOver, and whether developers can understand why an
item was proposed. Targets belong to the release stage that can measure them; this document does not
invent numbers before a representative corpus and baseline exist.

## Decisions before implementation expands

The first vertical slice should settle, in order:

1. the menu bar presentation and when a larger window is necessary;
2. the authorized-root selection and macOS access model;
3. the first classifier and its minimum evidence predicate;
4. the stable filesystem identity available across scan and cleanup;
5. receipt lifetime and the amount of path information safe to retain.

Consequential choices receive a short record in [architectural decisions](decisions/README.md).
