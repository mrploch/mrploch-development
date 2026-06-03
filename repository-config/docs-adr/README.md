# Architecture Decision Records (ADRs)

This directory contains the Architecture Decision Records (ADRs) for **<repository name>**.

## What is an ADR?

An ADR captures a single architecturally significant decision: **what** we decided, **why** we decided it, and **what alternatives we considered**. ADRs outlive PRs and issues — when someone asks in two years "why did we structure X this way?", the ADR is where the answer lives.

We use a lightweight variant of [MADR (Markdown Any Decision Records)](https://adr.github.io/madr/). The template is in [`0000-template.md`](0000-template.md).

## When to write an ADR

**Write an ADR when:**

- A decision affects how the codebase is structured or how consumers interact with it.
- A decision involved choosing between two or more credible alternatives.
- The reasoning behind the decision is non-obvious from the code alone.
- The decision constrains future work in ways future maintainers should know about.

**Don't write an ADR for:**

- Implementation details local to a single file or feature.
- Decisions captured fully in a commit message or PR description that won't outlive the PR.
- Reversible coding-style preferences (those belong in `.editorconfig` or analyser rules).
- Bug fixes — unless the fix establishes a new convention.

## Index

| # | Status | Title | Date |
|---|--------|-------|------|
| _No ADRs yet — see `0000-template.md` to add the first one._ | | | |

## Authoring

1. Copy `0000-template.md` to a new file named `NNNN-short-title.md`, where `NNNN` is the next number in sequence (zero-padded, four digits).
2. Fill in the template. Keep it focused on this single decision; don't pad with general context that belongs in other docs.
3. Add a row to the Index above.
4. Commit the ADR alongside the PR that implements (or formally proposes) the decision.

## Status lifecycle

- **Proposed** — under discussion, not yet implemented.
- **Accepted** — current decision; implemented or being implemented.
- **Deprecated** — no longer current, but kept for historical context. Add a one-line note explaining what replaced it (or why it was abandoned).
- **Superseded by ADR-NNNN** — replaced by a later decision. Cross-link both ways: this ADR's status points at the new one, the new one's `Supersedes` field points back here.

## See also

- [adr.github.io](https://adr.github.io/) — overview of ADR practices
- [MADR project](https://adr.github.io/madr/) — the template family this repo uses
- [Michael Nygard's original 2011 post](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — where ADRs come from
