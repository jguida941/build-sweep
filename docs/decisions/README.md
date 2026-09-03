# Architectural decisions

Architectural decision records preserve why a consequential BuildSweep choice was made. They are
short historical records, not another copy of the current product, safety, or architecture docs.

## Decision index

| ID | Decision | Status |
| --- | --- | --- |
| [ADR-0001](0001-menu-bar-first-interface.md) | Use a menu-bar-first application shell | Accepted |
| [ADR-0002](0002-evidence-gated-trash-pipeline.md) | Require an evidence-gated, user-approved Trash pipeline | Accepted |

## When to write a decision

Write an ADR when a choice changes a durable component boundary, filesystem authority, safety or
privacy posture, persistence model, platform/framework dependency, or release shape. Do not write
one for routine Swift implementation details that a focused diff and product test explain better.

Each ADR contains context, decision, alternatives, consequences, and links to the canonical docs it
changes. Use `Proposed`, `Accepted`, `Superseded`, or `Rejected` as status. When a decision changes,
add a new ADR and link both records; do not rewrite the old rationale as though it never existed.

Current truth remains in:

- [Product requirements](../PRODUCT.md)
- [Safety model](../SAFETY.md)
- [Architecture](../ARCHITECTURE.md)
