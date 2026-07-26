# GitHub Copilot instructions — Ploch.App

Ploch.App is a MrPloch layered console application built on the `Ploch.Data` generic repository /
Unit of Work stack and the `Ploch.CommandLine.Spectre` console host. See `CLAUDE.md` at the repo
root for the canonical agent guidance.

## Structure

- `src/Model` — domain entity POCOs implementing `Ploch.Data.Model` interfaces.
- `src/Data` — `AppDbContext`, `Configurations/` (one per entity), audit-timestamp handling.
- `src/Data.SQLite` / `src/Data.SqlServer` — design-time factories, `appsettings.json`, migration scripts.
- `src/ConsoleApp` — Spectre.Console host (`AppBuilder`) with `Commands/DemoCommand`.
- `tests/IntegrationTests` — xUnit v3 integration tests on `GenericRepositoryDataIntegrationTest<AppDbContext>`.

## Conventions

- MrPloch libraries are referenced either as relative source projects anchored to
  `$(PlochSiblingsRoot)` (MrPloch repos cloned as siblings) or as NuGet packages from the MrPloch
  GitHub Packages feed — switch with `-p:UsePlochProjectReferences=true|false`.
  `Ploch.CommandLine.Spectre` is not yet published, so it stays a sibling source reference in both modes.
- Entities implement `Ploch.Data.Model` interfaces; configurations are `internal`; set `OnDelete` explicitly.
- Inject the narrowest repository interface; use `IUnitOfWork` for multi-entity transactions.
- Tests use xUnit v3, FluentAssertions and AutoFixture.
- Conventional Commits with a `Refs: #<issue>` footer; British English.
