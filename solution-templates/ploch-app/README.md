# Ploch.App

A MrPloch application generated from the `ploch-app` `dotnet new` template — a layered
console application built on the [`Ploch.Data`](https://github.com/mrploch/ploch-data)
generic repository / Unit of Work stack and the
[`Ploch.CommandLine.Spectre`](https://github.com/mrploch/ploch-commandline) console host.

## Layout

```
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

This repository references the MrPloch libraries as **relative source-project references**,
so the following repositories must be cloned **side by side** under the same parent folder:

```
<parent>/
  ploch-common/
  ploch-data/
  ploch-commandline/
  mrploch-development/
  Ploch.App/          <- this repository
```

If your clone layout differs, override the sibling root at build time:

```bash
dotnet build -p:PlochSiblingsRoot=<absolute-path-to-parent-with-trailing-slash>
```

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
