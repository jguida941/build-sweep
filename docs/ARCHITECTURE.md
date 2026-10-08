# Architecture

Status: target architecture for the early BuildSweep releases. The first read-only Cargo slice
implements a narrow path through this architecture; cleanup components remain unimplemented.

## Architectural outcome

BuildSweep is a local, native macOS application with a one-way cleanup pipeline:

```text
authorized scan roots
        ↓
filesystem inventory
        ↓
toolchain-specific evidence and classification
        ↓
immutable typed candidates
        ↓
visible user selection and confirmation
        ↓
identity and containment revalidation
        ↓
macOS Trash service
        ↓
independently observed per-item receipts
```

Each arrow is a boundary that can refuse input. No downstream component may reconstruct authority
from a path string after an upstream component refused or omitted it.

## Current implementation boundary

The current app accepts one workspace chosen with the native macOS folder picker, applies the Cargo
classifier to its default `target`, and displays a typed finding or refusal with an allocated-size
estimate. This is an inspection finding, not the immutable cleanup candidate described by ARC-005.
Size measurement excludes entries observed as symbolic links and entries whose device differs from
the measured root, retaining readable sibling file allocation. Concurrent ancestor replacement can
redirect later path-based metadata reads; that containment boundary remains unimplemented.

A recursive directory inventory and Cargo scan coordinator are implemented separately from the
app. Scan results retain unreadable Cargo evidence as issues while keeping supported findings.
The inventory opens descendant paths one component at a time relative to an open root directory,
refusing symbolic links at each component. Directory listing and child metadata reads use directory
descriptors. Readable sibling branches and observable denied directories remain in partial results.
Returned paths do not carry those open descriptors into classification.
The reader defaults to a 100,000-child-entry allowance per inventory, counting files and excluded
entries as well as directories. If another entry would exceed the allowance, it retains observed
directories and reports an explicit partial result. This bounds child metadata attempts; it does
not bound directory-stream buffering, component-chain reopening, or subsequent artifact size measurement.
Root acquisition, moved open directories, later path consumers, aliases, mounts, cancellation, and
other incomplete-observation boundaries still need validation before recursive app integration.
The app continues to inspect only the selected workspace and does not yet present results from
recursive discovery.

A SwiftPM output-map decoder translates supplied, byte-limited metadata into raw source/object
path pairs. Input must be UTF-8 without a byte-order mark. The decoder refuses repeated decoded
member names within each object before storing the map, keeps auxiliary outputs separate, and
refuses unsupported entry shapes. It does not read or validate referenced paths, establish
regeneration evidence, or classify artifacts. SwiftPM file acquisition, artifact validation, and app
discovery remain unimplemented.

A bounded metadata reader borrows an already-open handle at its current position. It preserves
input within the configured byte allowance and refuses oversized input after consuming at most one
additional byte. Read errors produce a typed refusal. The caller owns access, handle lifetime, and
exclusive use. The byte allowance does not bound I/O waiting or provide cancellation. The reader
does not open paths, validate filesystem identity, or connect SwiftPM discovery to the app.

Multi-project snapshots, stable cleanup identity, selection, revalidation, Trash, and receipts
remain unimplemented. The menu-bar entry and inspector window share one application model;
filesystem work runs away from the main actor. Saved grants, incremental inventory, shared
multi-location state, useful Dock/menu commands, Apple classifiers, and a WidgetKit extension remain
planned. Storage overviews, content comparison, supported use/retention checks, age filters, and
growth summaries are also unimplemented. A documented component boundary is not an implemented service.

## Discovery boundary

Recursive discovery keeps inventory and classification separate. The filesystem inventory walks
real directories beneath one authorized root and reports typed cancellation, access, and
incomplete-observation outcomes. It never calls a path supported merely because it finds a familiar
name or manifest.

The scan coordinator passes possible workspace roots to the relevant classifier and collects only
its evidence-backed results. It may prune traversal at an explicit scope boundary or beneath an
artifact already classified for that scan, but pruning does not create product authority. This
keeps discovery reusable as more toolchains are added without moving safety policy into the
filesystem walker.

### Incremental traversal

Inventory must provide observations as directories are visited, with explicit descend/prune
decisions and cancellation and resource-limit outcomes. Classification can then prevent unnecessary
descent beneath supported artifacts without moving recognition policy into the walker. The current
array-returning inventory buffers the entire walk and does not yet provide this behavior.

The coordinator deduplicates approved roots and artifact identities while preserving the grant that
justifies each finding. It resolves ancestor/descendant overlap before producing selectable items.
Boundary exclusions, in-scope read failures, and incomplete size measurements remain separate data.

