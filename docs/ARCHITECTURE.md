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
classifier to its default `target`, estimates allocated storage without following symbolic links or
crossing a mounted filesystem, and projects the typed finding or refusal into a native window. This
is an inspection finding, not the immutable cleanup candidate described by ARC-005.

A recursive directory inventory and Cargo scan coordinator are implemented separately from the
app. Scan results retain unreadable Cargo evidence as issues while keeping supported findings.
Traversal containment and other incomplete-observation cases still need validation before app
integration. The app continues to inspect only the selected workspace and does not yet present
results from recursive discovery.

Multi-project snapshots, stable cleanup identity, selection, revalidation, Trash, and receipts
remain unimplemented. The menu-bar entry and inspector window share one application model;
filesystem work runs away from the main actor.

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

## Components and responsibilities

- **ARC-001 — App shell:** Owns the native menu bar scene, commands, window or popover presentation,
  and dependency composition. It contains no classification or deletion rules.
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

## State and identity

A scan creates a unique snapshot identity. Every candidate is bound to that snapshot and to a
stable filesystem identity observed under one authorized root. Selection stores candidate identity,
not list position. A refresh replaces the visible snapshot and invalidates selections that cannot be
proven identical.

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
- no supported candidates found;
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

## Change control

A change that moves responsibility across these boundaries, introduces a new irreversible effect,
changes candidate identity, broadens filesystem authority, or makes a new framework/platform choice
requires an architectural decision record. Small implementation choices stay with the focused
implementation change.

Decision records explain why a choice was made and link back here. This document remains the source
of truth for the current architecture; an accepted decision does not duplicate or replace it.
