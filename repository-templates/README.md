# .NET repository templates — canonical shared files

The mrploch organisation has three GitHub template repositories for new .NET repositories:

| Template | Repository | For |
|---|---|---|
| `library` | [ploch-templates-dotnet-repository](https://github.com/mrploch/ploch-templates-dotnet-repository) | A packable .NET library with a NuGet trusted-publishing release workflow |
| `console` | [ploch-templates-dotnet-console](https://github.com/mrploch/ploch-templates-dotnet-console) | A command-line application on Spectre.Console.Cli |
| `console-data` | [ploch-templates-dotnet-console-data](https://github.com/mrploch/ploch-templates-dotnet-console-data) | A command-line application with an EF Core data layer on Ploch.Data |

Each template is self-contained: a repository created from it builds without any other repository. The files that
must stay identical across all three (the CI workflows, the bootstrap script, analyser and editor settings, and the
hygiene files) are kept here, in [`shared/`](shared), and copied into the templates with
[`Sync-RepositoryTemplates.ps1`](Sync-RepositoryTemplates.ps1). Template-specific files (projects, build properties,
package versions, README, agent instructions) live only in each template repository.

## Changing a shared file

1. Edit the file under `shared/`. In shared files, `__REPOSITORY__` stands for the template's repository name.
2. Clone the template repositories beside this one (the mrploch workspace layout) and preview the update:

   ```powershell
   ./repository-templates/Sync-RepositoryTemplates.ps1 -WhatIf
   ```

3. Apply it, then commit and open a pull request in each template repository. Each template's CI, including its
   Template Bootstrap workflow, verifies the change:

   ```powershell
   ./repository-templates/Sync-RepositoryTemplates.ps1
   ```

4. Merge the change here too, so `shared/` stays the source of truth.

`-Template library,console` limits a run to some templates, and `-TemplatesRoot <path>` points at clones elsewhere.

## Detecting drift

```powershell
./repository-templates/Sync-RepositoryTemplates.ps1 -Check
```

reports every shared file that differs from `shared/` and exits with code 1 if any does — for example after a fix
was made directly in a template repository. Copy such a fix back into `shared/` rather than overwriting it.

## Removing a shared file

Delete it from `shared/` and add its path to `retired` in [`templates.json`](templates.json). The next sync deletes it
from every template, and `-Check` reports any template that still has it. Remove the entry once every template has
been synced.

## Template-specific exclusions

[`templates.json`](templates.json) lists the templates. A template's `exclude` entries are shared files it keeps its
own version of; `console-data` keeps its own `.config/dotnet-tools.json` because it adds the `dotnet-ef` tool.

## Repositories created from a template

A new repository is an independent copy: it is initialised once with `scripts/Initialize-Repository.ps1` (which then
deletes itself) and is not synced afterwards. To adopt a later template change, compare the file with the template
and copy the change by hand.
