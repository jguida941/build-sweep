# Safety model

Status: normative design requirements. The current prototype does not yet enforce these laws.

BuildSweep treats cleanup as a safety-sensitive local operation. “Regenerable” is a classification
that must be supported by current evidence; it is never inferred from a familiar folder name or
used as permission to remove an item automatically.

## Safety laws

- **SAFE-001 — Name is not evidence:** A path or directory name alone never authorizes
  classification or cleanup.
- **SAFE-002 — Evidence-gated candidates:** The scanner may emit a candidate only when a supported
  classifier observes the required project or toolchain evidence for that exact artifact.
- **SAFE-003 — Source exclusion:** Source, repository metadata, manifests, lockfiles, workspace and
  project settings, editor rules, user-authored IDE configuration, credentials, and unknown items
  never enter a cleanup request.
- **SAFE-004 — Authorized containment:** Scanning and cleanup remain inside roots the developer has
  explicitly authorized. Links, aliases, path normalization, or traversal must not silently expand
  that authority.
- **SAFE-005 — Exact user selection:** Only the stable identities of candidates explicitly selected
  and confirmed by the developer may reach the cleanup boundary. Selecting a child does not select
  its parent, siblings, or a newly appearing item.
- **SAFE-006 — Revalidation before effect:** Immediately before cleanup, BuildSweep must verify that
  each selected item is still the classified filesystem object inside the authorized root. A moved,
  replaced, missing, or newly ambiguous item is refused and must be rescanned.
- **SAFE-007 — Trash only:** BuildSweep moves accepted items through the macOS Trash operation. It
  does not call permanent deletion, shell deletion, or a fallback that bypasses Trash.
- **SAFE-008 — Per-item receipt:** Every attempted item receives an outcome that identifies the
  selected candidate and records success, refusal, cancellation, or failure without exposing
  unrelated private path data.
- **SAFE-009 — Partial failure is not success:** One successful move cannot mask a refused or failed
  item. The interface preserves each outcome and offers only actions valid for the remaining state.
- **SAFE-010 — Cancellation is non-destructive:** Cancelling a scan or size calculation produces no
  cleanup candidate from incomplete evidence. Cancelling before a Trash operation begins causes no
  filesystem mutation.
- **SAFE-011 — No privilege surprise:** BuildSweep does not escalate privileges or broaden macOS
  access behind the developer's back. Denied locations remain denied and are reported as such.

These laws are conjunctive. Passing one law does not compensate for violating another.

## Classification evidence

A classifier owns one artifact family and declares:

- the artifact type it can emit;
- the project or toolchain observations it requires;
- the relationship those observations must have to the candidate path;
- explicit exclusions and ambiguous states;
- the evidence displayed to the developer;
- the versions or layouts it does not claim to understand.

Evidence must be observed from the current filesystem snapshot. Cached classification, a previous
scan, a suffix match, or the cleanup service's own success response is not a substitute.

The first supported classifiers will define their exact evidence in focused implementation changes.
Until then, the artifact families in [the product plan](PRODUCT.md#planned-artifact-coverage) remain
planned rather than supported.

## Always-excluded material

Unless a future safety review changes this document explicitly, BuildSweep excludes:

- source files and source-bearing directories;
- `.git` and other version-control metadata;
- package manifests and lockfiles;
- Xcode projects and workspaces, SwiftPM manifests, Cargo manifests, Gradle build definitions, and
  CMake source definitions;
- `.idea`, `.vscode`, Xcode user data, editor rules, run configurations, and other user-authored IDE
  settings;
- signing material, credentials, environment files, and secrets;
- symbolic links, aliases, mount boundaries, and unresolved filesystem identities;
- any unsupported, contradictory, stale, or incomplete classification.

An exclusion wins over a positive-looking signal. A new exception requires a documented decision,
a narrower classifier, and product tests for the dangerous near misses.

## Selection and confirmation

The results view is informational until the developer makes a selection. Confirmation must show the
exact selected items and their total size using the same identities that will be revalidated at the
effect boundary. Default selection must not make an unreviewed item easy to remove accidentally.

If a result changes after scanning, BuildSweep refuses that item instead of quietly substituting a
path with the same text. A fresh scan creates a fresh candidate identity.

## Trash boundary and outcomes

The Trash service receives only revalidated candidate identities, never an arbitrary path assembled
from UI text. It returns a typed outcome per item. A receipt records what BuildSweep actually
observed; it does not claim that space was reclaimed until the move is independently visible, and it
does not claim permanent erasure because Trash is recoverable.

BuildSweep must continue to present refused and failed outcomes after a mixed operation. Retrying
requires a fresh validity check and cannot expand the original selection.

## Verification expectations

Every safety law that reaches implementation needs an ordinary product test for its stable public
behavior. High-risk laws also need adversarial cases for similarly named source directories,
blanket refusal, stale identities, link traversal, selection substitution, partial failure, and a
Trash service that reports success without producing the expected filesystem effect.

Tests and implementation are necessary but not sufficient for a release claim. Supported macOS
behavior, accessibility, and the visible confirmation/receipt experience must also be observed in
the environments named by the release stage.
