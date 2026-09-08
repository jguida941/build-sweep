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
real user-observable behavior.

When a real product observation contradicts an assumption here, update the owning document and, for
a consequential decision, add or supersede an architectural decision record. Do not preserve stale
documentation to make an implementation appear conformant, and do not silently change product
meaning only in implementation.

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
- **PRD-002 — Authorized scope:** The developer can approve, remember, disable, and remove scan
  locations. Inspection remains within the currently approved roots.
- **PRD-003 — Supported classification:** BuildSweep presents only artifacts for which a supported
  classifier has sufficient project or toolchain evidence.
- **PRD-004 — Explainable results:** Every candidate shows its artifact type, path, size, and the
  evidence used to classify it, including known regeneration requirements and limits.
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
classifier is present and its required evidence and refusal behavior have been demonstrated.

| Family | Planned artifacts | Minimum evidence direction |
| --- | --- | --- |
| Rust | Cargo `target` output | A related Cargo project plus build-output evidence |
| Swift | Generated output within SwiftPM `.build` | Swift package and build metadata; preserve source-bearing checkouts and unknown contents |
| Xcode | Generated build output within project or workspace DerivedData | Xcode-derived metadata binding output to its project; preserve archives, source packages, and unrelated state |
| Python | Bytecode and supported test, type-checker, and linter caches | Tool-specific cache structure within an authorized project |
| Java and Android | Supported Gradle and Maven build output | Related build definitions and generated-output evidence |
| C and C++ | Verified CMake build trees | CMake-generated metadata, not a directory name alone |
| JavaScript and other tools | Selected generated output and tool caches | A separately supported tool-owned layout with source and dependency exclusions |
| IDEs | Selected regenerable caches and indexes | A supported IDE-owned cache location or marker with explicit exclusions |
| Python environments | Informational environment inventory first | Environment metadata; cleanup remains unavailable until a separate recreation rule is supported |

Adding a family requires an update to this table, the safety model, its implementation, and evidence
that dangerous near misses are refused. Similar-looking source or configuration directories are
never admitted by analogy.

## Read-only discovery boundary

The planned scan accepts several locations approved through the native macOS chooser and remembers
those grants for later scans. The developer can review, disable, remove, and reauthorize locations.
Suggested project and developer-cache locations confer no access until explicitly approved. There
is no default whole-Mac scan and no automatic expansion into paths mentioned by project metadata.

Scans start on demand and remain cancellable. Results arrive incrementally, preserve denied and
unreadable locations, and distinguish exhausted resource limits from a complete empty scan.
Overlapping roots and artifact directories must not duplicate findings or inflate their totals.
Scope completeness and each item's size completeness remain separate observations. Timestamps
alone never establish that an artifact is unused.

Discovery produces inspection results only. It does not select an artifact, authorize cleanup, or
weaken later revalidation. Informational environments and unsupported near misses remain distinct
from supported cleanup candidates. The current app still inspects one selected Cargo project;
remembered locations and this broader presentation remain planned.

## Native interfaces

Four entry points share the same application commands and results:

| Surface | Purpose | Planned actions |
| --- | --- | --- |
| Menu bar | Compact status and frequent actions | Scan Saved Locations, Cancel Scan, Review Results, Manage Locations, Settings, Quit |
| Dock | Quick access when the window is not frontmost | Scan Saved Locations, Cancel Scan, Review Results |
| Widget | Glanceable summary and focused actions | Scan Now and Review; medium WidgetKit family first |
| Main window | Comparison, explanations, permissions, and cleanup review | Locations sidebar, size-sorted results, details, search/filter, keep/exclude, Reveal in Finder, exact selection and confirmation |

The menu bar shows the latest estimate, its observation time, and scan status in a native compact
panel. The widget shows the same qualified summary, with clear stale, partial, and unavailable
states. Its gallery preview must describe actual supported functionality. A widget action may open
the app to start a scan or resolve permission; the widget does not perform filesystem work itself.

Starting the same scan from another surface reveals the current attempt instead of restarting it.
Changing or revoking scan authority invalidates affected work. Closing the window leaves an accepted
scan running; explicitly quitting cancels read-only work. A cancelled new attempt does not make an
older displayed result appear freshly measured. Cleanup confirmation remains in the main window.

