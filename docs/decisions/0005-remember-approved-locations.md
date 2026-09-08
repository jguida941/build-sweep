# ADR-0005: Remember explicitly approved scan locations

Status: Accepted

Date: 2026-09-08

## Context

Choosing each Cargo project separately cannot support recurring maintenance across development
folders and tool-owned output locations. Persistent access changes filesystem authority and must
remain visible and revocable.

## Decision

Remember multiple locations explicitly approved through the native chooser using security-scoped
bookmarks. One authorization store owns location identity, grant state, and authorization revisions.
Suggested locations and paths found in metadata do not grant access. Scan on demand, retain denied
locations as visible outcomes, and allow disabling, removing, and reauthorizing saved locations.
Read grants do not silently become write grants when cleanup is added.

This is a planned capability. The current app keeps read access only during one inspection.

## Alternatives

- Asking for every project on every scan makes routine maintenance unnecessarily repetitive.
- A default whole-Mac grant gives broader access than the first supported classifiers require.
- Saving path strings alone does not preserve the chooser's authorization.

## Consequences

Resolve and balance access around work. Invalidate affected results when authority changes and
deduplicate overlapping locations without widening grants. Observe relaunch, revoked access, and
mixed successful/denied locations through the packaged sandboxed app. Cleanup needs a later
deliberate write-permission transition.

Apple documents persistent access using [security-scoped bookmarks](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox).

Current requirements: [PRODUCT.md](../PRODUCT.md)

Current laws: [SAFETY.md](../SAFETY.md)

Current boundaries: [ARCHITECTURE.md](../ARCHITECTURE.md)
