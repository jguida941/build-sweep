# ADR-0002: Require an evidence-gated, user-approved Trash pipeline

Status: Accepted

Date: 2026-09-03

## Context

Developer machines contain generated output beside source, configuration, credentials, and
project-specific state. A fast cleaner based on names or broad path patterns can appear effective
while removing material that is not safely regenerable. Permanent deletion also makes a
classification mistake unnecessarily costly.

## Decision

BuildSweep uses a one-way pipeline: authorized inventory, toolchain-specific evidence,
classification, typed candidate, explicit user selection, immediate revalidation, macOS Trash, and
an observed per-item receipt.

No stage may be skipped by a later stage. In particular, the UI cannot turn arbitrary path text into
a cleanup request, and a successful service return cannot be its own evidence that the filesystem
effect occurred.

## Alternatives

- **Name or glob matching:** rejected because a source directory can share the same name as generated
  output.
- **Automatic cleanup after scanning:** rejected because classification and authorization are
  different decisions.
- **Permanent deletion:** rejected because it removes the recovery boundary without improving
  classification.
- **Shelling out to `rm`:** rejected because it bypasses the product's typed Trash boundary and
  recoverability promise.

## Consequences

- Each artifact family needs a narrow classifier and evidence that dangerous near misses are refused
  before it is listed as supported.
- Candidate and filesystem identities must survive the transition from scan to confirmation.
- Stale or ambiguous candidates fail closed and require a fresh scan.
- Mixed outcomes remain visible; cleanup cannot be summarized by one success Boolean.
- The first useful release is deliberately narrower than a generic disk cleaner.

Current laws: [SAFETY.md](../SAFETY.md)

Current component flow: [ARCHITECTURE.md](../ARCHITECTURE.md)
