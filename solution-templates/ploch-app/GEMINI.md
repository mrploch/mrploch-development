# GEMINI.md

Orientation for Gemini and other AI coding agents working in the **Ploch.App** repository.

This is a MrPloch layered console application (Model → Data → ConsoleApp) built on the
`Ploch.Data` generic repository / Unit of Work stack and the `Ploch.CommandLine.Spectre`
console host. See **[`CLAUDE.md`](./CLAUDE.md)** for the full architecture, conventions, and
command reference — it is the canonical agent guide for this repository.

## Quick facts

- MrPloch libraries are referenced either as **relative source projects** anchored to
  `$(PlochSiblingsRoot)` (clone `ploch-common`, `ploch-data`, `ploch-commandline` and
  `mrploch-development` as siblings, or override `-p:PlochSiblingsRoot=<path-with-trailing-slash>`)
  or as **NuGet packages** from the MrPloch GitHub Packages feed — switch with
  `-p:UsePlochProjectReferences=true|false` (default set in `Directory.Build.props`).
  `Ploch.CommandLine.Spectre` is not yet published, so it is a sibling source reference in both modes.
- Build: `dotnet build Ploch.App.slnx` · Test: `dotnet test Ploch.App.slnx` ·
  Run: `dotnet run --project src/ConsoleApp -- demo`.
- EF Core migrations live in `src/Data.SQLite` / `src/Data.SqlServer` (SQLite is the default).
- Follow the org rules in `mrploch-development/.claude/rules/` (domain-model, data-access,
  data-project, writing-dotnet-tests, commits, branch-naming). Conventional Commits with a
  `Refs: #<issue>` footer; British English.
