# Safety model

Status: normative design requirements. The current read-only Cargo inspector enforces a narrow
classification subset; cleanup laws remain design requirements until their boundaries exist.

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
- **SAFE-012 — Equality is not disposability:** A matching content comparison never creates cleanup
  authority. Required paths, metadata, independent writes, source, and retention obligations remain
  separate constraints; an existing hard link is not an additional independent copy.
- **SAFE-013 — Unknown use stays protected:** Age, a clean repository, no matching reference, or no
  observed open process cannot prove disuse. Supported use and retention checks must not turn an
  uninspected consumer into a claim that an item is unnecessary.
- **SAFE-014 — Recovery must survive cleanup:** Any future recovery-dependent removal must retain a
  separately verified recovery object that is neither selected for removal nor contained within any
  selected directory.
  Revalidate both removed and retained objects at the effect boundary. Source and protected records
  remain excluded unless a later explicit safety decision admits a narrower operation.

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

The current Cargo inspector supports only the default layout beneath one folder the developer
selects. It requires that the selected root be a real directory, `Cargo.toml` be a real regular file,
`target` be a real directory at that root, and `target/CACHEDIR.TAG` be a real regular file whose
prefix matches Cargo's canonical cache-tag signature. A missing, unreadable, wrong-type, linked, or
invalid observation produces a typed refusal. The resulting read-only finding is not cleanup
authority.

