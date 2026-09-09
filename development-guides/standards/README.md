# MrPloch Development Standards

Canonical, org-wide standards for .NET development in the [MrPloch GitHub organisation](https://github.com/mrploch).

These documents are the source of truth used to generate the `dotnet new` solution templates, the GitHub repository templates, and the reference sample applications. Where a standard diverges from mainstream practice, the document says so and gives the reason.

## Documents

| Document | Covers |
|---|---|
| [`project-structure-and-naming.md`](./project-structure-and-naming.md) | Repository shapes (single-project vs multi-project), the `Ploch.{Product}[.{Area}].{Layer}[.{Qualifier}]` naming pattern, the full canonical layer set (`.Domain`, `.Data`/`.Data.{Provider}`, `.UseCases`, `.UI.*`, `.Api.*`, `.Infrastructure`, `.Common`, `.Worker`, `.Functions`), the "Console App with Data Access" archetype end-to-end, `Ploch.Common` / `Ploch.Data` usage conventions (including the mandatory `ArgumentChecking` convention), testing standards, and a new-project checklist. |

## Relationship to `.claude/rules/`

`.claude/rules/*.md` are **agent instructions** — terse, imperative, loaded into an AI coding session's context. The documents here are **human-facing documentation** — they explain the reasoning, cite external references, and record deliberate divergences.

**Where the two disagree, the documents in this directory win.** The rules files are a derived, condensed restatement; when a standard changes here, the corresponding rule must be updated to match, and until it is, it is stale.

> **Known stale rules as of 2026-09-09:** `.claude/rules/project-naming.md` and `.claude/rules/domain-model.md` still mandate a `.Model` project, and the installable `solution-templates/ploch-app` template still generates `src/Model`, `src/ConsoleApp`, and no `.UseCases` project. Those contradict [`project-structure-and-naming.md`](./project-structure-and-naming.md) and are tracked for update. Follow this directory, not them.