Native controls, keyboard navigation, VoiceOver, contrast, and readable long paths are required on
each implemented surface. The app retains macOS 13 support; newer widget capabilities use explicit
availability paths. See [the shared-command decision](decisions/0004-shared-native-commands.md).

## Storage and regeneration information

Show estimated artifact size, bytes observed moved to Trash, and current available disk capacity as
different quantities. Allocated-size estimates do not promise unique physical space reclaimed,
particularly with shared storage. A Trash move alone must never increase a freed-space counter.
Provide Open Trash for the developer's final Finder action; BuildSweep does not empty the Trash.

Explain known rebuild or download requirements without executing project scripts. A requirements
file or lockfile alone does not prove that an environment can be recreated: interpreter
availability, resolved dependencies, editable/local packages, and user-added contents matter.
Virtual environments remain informational until an independently supported rule addresses these
conditions. Scanning them is not permission to remove them.

## Delivery milestones

1. **Bounded discovery:** finish containment and incomplete-observation behavior, then incremental
   traversal, pruning, and overlap handling while preserving existing Cargo recognition.
2. **Remembered locations and results:** approved saved locations, one shared scan snapshot,
   incremental results, per-location issues, and a native comparison window.
3. **Useful menu and Dock commands:** connect quick actions to that same workflow and preserve
   startup, cancellation, and window activation behavior.
4. **Apple coverage:** add SwiftPM and Xcode separately, admitting only supported generated subtrees.
5. **Reviewed cleanup:** exact selection, deliberate write access, identity revalidation, native
   Trash movement, and independently observed per-item receipts; enable each family separately.
6. **Widget:** package the medium widget with qualified summaries, Scan and Review actions, gallery
   appearance, cold-launch routing, and accessibility.
7. **Coverage expansion:** Python caches and Java build output, followed by C/C++, JavaScript, IDE,
   and other tool caches. Conditional environment cleanup is a separate capability.
8. **Release readiness:** verify supported macOS behavior, accessibility, responsiveness,
   cancellation, packaging, and the user-facing review and receipt experience.

The first useful cleanup release prioritizes Apple toolchains and the existing Rust family. Each
milestone remains planned until implemented and observed; partial delivery must be labeled honestly.
The current prototype has no cleanup capability.

## Non-goals

BuildSweep is not:

- a general-purpose disk cleaner;
- a permanent-deletion or secure-erasure tool;
- a source-code, arbitrary dependency, workspace-setting, or editor-configuration cleaner;
- a replacement for a build tool's own clean command;
- an automatic background deletion service;
- a runtime AI classifier for deciding whether a path is safe;
- a promise that every developer cache or every version of a supported tool is recognized.

## Product completion

Use these terms without collapsing one into another:

- **planned:** the capability appears in product or architecture documents;
- **implemented:** production code exists in the current checkout;
- **behavior-observed:** the capability's required outcomes were observed on a named build and
  environment;
- **user-accepted:** the declared user task and visual question were accepted on a named build and
  macOS environment;
- **release-accepted:** every requirement in the capability's declared release stage has the
  required implementation, safety, accessibility, behavior, and user evidence.

A capability is complete only when its public requirement and safety laws are implemented, its
required behavior and UI states are observable, and remaining limits are stated.
The current prototype does not yet meet those conditions for any cleanup capability.

## Product success signals

Release planning should measure candidate precision on declared fixtures, dangerous near-miss
refusals, scan time and cancellation, independently observed Trash outcomes, unresolved partial
failures, task completion with keyboard and VoiceOver, and whether developers can understand why an
item was proposed. Targets belong to the release stage that can measure them; this document does not
invent numbers before a representative corpus and baseline exist.

## Decisions before cleanup expands

The native entry points and remembered-location direction are accepted design choices, not evidence
of implementation. Before cleanup is enabled, establish filesystem identity through the actual
effect boundary, deliberate write authorization, and receipt retention and privacy. Family-specific
recreation predicates are admitted separately; an unsupported tool never inherits another family's
cleanup authority.

Consequential choices receive a short record in [architectural decisions](decisions/README.md).
