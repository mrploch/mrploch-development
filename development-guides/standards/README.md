# MrPloch Development Standards

Canonical, org-wide standards for .NET development in the [MrPloch GitHub organisation](https://github.com/mrploch).

These documents are the source of truth used to generate the `dotnet new` solution templates, the GitHub repository templates, and the reference sample applications. Where a standard diverges from mainstream practice, the document says so and gives the reason.

## Documents

| Document | Covers |
|---|---|
| [`project-structure-and-naming.md`](./project-structure-and-naming.md) | Repository shapes (single-project vs multi-project), the `Ploch.{Product}[.{Area}].{Layer}[.{Qualifier}]` naming pattern, the canonical layer set (`.Domain`, `.Data`, `.UseCases`, `.UI.*`, `.Api.*`), the "Console App with Data Access" archetype end-to-end, `Ploch.Common` / `Ploch.Data` usage conventions, testing standards, and a new-project checklist. |

## Relationship to `.claude/rules/`

`.claude/rules/*.md` are **agent instructions** — terse, imperative, loaded into an AI coding session's context. The documents here are **human-facing documentation** — they explain the reasoning, cite external references, and record deliberate divergences.

Where the two overlap, this directory is authoritative on *why*, and the rules files are authoritative on *what to do*. Keep them consistent; when a standard here changes, update the corresponding rule.
