# Contributing

Thank you for helping to improve this project.

## Before you start

- For anything beyond a small fix, open an issue first so the approach can be agreed.
- Security issues are reported privately; see [SECURITY.md](SECURITY.md).

## Development

You need the .NET SDK version pinned in [`global.json`](global.json).

```bash
dotnet tool restore
dotnet build -c Release      # Release turns analyser warnings into errors, exactly as CI does
dotnet test -c Release
```

Coverage, as CI measures it:

```bash
dotnet test -c Release /p:CollectCoverage=true /p:CoverletOutput=./CoverageResults/ "/p:CoverletOutputFormat=cobertura%2copencover"
dotnet reportgenerator "-reports:**/CoverageResults/coverage*.cobertura.xml" -targetdir:coverage-report -reporttypes:Html
```

## Pull requests

- Branch from `main` and keep each pull request to one logical change.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages, for example
  `feat(text): add slug separator option`.
- Add or update tests. CI requires at least 80% coverage of the lines a pull request changes.
- Document public APIs with XML comments. Packable libraries generate documentation files, so their build fails
  on undocumented public members.
- Add a [`change-log/`](change-log/README.md) entry for every user-visible change.
- The build must be free of warnings, and every review conversation must be resolved before merging.