## Components and responsibilities

- **ARC-001 — App shell:** Owns startup composition, native window, menu, Dock and widget command
  routing, and location authorization adapters. It contains no classification or deletion rules.
- **ARC-002 — Scan coordinator:** Starts and cancels bounded scans, reports progress, and joins
  classifier output into a stable scan snapshot. It does not decide that an artifact is safe.
- **ARC-003 — Filesystem inventory:** Observes entries and metadata inside authorized roots without
  following an unapproved path or link boundary. It has no cleanup capability.
- **ARC-004 — Artifact classifiers:** One classifier per supported family turns current filesystem
  observations into either a typed candidate with evidence or a typed refusal. Classifiers have no
  UI or Trash dependency.
- **ARC-005 — Candidate model:** Carries stable filesystem identity, normalized location, artifact
  kind, byte count and completeness, evidence, scan identity, and the authorized-root relationship.
  It is immutable after emission.
- **ARC-006 — Selection model:** Owns the exact candidate identities selected by the developer. It
  cannot create candidates or widen a selection from display text.
- **ARC-007 — Revalidation service:** Reopens each selected identity immediately before cleanup and
  verifies classification, containment, and snapshot-sensitive facts. It emits an approved effect
  request or a typed refusal.
- **ARC-008 — Trash service:** Accepts only approved effect requests and invokes the macOS Trash
  boundary. It cannot scan, classify, select, permanently delete, or silently retry a different
  item.
- **ARC-009 — Receipt model and store:** Records one observed outcome per attempted candidate and
  preserves mixed results. It distinguishes a Trash request from an independently observed move.
- **ARC-010 — Presentation state:** Projects scan, selection, confirmation, cleanup, and receipt
  state into SwiftUI. Views render state and send user intent; they do not perform filesystem policy.
- **ARC-011 — Storage observations and comparison:** Produces qualified read-only size, age and
  content-match observations from the shared authorized inventory. Bounds hashing and comparison,
  preserves object identity and incomplete outcomes, and cannot create cleanup requests.
- **ARC-012 — Use and recovery evidence:** Reads only supported project/tool metadata and records
  known consumers, activity, retention constraints and recovery dependencies. Unknown relationships
  remain unknown. Family rules and revalidation consume these observations; this component cannot
  select items or relax a protected-material exclusion.

## Dependency rules

The domain model and classifier rules remain independent of SwiftUI and concrete macOS services.
Dependencies point inward:

```text
SwiftUI presentation ─┐
menu bar app shell ───┼──> application workflows ──> domain policies and types
macOS adapters ───────┘                │
                                       └──> adapter protocols
```

Concrete filesystem, Trash, clock, identity, and receipt adapters are injected at composition time.
Domain and application layers must not import a view or read UI labels to make a safety decision.
Views must not pass arbitrary paths directly to the Trash adapter.

## Shared commands and native presentation

Create one application command owner at startup before a scene or external action can use it. Inject
it into the window, menu bar, and Dock delegate. Commands request a scan, cancel an attempt, open
review, manage locations, or open settings; they cannot grant authority or accept arbitrary cleanup
paths. The coordinator is the sole scan executor. Equivalent requests for the same authority
revision share the active attempt; a changed authority revision invalidates affected work.

Keep Domain, Application, Infrastructure, and Presentation responsibilities in the existing app
until a real compilation boundary is needed. A typed classifier interface adds families without
duplicating Cargo policy. Replace the Cargo-specific presentation model when shared snapshots land;
do not retain an independent single-project workflow beside it.

The menu uses a native compact panel and the Dock delegates quick actions to the same command owner.
The main window uses a locations sidebar, sortable results table, and artifact detail view. Row
focus and cleanup selection are separate. The main window owns permission repair and confirmation.

WidgetKit receives a versioned, atomically replaced summary through an App Group, containing
observation time, scan identity, qualified estimated size, and validity state. It receives no raw paths, bookmarks, or
cleanup requests. Scan and Review actions route to fixed app commands; cold launch initializes
authorization and state before processing them. A request is not displayed as accepted work until
the app accepts it. Widget timelines are not a promise of live progress.

## Storage and retention observations

Extend the existing inventory and scan snapshot as these capabilities land; do not build a second
scanner or a generic plugin system. Storage observations, recognized artifacts, content-match groups,
and cleanup candidates have different types and consumers. Unsupported or protected large items can
appear in the storage view without a route into the selection model. Comparison and supported
use/recovery readers are narrow responsibilities added within the existing layers.

