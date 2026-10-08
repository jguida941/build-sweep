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

## Product outcome

BuildSweep helps a developer understand accumulating development storage and recover space from
supported regenerable artifacts while keeping the decision understandable and reversible. Approved
scope can include projects, shared tool caches, and temporary development work outside repositories.
Large unsupported items remain visible as informational observations, with their uncertainty stated.

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
- **PRD-003 — Supported classification:** BuildSweep identifies an artifact as supported only when
  a classifier has sufficient project or toolchain evidence. Informational storage observations do
  not become cleanup candidates.
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
- **PRD-010 — Storage visibility:** Within approved development locations, show large files and
  directories with size completeness and supported, protected, or unknown status. Finding no
  supported artifacts must not imply that the location uses no space.
- **PRD-011 — Duplicate observations:** Report verified matching file contents separately from
  cleanup eligibility. Identify every compared object, comparison scope, and unresolved metadata;
  do not label two paths to the same filesystem object as two independent copies.
- **PRD-012 — Use and recovery evidence:** Explain relationships established by supported project
  or tool metadata, known active work, and supported regeneration requirements. Missing references
  are not proof of disuse. Archive-backed recovery is distinct from regeneration.
- **PRD-013 — Age and growth:** Allow review filters by observed age and comparisons between saved
  scans. State the timestamp basis and comparable scan scope; unknown age or incomplete coverage
  must remain visible. No age threshold authorizes cleanup.

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
| Agent-created work areas | Read-only inventory of build output, worktrees, retained results, and unknown contents | Supported tool and project relationships; only independently admitted generated subtrees may become candidates |
| Shared package, download, and version stores | Informational inventory before tool-specific cleanup rules | Recognized tool layout, current version or active update state, and supported recovery requirements |

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

## Storage, duplicates, and project use

The results window should answer three separate questions: what occupies space, what is recognized,
and what qualifies for reviewed cleanup. Informational rows cannot be selected for cleanup. Show
supported generated output, unknown or protected contents, and duplicate groups without combining
all their sizes into a removable-space estimate. Source and sensitive contents remain protected;
large-folder visibility does not authorize indiscriminate content hashing.

Duplicate comparison starts with explicitly scoped regular files. Size or sampled hashes can narrow
comparison work but cannot establish equality. A verified content match requires complete comparison
of stable objects; a changed, unreadable, cancelled, or limit-exhausted comparison remains unresolved.
Report the comparison's content scope: matching primary file bytes alone says nothing about other
streams, metadata, independent future writes, required locations, or recovery.

Project awareness grows through separately supported tool layouts and metadata. Report observed
owners, configured inputs, repository/worktree relationships, and retained recovery requirements
where supported. Never execute an unfamiliar project's scripts to determine whether its data is
needed. A clean Git status, an old timestamp, a temporary-looking name, or no observed open process
cannot establish that a directory is disposable. Unknown use or retention requirements prevent a
cleanup recommendation for that item; they do not prevent a storage observation.

Agent-created work areas, including Codex work folders, may contain source, worktrees, build
intermediates, downloaded tools, logs, transcripts, results, and recovery records together. Show
their measured parts and supported project relationships without classifying the containing folder
as regenerable. A relationship is evidence from a recognized tool layout or project metadata,
not a guess from a folder name. Distinguish the producer, a known consumer, an active writer, and
a retained recovery dependency; show unknown or conflicting relationships explicitly. References
outside approved locations remain unresolved rather than expanding scan access.

The repeatable cleanup path is a narrow rule for one generated artifact family, with its own
regeneration source, use and retention checks, exact identity, and current revalidation. Shared
package stores, installed tool versions, and updater staging need tool-specific rules that account
for active use, offline rebuilds, rollback, and replacement downloads. A tool's dry-run or a scan
that finds no active process is information, not proof that the whole store can be removed. Whole
work-area cleanup is unavailable without a separate, supported recovery rule.

Rules must be portable across developers' Macs: identify supported tool layouts and metadata under
each person's approved locations rather than depend on this machine's folder names or a fixed home
path. Validate a rule against different projects, tool versions, worktree layouts, and negative
examples. If a supported relationship cannot be established on another machine, show the storage
observation with an unknown relationship and no cleanup recommendation.

