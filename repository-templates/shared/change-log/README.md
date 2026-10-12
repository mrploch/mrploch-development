# Change log entries

Every pull request with a user-visible change adds one Markdown file to this directory, named
`<yyyy-MM-dd>-<short-description>.md`, for example `2026-10-09-add-slug-options.md`:

```markdown
### Added

- `TextNormalizer.ToSlug` accepts a custom separator.
```

Use the headings `Added`, `Changed`, `Fixed`, `Removed` or `Security`.

In repositories with a Release workflow (the library template), the release concatenates the entries into the
GitHub release notes, then moves them to `change-log/archive/<version>/` in its bookkeeping pull request. Merge that
pull request before the next release; until it is merged, the same entries would be published again.
