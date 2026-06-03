# Repository: mrploch-development

> **Audience:** AI agents (Claude Code, Codex, Gemini, …) opening a session inside this repo or in a sibling repo that references it.
> **Purpose:** A short, opinionated orientation. For full prose, see [`README.md`](../README.md).

<!-- BEGIN: human-authored content -->

## What this repository is

This is the **org-wide development-standards and guideliness repository** for the [MrPloch GitHub organisation](https://github.com/mrploch).
It is **not** a library or application.
It contains things like:

- code style settings (and static analyzer settings), for example `.editorconfig` files for repositories
- AI Agents configurations
- templates for solutions
- configuration scripts
- general development guideliness for `MrPloch` GitHub organization

## What lives here

<!-- TODO (user): Bullet list — top-level directories and what they hold. Keep terse. -->

- `dependencies/` — shared MSBuild `*.Packages.props` fragments imported by sibling repos for Central Package Management.
- `editor-config/` — `.editorconfig` baselines.
- `repository-config/` — repo-creation guides and configuration files for new public/private repos.
- `solution-templates/` — `.slnx` / `Directory.Build.props` starting points for new solutions.
- `computer-config/` — local development machine setup notes.
- `development-notes-guidelines/` — how the org keeps task notes and journals.
- `designs/` — cross-repo design documents and architectural sketches.
- `scripts/` — utility scripts for repo / workspace maintenance.

## How sibling repos use this repo

<!-- TODO (user): Replace / extend with your actual conventions. -->

Sibling repos (`ploch-common`, `ploch-data`, `ploch-lists`, …) reference this repo
via **relative paths** during local development:

```xml
<Import Project="../mrploch-development/dependencies/Testing.Packages.props" />
```

All MrPloch repos must be cloned as siblings under the same parent directory.

## Issue & feature tracking

We use GitHub Issues per repository and also [GitHub Projects](https://github.com/orgs/mrploch/projects) per repository.
From time to time, we create a new projects per feature, especially if a feature spans across several repositories. For example the [Generic Repository and Unit of Work](https://github.com/orgs/mrploch/projects/9).

## Notes & journaling

<!-- TODO (user): Workspace-level notes live in `C:\DevNet\my\mrploch\notes`. Anything mrploch-development-specific? -->

…

## Hard rules for agents working in this repo

<!-- TODO (user): Things you want agents to ALWAYS or NEVER do here. Example: -->

- **Do not** edit auto-generated content between `<!-- BEGIN ContextStream -->` / `<!-- END ContextStream -->` markers in `CLAUDE.md`, `AGENTS.md`, or `GEMINI.md`.
- **Do** update `README.md` when adding or renaming top-level directories.
- …

<!-- END: human-authored content -->
