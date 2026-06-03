# Repository Configuration

## Folder Index

| Folder | Purpose |
|--------|---------|
| [`root-folder`](./root-folder) | Files copied into the root of a new repository (`Directory.Build.props`, `Directory.Packages.props`, `NuGet.config`, build scripts, etc.). |
| [`common-properties`](./common-properties) | Shared MSBuild property fragments imported by repos. |
| [`default`](./default) | Default `.editorconfig` variants for source and test projects. |
| [`sample-solutions`](./sample-solutions) | Reference solution layouts for common repository shapes. |
| [`docs-adr`](./docs-adr) | Template for the per-repo `docs/adr/` folder (Architecture Decision Records). |

## Root Folder

The [root-folder](./root-folder) contains common files that should be used as a template in a new repository.
Files should be adjusted to the project. Two types of the items should be changed (or set using environment variables):

- items that reference properties `$(MRPLOCH_ORG_*)`
- items with value `_CHANGE_ME__`

Items referencing properties should either 

It contains:

- [`.editorconfig`](./root-folder/.editorconfig)
- [`Directory.Build.props`](./root-folder/Directory.Build.props)
  - .NET version
  - Language version
  - Analysis level
  - Enabling implicit usings and nullables
  - etc.
- [`Directory.Packages.props`]
  - Centralized package versions
  - Enabling analyzer packages

## Documentation Conventions

### Architecture Decision Records (ADRs)

Every MrPloch .NET repository should have a `docs/adr/` folder for Architecture Decision Records — short, versioned markdown files that capture **what** we decided, **why** we decided it, and **what alternatives we considered**. ADRs outlive PRs and issues and are the canonical place to look when someone asks "why was this designed this way?".

We use a lightweight variant of [MADR (Markdown Any Decision Records)](https://adr.github.io/madr/).

#### Per-repo setup

When creating a new repository (or adding ADRs to an existing one):

1. Create a `docs/adr/` folder at the repo root.
2. Copy the two files from [`docs-adr/`](./docs-adr/) into it:
   - [`README.md`](./docs-adr/README.md) — the index. Replace `<repository name>` with the actual repo / package name. Add a row to the **Index** table when each new ADR is added.
   - [`0000-template.md`](./docs-adr/0000-template.md) — the template. Leave it untouched; contributors copy from it when authoring an ADR.
3. Link `docs/adr/README.md` from the repo's `docs/README.md` (or top-level `README.md` if there is no `docs/` index).
4. From now on, write an ADR alongside any PR that contains a non-trivial architectural decision.

#### When to write an ADR

| Write an ADR for | Don't write an ADR for |
|------------------|-----------------------|
| Decisions that affect codebase structure or consumer-facing API | Implementation details local to a single file or feature |
| Choices made between two or more credible alternatives | Decisions captured fully in a PR description that won't outlive the PR |
| Reasoning that is non-obvious from the code alone | Reversible coding-style preferences (use `.editorconfig` / analyser rules instead) |
| Decisions that constrain future work | Bug fixes — unless the fix establishes a new convention |

#### File naming and numbering

- `NNNN-short-kebab-title.md`, where `NNNN` is the next sequential number (zero-padded, four digits).
- The number is **per-repo**, not org-wide.
- The first real ADR in a repo is `0001-…`. `0000-template.md` is reserved for the template.

#### Status lifecycle

- **Proposed** — under discussion, not yet implemented.
- **Accepted** — current decision; implemented or being implemented.
- **Deprecated** — no longer current, kept for historical context.
- **Superseded by ADR-NNNN** — replaced by a later decision; cross-link both ways.

#### Reference repos

- [`ploch-common/docs/adr/`](https://github.com/mrploch/ploch-common/tree/master/docs/adr) — has [ADR-0001](https://github.com/mrploch/ploch-common/blob/master/docs/adr/0001-multi-target-test-project-over-side-project.md) (multi-targeting the test project to cover both shipped binaries) as a worked example.
- [`ploch-data/docs/adr/`](https://github.com/mrploch/ploch-data/tree/main/docs/adr) — scaffold only at the moment.

## Developer Activities

### Creating New Solutions

### Creating New Projects

#### Checklist

- [ ] Create a corresponding test project
- [ ] Edit the `csproj` files for both projects and remove all properties already listed in the `Directory.Build.props` file
- [ ] Create the `docs/adr/` folder by copying [`docs-adr/`](./docs-adr/) (see [ADR conventions](#architecture-decision-records-adrs) above)
