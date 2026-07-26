# Ploch.App

A MrPloch application generated from the `ploch-app` `dotnet new` template — a layered
console application built on the [`Ploch.Data`](https://github.com/mrploch/ploch-data)
generic repository / Unit of Work stack and the
[`Ploch.CommandLine.Spectre`](https://github.com/mrploch/ploch-commandline) console host.

## Layout

```text
src/
  Model/          # Domain entity POCOs (implement Ploch.Data.Model interfaces)
  Data/           # AppDbContext, entity configurations, audit-timestamp handling
  Data.SQLite/    # SQLite design-time factory + migrations + helper scripts
  Data.SqlServer/ # SQL Server design-time factory + migrations + helper scripts
  ConsoleApp/     # Spectre.Console host (AppBuilder) + the `demo` command
tests/
  IntegrationTests/  # GenericRepositoryDataIntegrationTest-based integration tests
```

## Prerequisites

This repository can reference the MrPloch libraries in two ways, controlled by the
`UsePlochProjectReferences` MSBuild property (its default was chosen by the template's
`--referenceStyle` parameter — see `Directory.Build.props`):

- **ProjectReference mode** (`UsePlochProjectReferences=true`) — relative source-project
  references into side-by-side sibling clones. Use this for local cross-repo development.
- **NuGet mode** (`UsePlochProjectReferences=false`) — `Ploch.*` packages restored from the
  MrPloch GitHub Packages feed (see `NuGet.Config`; requires the
  `MRPLOCH_GITHUB_PACKAGES_TOKEN` environment variable). Package versions are pinned in
  `Directory.Packages.props` (`PlochPackagesVersion`).

Either mode can be selected per build without editing any file:

```bash
dotnet build -p:UsePlochProjectReferences=true    # sibling source projects
dotnet build -p:UsePlochProjectReferences=false   # NuGet packages
```

In ProjectReference mode the following repositories must be cloned **side by side** under the
same parent folder:

```text
<parent>/
  ploch-common/
  ploch-data/
  ploch-commandline/
  mrploch-development/
  Ploch.App/          <- this repository
```

In NuGet mode the `ploch-data` clone is no longer needed, but three siblings are still required:
`mrploch-development` (shared package-version props), `ploch-commandline` (`Ploch.CommandLine.Spectre`
is not yet published as a NuGet package, so the ConsoleApp project references its source in **both**
modes), and `ploch-common` (referenced transitively by `Ploch.CommandLine.Spectre`'s own source
projects).

If your clone layout differs, override the sibling root at build time:

```bash
dotnet build -p:PlochSiblingsRoot=<absolute-path-to-parent-with-trailing-slash>
```

> **Note:** the SqLite and SqlServer `Ploch.Data.GenericRepository.EFCore.*` DependencyInjection
> packages share namespaces and method signatures — a project may reference only **one** of them
> at a time (the ConsoleApp uses the SqLite one).

## Build & test

```bash
dotnet build Ploch.App.slnx
dotnet test  Ploch.App.slnx
```

## Run the console app

```bash
dotnet run --project src/ConsoleApp -- demo
```

The `demo` command creates the SQLite database, seeds an author and two articles through the
generic repository + Unit of Work, and renders them as a Spectre.Console table.

## Database migrations

Migrations live in the provider-specific projects. By default the app uses **SQLite**.

```bash
# SQLite (default)
cd src/Data.SQLite
./recreate-migrations.ps1      # add an Initial migration
./update-database.ps1          # apply it

# SQL Server
cd src/Data.SqlServer
./recreate-migrations.ps1
./update-database.ps1
```

Switch providers by referencing the SQL Server DI package in `src/ConsoleApp` and updating the
connection string in `appsettings.json` — no application code changes are required (both
providers expose the same `AddDbContextWithRepositories<TDbContext>()` registration).

## Conventions

This repository follows the MrPloch organisation standards documented in
[`mrploch-development`](https://github.com/mrploch/mrploch-development) and surfaced to AI
agents via `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.cursorrules`, and
`.github/copilot-instructions.md`.