The results inspector should show a bounded relationship view for a selected item: its observed
project or worktree, producing tool, known consumers, and retained recovery dependencies, with the
metadata source and observation scope for each connection. A developer can follow a supported
connection to another observed item. Uninspected locations and missing metadata appear as unknown,
not as an empty graph. Matching file contents are a separate comparison, not a use connection.
This view explains what is known without claiming a complete dependency graph of the Mac.

A rebuildable cache and an exact historical copy have different recovery needs. The latter may
contain unique source, results, or records that a new build will not reproduce. Duplicate discovery
therefore starts as informational. Removal based on a retained copy or archive requires a separately
admitted recovery rule, explicit kept and removed identities, and current restoration evidence.
No such rule or general archive/compaction capability is implemented. Existing protected-material
exclusions continue to apply; a recovery archive does not override them.

BuildSweep should also expose recurring growth through comparable scan summaries, so repeated
output accumulation can be traced to supported projects or tools. It does not repair other tools'
retention policies automatically. Its own scan state and receipts need bounded storage, visible
retention choices, and low-space failure handling; scanning must not duplicate the trees it observes.

## Native interfaces

Four entry points share the same application commands and results:

| Surface | Purpose | Planned actions |
| --- | --- | --- |
| Menu bar | Compact status and frequent actions | Scan Saved Locations, Cancel Scan, Review Results, Manage Locations, Settings, Quit |
| Dock | Quick access when the window is not frontmost | Scan Saved Locations, Cancel Scan, Review Results |
| Widget | Glanceable summary and focused actions | Scan Now and Review; medium WidgetKit family first |
| Main window | Comparison, explanations, permissions, and cleanup review | Locations sidebar, size-sorted results, details with supported project connections, search/filter, keep/exclude, Reveal in Finder, exact selection and confirmation |

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
   traversal, pruning, and overlap handling while preserving existing Cargo recognition. Add
   qualified storage observations without treating unsupported large folders as empty.
2. **Remembered locations and results:** approved saved locations, one shared scan snapshot,
   incremental results, per-location issues, and a native comparison window. Keep unknown and
   protected observations non-selectable; show age basis and comparable growth separately.
3. **Useful menu and Dock commands:** connect quick actions to that same workflow and preserve
   startup, cancellation, and window activation behavior.
4. **Apple coverage:** add SwiftPM and Xcode separately, admitting only supported generated subtrees.
5. **Reviewed cleanup:** exact selection, deliberate write access, identity revalidation, native
   Trash movement, and independently observed per-item receipts; enable each family separately.
6. **Widget:** package the medium widget with qualified summaries, Scan and Review actions, gallery
   appearance, cold-launch routing, and accessibility.
7. **Coverage expansion:** Python caches and Java build output, followed by C/C++, JavaScript, IDE,
   agent work areas, and other tool caches. Start mixed work areas and shared stores as read-only
   observations; admit generated subtrees and tool-specific cleanup separately. Conditional
   environment cleanup is a separate capability.
8. **Duplicates and retention:** introduce read-only file comparisons, then supported use/recovery
   evidence. Admit any duplicate cleanup rule separately; preserve evidence, working copies, source,
   and required locations. General archive creation and storage compaction remain deferred.
9. **Release readiness:** verify supported macOS behavior, accessibility, responsiveness,
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
- a promise that every developer cache or every version of a supported tool is recognized;
- a universal determination that arbitrary software will never need a file again;
- automatic archive deletion, hard-link replacement, or compaction of working copies.

## Decisions before cleanup expands

The native entry points and remembered-location direction are accepted design choices, not evidence
of implementation. Before cleanup is enabled, establish filesystem identity through the actual
effect boundary, deliberate write authorization, and receipt retention and privacy. Family-specific
recreation predicates are admitted separately; an unsupported tool never inherits another family's
cleanup authority.

Consequential choices receive a short record in [architectural decisions](decisions/README.md).