A content-match observation binds every member's filesystem identity, approved-root relationship,
comparison scope, observation interval and validity. Group by cheap metadata and hashes, then compare
complete contents of stable objects before reporting a verified match. Coalesce overlapping roots
and hard-link identities without conflating byte-identical files with shared physical blocks.
The measurement adapter keeps logical, allocated and unknown exclusive storage separate; the UI
cannot convert duplicate byte totals into promised savings.

Supported use evidence binds the metadata source, recognized layout/version, referenced identities,
and inspected scope. Project source remains data, never executable inspection instructions. A
reference outside a grant is an unresolved relationship, not permission to follow it. No global
project-dependency graph or proof of arbitrary future use is claimed.

For agent-created work areas and tool stores, ARC-011 can report bounded storage observations of
mixed contents, while ARC-012 reads only supported metadata for producer, consumer, active-writer,
version-pointer, and recovery relationships. Each relationship is observed, unresolved, or
contradictory and retains its inspected scope; missing references never become an unused verdict.
ARC-004 may classify an individual generated subtree under its own family rule, but cannot promote
the containing work area or store into a candidate. ARC-007 rechecks the family-specific use and
recovery facts, including active version or update state where relevant, immediately before effect.
This adds narrow readers to the shared scan rather than a second scanner or unrestricted project
graph. Readers recognize versioned tool evidence relative to each approved root and observed
filesystem identities, not an absolute path from one machine. Unsupported layouts remain read-only
unknowns, with no fallback from missing metadata to inferred disuse.
ARC-010 projects these typed relationships for one selected item and its known neighbors, including
the metadata source and incomplete scope. Following a connection does not grant access beyond an
approved root or turn a content match into a consumer edge. This bounded projection is a review
aid, not an exhaustive dependency graph or a cleanup decision.

If a later cleanup rule depends on retained recovery data, bind that dependency into its immutable
candidate. Selection and revalidation reject removal of a recovery dependency or its ancestor,
coordinate overlapping operations, and invalidate dependent candidates when a kept object changes
or disappears. Receipts preserve original paths and the recovery relationship. The native Trash
service retains its existing narrow role; archive creation, hard-link substitution and storage
compaction are not implicit cleanup effects.

Keep scan history bounded and local. Growth comparisons bind equivalent root authority, coverage,
measurement basis and observation times; incomplete scans cannot appear as a measured decrease.
Do not persist file contents merely to remember a scan. Evidence and receipt retention must account
for low available capacity and retained recovery dependencies before pruning records.

## Location authorization

One store owns approved location IDs, bookmark data, enablement, and authorization revisions. It
resolves security-scoped URLs and balances access for the duration of work. UI components do not
resolve bookmarks. Missing or stale grants lead to typed setup/access states, never fallback access
to a wider path. Persisted read grants do not substitute for deliberate cleanup write permission.

## State and identity

A scan creates a unique snapshot identity. Every candidate is bound to that snapshot and to a
stable filesystem identity observed under one authorized root. Selection stores candidate identity,
not list position. A refresh replaces the visible snapshot and invalidates selections that cannot be
proven identical.

The latest attempt and the displayed snapshot are separate values. Starting or cancelling a scan
does not rewrite the observation time of a retained older snapshot. Late completion is checked
against both attempt identity and current root authority. Revocation invalidates affected findings
and selection. Closing the window does not destroy the command owner or its task.

Snapshots preserve per-location outcomes and per-item measurement completeness independently.
Read-only findings are a distinct type from cleanup candidates. Estimated allocated bytes, observed
Trash outcomes, and available volume capacity are separate projections, not one savings counter.

The revalidation service is the only transition from reviewed candidate to effect request. It must
reject a candidate when the item is missing, replaced, relocated outside authority, linked through
an unsupported boundary, no longer satisfies its classifier, or cannot be observed completely.

Scanning and byte counting run away from the main actor. User-visible state changes return to the
appropriate UI isolation boundary. Cancellation is explicit data, not an error coerced into empty
results.

## Presentation states

The product must represent at least these distinct states as the corresponding slices are built:

- ready to choose or inspect scan roots;
- scanning with progress or indeterminate activity and cancellation;
- results with complete and incomplete size observations distinguished;
- no supported candidates found, with storage observations and unsupported coverage still visible;
- duplicate content observed with cleanup unavailable;
- known use or retention requirement, or use/recovery status unknown;
- age unknown or growth comparison unavailable;
- access denied or authorization required;
- scan failure that preserves actionable context;
- selection review and confirmation;
- revalidation in progress or refusal;
- Trash operation in progress;
- complete success, cancellation, complete failure, and partial failure;
- receipts available for review.

