# Architecture Decision Records

One file per decision: `ADR-NNN-short-slug.md`, numbered in order. The folder is the log.

## When to write one

In the same PR as the change, when it adds or swaps a service, database, external vendor or core library;
changes auth, roles, secrets or personal data; changes a public API or webhook shape; or changes deployment
topology. Skip it for trivial, reversible changes. Not sure? Write it.

## How

1. Copy [`TEMPLATE.md`](TEMPLATE.md) to `ADR-NNN-short-slug.md` (next free number; never reuse one).
2. Fill every section, with at least two real options. Status starts as `Proposed`, becomes `Accepted` on
   review.
3. Never edit an Accepted ADR. Write a new one, then change only the old one's Status to
   `Superseded by ADR-NNN`. Never delete an ADR.