This narrow rule follows Cargo's documented [default target-directory
layout](https://doc.rust-lang.org/cargo/reference/build-cache.html) and the signature check in
Cargo's own [`cargo clean`
validator](https://doc.rust-lang.org/nightly/nightly-rustc/src/cargo/ops/cargo_clean.rs.html#156-185).

Every other artifact family in [the product plan](PRODUCT.md#planned-artifact-coverage) remains
planned rather than supported.

## Discovery safety

A discovered directory name or manifest is only a reason to ask a classifier; it is not enough to
produce a supported result. The classifier must observe its complete evidence predicate for the
exact artifact before the scan can present it.

Inventory does not follow symbolic links or aliases and does not cross a mounted-filesystem
boundary beneath the authorized root. Those paths are outside the declared scan scope. A directory
that is inside that scope but cannot be inspected makes the scan partial instead of silently
becoming an empty or successful result. A familiar generated-directory name may be pruned only as a
traversal decision; it never becomes classification or cleanup authority.

### Saved access and incomplete observations

Remembered access is limited to grants obtained through the native chooser. Disabling or removing a
location prevents new observation under that grant and invalidates its contribution to current
results and selection. Metadata pointing outside approved roots does not authorize following it.
Read access never silently becomes cleanup write access.

An explicit exclusion or out-of-scope mount is different from an unreadable directory within scope.
Resource exhaustion is a partial observation. Scan-scope completeness and artifact-size
completeness must survive every summary independently; a complete inventory can contain an artifact
whose size could not be fully measured. Deduplicate overlapping observations without implying that
allocated estimates equal unique physical storage.

## Informational storage and duplicate results

Size observations and content comparisons are read-only findings, not supported-artifact or cleanup
claims. Unknown and protected material may contribute to qualified storage totals without being
eligible for content inspection or removal. Report what was excluded, unreadable, or limited.
Overlapping roots and hard links must not inflate independent-copy counts. Logical length, allocated
estimates, and exclusive physical space are different quantities; shared storage may make exclusive
reclamation unknown.

A duplicate-content claim requires complete comparison against the same observed filesystem
objects, with containment, identity and change checks throughout reading. Hashes may group likely
matches; sampled or equal hashes alone cannot authorize a verified equality claim. Record the
compared streams and unsupported metadata. Error or cancellation must never become equality.

Known active writers or conflicting retention evidence prevent admission to cleanup. Read-only
observation of those items may continue with the limitation shown. Lack of observed activity is
not a substitute for the supported family's regeneration and use rules. Reading project metadata
must not execute project scripts or acquire access outside approved locations.

An agent work folder or tool-owned store is a mixed container, not a cleanup family. Keep source,
worktrees, transcripts, logs needed for diagnosis, proof or review results, receipts, and other
retained records protected even when they sit beside generated files. A narrow generated subtree
may be considered only under its own supported family rule. For shared caches, installed versions,
and updater staging, the rule must understand the current layout and verify active use, update or
rollback needs, and a durable way to obtain required data again. A clean repository, package-manager
dry-run, matching copy, or lack of open files does not waive these checks. Unknown or contradictory
relationships refuse cleanup while remaining visible in storage results.
Displayed project connections are evidence-scoped observations, not a complete dependency graph;
an absent connection or a content match cannot authorize removal.

An archive's existence is not restoration evidence. A future recovery rule must account for the
exact contents and required metadata, completeness, integrity, available restoration tooling and
retained destination, with a demonstrated restoration appropriate to its stated claim. Mutually
dependent copies cannot each justify deleting the other, including across separate confirmed
operations. Restoration of historical records does not recreate their original execution.

## Always-excluded material

Unless a future safety review changes this document explicitly, BuildSweep excludes:

- source files and source-bearing directories;
- unique reports, historical records, recovery archives relied upon by retained work, and data with
  unresolved retention requirements;
- `.git` and other version-control metadata;
- package manifests and lockfiles;
- Xcode projects and workspaces, SwiftPM manifests, Cargo manifests, Gradle build definitions, and
  CMake source definitions;
- `.idea`, `.vscode`, Xcode user data, editor rules, run configurations, and other user-authored IDE
  settings;
- signing material, credentials, environment files, and secrets;
- dependency source checkouts, Xcode archives, SDKs, and simulator or device user data;
- symbolic links, aliases, mount boundaries, and unresolved filesystem identities;
- any unsupported, contradictory, stale, or incomplete classification.

An exclusion wins over a positive-looking signal. A new exception requires a documented decision,
a narrower classifier, and evidence that the dangerous near misses are refused.

## Additional artifact families

SwiftPM and Xcode cleanup must identify supported generated subtrees. A recognizable parent such as
`.build` or DerivedData can contain source-bearing or unrelated material, so its name never
authorizes removing the whole container. Unknown or protected contents prevent that directory from
becoming a cleanup candidate.

Python environments are informational until a separate supported recreation rule exists. Manifest
or lockfile presence alone is insufficient. Preserve local/editable packages and user-authored
material; do not execute project scripts to determine safety. Each later family needs its own
positive evidence, exclusions, and current regeneration limits.

## Selection and confirmation

The results view is informational until the developer makes a selection. Confirmation must show the
exact selected items and their total size using the same identities that will be revalidated at the
effect boundary. Default selection must not make an unreviewed item easy to remove accidentally.

If a result changes after scanning, BuildSweep refuses that item instead of quietly substituting a
path with the same text. A fresh scan creates a fresh candidate identity. Row focus, filtering,
sorting, and a widget or Dock action cannot create or widen cleanup selection. Nothing is selected
by default. Confirmation takes place in the main window using the exact selected identities.

## Trash boundary and outcomes

The Trash service receives only revalidated candidate identities, never an arbitrary path assembled
from UI text. It returns a typed outcome per item. A receipt records what BuildSweep actually
observed, including the identity at the resulting Trash location. A successful service response
alone does not establish the move. Post-operation checks supplement pre-effect protection; detecting
a wrong-object move afterwards does not satisfy the requirement to prevent it.

An observed move is not evidence that disk space was freed. Items remain in Trash until emptied, so
estimated artifact bytes, bytes moved to Trash, and current available capacity remain separate.
BuildSweep offers Open Trash for the developer's Finder action and never empties the Trash itself.
See [Apple's description of Trash](https://support.apple.com/guide/mac-help/delete-files-and-folders-on-mac-mchlp1093/mac).

BuildSweep must continue to present refused and failed outcomes after a mixed operation. Retrying
requires a fresh validity check and cannot expand the original selection.

## Release boundary

A safety law is not supported merely because implementation exists. Release evidence must also show
the intended behavior and dangerous near misses, including similarly named source directories,
blanket refusal, stale identities, link traversal, selection substitution, partial failure, and a
Trash service that reports success without producing the expected filesystem effect. Supported
macOS behavior, accessibility, and the visible confirmation and receipt experience must be observed
in the environments named by the release stage.
For a tool-specific work-area or cache rule, include different home paths, project layouts, tool
versions, active and retained work, unsupported layouts, and absent metadata. A rule that only works
for one developer's directory tree is not admitted for general cleanup.