Exact visual composition belongs to the UI contract and user review. Collapsing these semantic
states into the same success-looking presentation is an architecture defect.

## Observable boundaries

The architecture provides narrow seams where each important behavior can be observed:

- classifier examples, near misses, properties, and path-shape transformations;
- authorized-root containment and link traversal;
- stable identity and stale-candidate revalidation;
- exact selection and refresh invalidation;
- cancellation and incomplete inventory behavior;
- Trash adapter requests and independent filesystem outcomes;
- per-item receipts and partial failures;
- presentation-state reduction and accessibility identifiers for meaningful controls.

A classifier exposes its typed result. Cleanup exposes both the Trash request and the filesystem
outcome through a channel independent of the Trash adapter's return value. Presentation is not the
only observable protection for a domain safety law.

## Requirement and safety traceability

This table maps current public laws to the boundaries expected to enforce them. It is a design map,
not evidence that enforcement exists.

| Law | Primary boundary | Required observable behavior |
| --- | --- | --- |
| PRD-001 | ARC-001, ARC-003, ARC-008 | Core workflows succeed with local adapters and no network dependency |
| PRD-002 | ARC-001, ARC-002, ARC-003 | Inventory never observes outside the supplied authorized roots |
| PRD-003 | ARC-004, ARC-005 | Each family accepts evidence-backed examples and refuses dangerous near misses |
| PRD-004 | ARC-005, ARC-010 | Candidate projection preserves kind, path, size state, and evidence |
| PRD-005 | ARC-006, ARC-007 | Only exact confirmed candidate identities become effect requests |
| PRD-006 | ARC-008, ARC-009 | Trash is the only effect and every accepted item receives an observed outcome |
| PRD-007 | ARC-002, ARC-007, ARC-009, ARC-010 | Empty, denied, cancelled, stale, partial, and failed states remain distinct |
| PRD-008 | ARC-001, ARC-010 | Keyboard and accessibility observations cover every implemented state and action |
| PRD-009 | ARC-002, ARC-003, ARC-010 | Work remains cancellable and UI state remains responsive under bounded load |
| PRD-010 | ARC-003, ARC-010, ARC-011 | Large unknown/protected observations remain visible but non-selectable |
| PRD-011 | ARC-003, ARC-011 | Full stable comparison is distinct from same-object aliases and cleanup eligibility |
| PRD-012 | ARC-004, ARC-007, ARC-012 | Known consumers/recovery dependencies are preserved; unknown use is not unused |
| PRD-013 | ARC-002, ARC-010, ARC-011 | Age basis and comparable coverage survive filters and growth summaries |
| SAFE-001 | ARC-004 | Same-name paths without required evidence are refused |
| SAFE-002 | ARC-004, ARC-005 | Candidate emission requires the complete family evidence predicate |
| SAFE-003 | ARC-003, ARC-004, ARC-007 | Protected source/configuration fixtures never become effect requests |
| SAFE-004 | ARC-003, ARC-005, ARC-007 | Traversal, link, alias, and normalized-path escapes are refused |
| SAFE-005 | ARC-006, ARC-007 | Parent, sibling, reordered, and newly appearing items are never implicitly selected |
| SAFE-006 | ARC-005, ARC-007 | Replaced, moved, missing, or reclassified items are refused before effect |
| SAFE-007 | ARC-008 | No adapter path can invoke permanent or shell deletion |
| SAFE-008 | ARC-008, ARC-009 | Every attempt produces one identity-bound typed outcome |
| SAFE-009 | ARC-009, ARC-010 | Mixed outcomes remain visible and cannot reduce to complete success |
| SAFE-010 | ARC-002, ARC-007, ARC-008 | Cancellation before effect yields no mutation or incomplete candidate |
| SAFE-011 | ARC-001, ARC-003 | Permission denial is surfaced without hidden escalation or scope expansion |
| SAFE-012 | ARC-004, ARC-011 | Equal contents cannot mint cleanup authority or erase metadata/use distinctions |
| SAFE-013 | ARC-004, ARC-012 | Missing or uninspected use evidence cannot become an unused verdict |
| SAFE-014 | ARC-005, ARC-006, ARC-007, ARC-012 | Every selected removal preserves and revalidates its required recovery object |

## Change control

A change that moves responsibility across these boundaries, introduces a new irreversible effect,
changes candidate identity, broadens filesystem authority, or makes a new framework/platform choice
requires an architectural decision record. Small implementation choices stay with the focused
implementation change.

Decision records explain why a choice was made and link back here. This document remains the source
of truth for the current architecture; an accepted decision does not duplicate or replace it.
