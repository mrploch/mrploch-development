# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in the **Ploch.App** repository.

## What this is

A MrPloch layered console application generated from the `ploch-app` `dotnet new` template.
It is built on the `Ploch.Data` generic repository / Unit of Work stack and the
`Ploch.CommandLine.Spectre` console host.

## Architecture

| Project | Responsibility |
|---------|----------------|
| `src/Model` | Domain entity POCOs implementing `Ploch.Data.Model` interfaces (`IHasId<T>`, `IHasTitle`, `IHasAuditProperties`, `IHasCategories<T>`, `IHasTags<T>`, …). No business logic. |
| `src/Data` | `AppDbContext`, one `IEntityTypeConfiguration<T>` per entity in `Configurations/`, audit-timestamp handling in `SaveChanges`. Provider-agnostic via `IDbContextCreationLifecycle`. |
| `src/Data.SQLite` | SQLite design-time `AppDbContextFactory`, `appsettings.json`, migration helper scripts. |
| `src/Data.SqlServer` | SQL Server design-time `AppDbContextFactory`, `appsettings.json`, migration helper scripts. |
| `src/ConsoleApp` | Spectre.Console host via `AppBuilder`, with `Commands/DemoCommand`. DI through `AddDbContextWithRepositories<AppDbContext>()`. |
| `tests/IntegrationTests` | xUnit v3 + FluentAssertions integration tests inheriting `GenericRepositoryDataIntegrationTest<AppDbContext>`. |

## Cross-repository references

This repo references the MrPloch libraries as **relative source-project references**, anchored to
`$(PlochSiblingsRoot)` (defined in `Directory.Build.props`, default `$(MSBuildThisFileDirectory)..\`).
All MrPloch repos (`ploch-common`, `ploch-data`, `ploch-commandline`, `mrploch-development`) must be
cloned as **siblings** under the same parent folder. Override with
`-p:PlochSiblingsRoot=<path-with-trailing-slash>` if your layout differs.

Shared package versions and analyzers are imported from `mrploch-development/dependencies/*.props`
in `Directory.Packages.props` (Central Package Management).

## Commands

```bash
dotnet build Ploch.App.slnx                    # build
dotnet test  Ploch.App.slnx                    # run integration tests
dotnet run --project src/ConsoleApp -- demo    # run the demo command
```

EF Core migrations live in the provider projects (`src/Data.SQLite`, `src/Data.SqlServer`) — use the
`recreate-migrations.ps1` / `update-database.ps1` scripts there. SQLite is the default provider.

## Conventions

Follow the MrPloch organisation standards (data-access, data-project, domain-model,
writing-dotnet-tests, project-structure, commits, branch-naming) documented in
`mrploch-development/.claude/rules/`. Key points:

- Entities implement `Ploch.Data.Model` interfaces; no ad-hoc `Id`/`Name`/`Title` properties.
- One `IEntityTypeConfiguration<T>` per entity, marked `internal`; set `OnDelete` explicitly.
- Inject the narrowest repository interface needed; use `IUnitOfWork` for multi-entity transactions.
- Tests: xUnit v3, FluentAssertions, AutoFixture; method names `Scenario_should_do_x`.
- Integration tests validate writes via a **fresh** `CreateRootDbContext()`, never via the
  repository under test.
- Commits follow Conventional Commits with a `Refs: #<issue>` footer. British English.
