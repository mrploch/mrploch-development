# MrPloch solution templates

`dotnet new` templates for bootstrapping new repositories in the MrPloch organisation.

| Template | Short name | Description |
|----------|-----------|-------------|
| [`ploch-app`](./ploch-app) | `ploch-app` | A layered console application (Model → Data → ConsoleApp) on the `Ploch.Data` generic repository / Unit of Work stack and the `Ploch.CommandLine.Spectre` console host, with SQLite + SQL Server data projects and integration tests. |
| `aspnet-api-ef` | — | Placeholder / work in progress. |

## `ploch-app`

### What you get

```text
src/
  Model/          # Domain entity POCOs (Ploch.Data.Model interfaces)
  Data/           # AppDbContext + entity configurations + audit handling
  Data.SQLite/    # SQLite design-time factory + migration scripts
  Data.SqlServer/ # SQL Server design-time factory + migration scripts
  ConsoleApp/     # Spectre.Console host + demo command
tests/
  IntegrationTests/  # GenericRepositoryDataIntegrationTest-based tests
```

Plus the full repo config (`Directory.Build.props`, `Directory.Packages.props`, `.editorconfig`,
`.gitignore`, `.gitattributes`, `.dockerignore`, `stylecop.json`, `NuGet.Config`, `.slnx`) and AI
agent files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursorrules`, `.claude/`,
`.github/copilot-instructions.md`), a PR template, Dependabot config, and a CI workflow.

### Install

```bash
dotnet new install <path-to>/mrploch-development/solution-templates/ploch-app
```

(To update after changes: `dotnet new install --force <path>`. To remove: `dotnet new uninstall <path>`.)

### Create a new app

The new repository **must** be created as a sibling of the other MrPloch repos (`ploch-common`,
`ploch-data`, `ploch-commandline`, `mrploch-development`), because it references them as relative
source projects:

```bash
cd <parent-folder-holding-the-mrploch-repos>
dotnet new ploch-app -n Ploch.Tools.MyApp
```

This produces `Ploch.Tools.MyApp/` with every `Ploch.App` token (project names, namespaces,
solution file) replaced by `Ploch.Tools.MyApp`. The `AppDbContext` / `AppDbContextFactory` class
names are intentionally fixed.

### Parameters

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `-n, --name` | `Ploch.App` | Project/solution/namespace name. |
| `--siblingsRoot` | `..\` | Relative path (trailing `\`) from the repo root to the parent folder holding the `ploch-*` sibling repos. Override if your clone layout differs. |
| `--skipRestore` | `false` | Skip the automatic `dotnet restore` after creation. |

You can also override the sibling root per build without re-templating:

```bash
dotnet build -p:PlochSiblingsRoot=<absolute-path-with-trailing-slash>
```

### Verify a generated app

```bash
dotnet build Ploch.Tools.MyApp.slnx
dotnet test  Ploch.Tools.MyApp.slnx
dotnet run --project src/ConsoleApp -- demo
```
