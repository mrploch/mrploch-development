# `ai-config-generator` — cloud agents & automation

This document covers the cloud agents the workspace currently encounters or wants to support, the constraints they impose on canonical content, and how the generator wires them together with day-to-day automation.

All facts in this document were verified against primary sources in April 2026; citations appear at the end. Where official documentation contradicts community reports, both are noted.

## The three cloud agents we care about

| Agent | Trigger | Sandbox | Reads | Writes | MCP support |
|---|---|---|---|---|---|
| **Cursor Background Agent** | `@cursor` mention; cursor.com/agents UI; Slack/Linear/GitHub integrations; programmatic via Cursor SDK or `cursor-agent` CLI | Cursor-hosted Ubuntu VM, configured via `.cursor/environment.json` | repo branch + `.cursor/environment.json`. Whether `.cursor/rules/*.mdc` are honoured is unconfirmed (gaps reported) | branch + PRs | partial / broken — MCP is configurable in `cursor.com/agents` UI but **not via Cloud Agents API**; `${env:...}` interpolation does not work in cloud context |
| **GitHub Copilot Coding Agent** | Issue assignment to Copilot; `@github-copilot` mention | GitHub-hosted | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md` (root + nested, since 2025-08-28), `CLAUDE.md`, `GEMINI.md` | branch + PRs | yes — stdio / http / sse — but configured **via repo settings UI, not a committed file**. **OAuth-authenticated remote MCP servers explicitly NOT supported.** Secrets must use `COPILOT_MCP_` prefix |
| **OpenAI Codex Cloud** | OpenAI web UI / Codex extension | OpenAI-hosted | `AGENTS.md` (walks down from git root, all concatenated up to 32 KiB), optional `setup_script` | branch + commits/PRs | unverified — official docs do not confirm MCP support in the cloud sandbox |

Local cousins (Cursor IDE, `cursor-agent` CLI, Copilot IDE Chat, Codex CLI) read the same instruction files and don't have the cloud-sandbox constraints — but they share the same generated output, so consistency is automatic.

## Why cloud agents are special for this generator

Three properties that drive design decisions:

1. **No local-process MCP servers.** Cloud sandboxes can't reach your laptop. Anything stdio-based that talks to a desktop app (ContextStream, anything that pokes at `localhost`) is unreachable. The generator's `runs_in.<cloud-target>` flags must be honest, and `cloud_mode: true` must be a hard filter, not advisory.
2. **OAuth-authenticated remote MCP servers don't run in the Copilot Coding Agent.** Confirmed by [GitHub MCP docs](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp). Generator MCP entries with `auth: oauth` must be filtered out for `copilot-coding-agent` regardless of `runs_in` flag.
3. **Frozen-snapshot fallback for missing MCP context.** Cloud agents lose access to ContextStream-like memory. The generator's optional `snapshot_export` writes recent decisions/lessons to committed files (`.ai-context/`) so cloud agents can read them as plain text. This is opt-in per-repo because public OSS repos may not want lessons committed.

## Canonical-content rules that influence cloud-agent output

- **Use `audience: cloud-safe`** for content that genuinely works in cloud sandboxes. Most rules qualify; a few don't.
- **Use `audience: claude-only`** for blocks that depend on Claude's `Skill` tool, sub-agents, or local MCP. These are stripped from cloud-agent output by construction.
- **Provide `body_overrides`** for cross-tool rules whose Claude version mentions Claude-specific tools. The cloud variant gets the override; the local Claude variant gets the original.

## Cursor — CLI, SDK, and Background Agents

Three Cursor surfaces relevant to this generator. They have **different** instruction-file behaviour, which is the most important fact in this document.

### 1. Cursor CLI (GA, January 2026)

Standalone binary (`curl https://cursor.com/install -fsS | bash`). Headless via `--print` / `-p`. Auth via `CURSOR_API_KEY`. Reads `.cursor/mcp.json` from the working tree (project) or `~/.cursor/mcp.json` (global). Supports stdio, HTTP, SSE MCP transports.

Whether the headless CLI reads `.cursor/rules/*.mdc` is **not documented**. Conservative assumption: it doesn't, or does so unreliably. The generator should not depend on the CLI consuming `.mdc` rules — instead, pass instructions inline via the prompt, or rely on the `--include` flag (if it materialises) to feed canonical-source paths directly.

### 2. Cursor TypeScript SDK (public beta, April 2026)

`npm install @cursor/sdk`. TypeScript only — no Python SDK. Auth via `CURSOR_API_KEY`. Token-based billing.

API surface:
- `agent.send(prompt, { files: [...] })` — programmatic invocation with prompt + file context.
- Cloud-VM mode: SDK launches an agent on a Cursor-hosted sandboxed clone of the repo; can `open a PR, push a branch, attach demos and screenshots` per the [SDK announcement](https://cursor.com/blog/typescript-sdk).
- Local mode: agent runs against an already-checked-out working tree.

**Important nuance for this generator:** the SDK announcement explicitly mentions `.cursor/skills/` and `.cursor/hooks.json` as the SDK's preferred reusable-behaviour mechanism — **not** `.cursor/rules/`. This suggests Cursor is bifurcating: `.cursor/rules/` for editor / human-driven flows, `.cursor/skills/` + `hooks` for SDK-driven flows. The generator's Cursor emitter should likely target both:

```
<repo>/.cursor/rules/<name>.mdc        ← editor + Background Agent (via UI)
<repo>/.cursor/skills/<name>/...       ← SDK-driven cloud / local agents
<repo>/.cursor/hooks.json              ← SDK lifecycle hooks
<repo>/.cursor/mcp.json                ← MCP, all surfaces
```

The exact `.cursor/skills/` schema is part of the SDK beta; the generator should mirror Claude's skill structure (folder per skill, `SKILL.md` plus attachments) and verify against the SDK docs once it leaves beta.

### 3. Cursor Background Agents (cloud)

Configured per-repo via `.cursor/environment.json` (committed): defines `snapshot`, `install`, `start`, `terminals`, `env`, `baseImage`, `persistedDirectories`. **This file does not configure MCP servers and does not reference rules files.**

MCP support is partial:
- Configurable through the `cursor.com/agents` UI dashboard, but **not through the Cloud Agents API.**
- `${env:...}` interpolation does not work in the cloud context — secrets must be hardcoded.
- Multiple users report authentication and visibility failures (forum thread: [Cloud Agents + MCP](https://forum.cursor.com/t/cloud-agents-mcp/152033)).
- Cursor's own docs explicitly say `MCP is not yet supported by the Cloud Agents API.`

Whether `.cursor/rules/*.mdc` are honoured by Background Agents is unconfirmed; community reports indicate at least some rule types (e.g. commit message rules) are ignored. The generator must not assume rules propagate to Background Agents.

### Cursor Rules `.mdc` frontmatter — confirmed schema

Three optional fields:

| Field | Type | Effect |
|---|---|---|
| `description` | string | Used by the model when `alwaysApply` is false and no globs match |
| `globs` | string or string array | Auto-attaches when matching files are in context |
| `alwaysApply` | boolean | If `true`, included in every session unconditionally |

When `alwaysApply: true`, `description` and `globs` are effectively ignored. When all three are absent, the rule is `manual` only — activated by `@rule-name` mention. No additional fields are documented.

The legacy `.cursorrules` (root) is parsed for backward compatibility but deprecated.

### Proposed automation pattern

A reusable composite GitHub Action lives at `mrploch/ploch-github-actions/cursor-cloud-agent`:

```yaml
# .github/workflows/cursor-cloud.yml — emitted into each repo by the generator
name: Cursor Cloud Agent

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  cursor:
    if: |
      github.event.comment.user.type == 'User' &&
      contains(github.event.comment.body, '/cursor ')
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.issue.pull_request.head.ref || 'main' }}
      - run: curl https://cursor.com/install -fsS | bash
      - run: |
          cursor agent run --print \
            --output-format stream-json \
            "${{ github.event.comment.body }}"
        env:
          CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
```

The composite action wraps the install + invocation flow and standardises auth, prompt extraction, and result-handling across all 16 sibling repos. Drift between repos is impossible because the action is versioned externally.

For SDK-driven flows the workflow imports a small TypeScript script that uses `@cursor/sdk` directly — useful when the prompt template needs runtime composition (e.g. prepending recent ContextStream lessons via snapshot export).

### Generator's role in Cursor flows

- Emits `.cursor/rules/*.mdc` (editor + Background Agent UI consumption).
- Emits `.cursor/skills/*` (SDK-driven flows). Skill bodies share canonical source with Claude skills; emitter only reformats frontmatter and folder layout.
- Emits `.cursor/mcp.json` with cloud-safe filtering when target is `cursor-bg-agent`.
- Optionally emits `.cursor/hooks.json` from a canonical hooks definition (to be designed in Phase 5).
- Optionally emits the workflow file (`targets.yaml > cursor-bg-agent.options.emit_workflow: true`).
- **Does NOT emit `.cursor/environment.json`** — that file is repo-specific (toolchain install, base image), not a translation of canonical content. Each repo authors its own `environment.json`.

## GitHub Copilot Coding Agent

### What the generator emits

`<repo>/.github/copilot-instructions.md` (repository-wide), `<repo>/.github/instructions/*.instructions.md` (per-area, with `applyTo` globs).

### Confirmed instruction sources

The Coding Agent reads (per [GitHub's reference table](https://docs.github.com/en/copilot/reference/custom-instructions-support)):

1. `.github/copilot-instructions.md` — repository-wide, no frontmatter.
2. `.github/instructions/*.instructions.md` — path-specific; uses `applyTo` frontmatter with glob patterns.
3. `AGENTS.md` — root (always-on) and nested files (added 2025-08-28).
4. `CLAUDE.md` and `GEMINI.md` — also read by the Coding Agent.

This is convenient: **the same `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` files the generator already emits for other targets are also read by the Copilot Coding Agent.** No additional Copilot-specific work needed beyond `copilot-instructions.md` and the `.instructions/` directory.

The IDE Copilot Chat reads only `.github/copilot-instructions.md`, not the path-specific `.instructions.md` files. Generator emits both regardless — the cloud agent benefits from the path-specific files.

### `applyTo` syntax

Confirmed glob support: `*`, `**`, `**/*`, `*.py`, `**/*.py`, `src/**`, `src/**/*.py`, `**/subdir/**/*.py`. Single string per file (comma-separate multiple globs into one string).

### MCP for Copilot Coding Agent — important correction

**Earlier draft of this design assumed `.github/copilot/mcp.json` is a committed file. That is wrong.** The Coding Agent's MCP servers are configured **via the GitHub repo settings UI** (Settings → Copilot → Cloud agent → MCP configuration), not via a repo-committed file. Org/enterprise admins can also configure servers via YAML in custom-agent definitions, but that's an out-of-band registration.

Implications for the generator:

- The generator does **not** emit a Copilot MCP file. There's nothing to emit.
- Instead, the generator emits a **documentation file** at `<repo>/.github/copilot-mcp.recommended.md` that lists the cloud-safe MCP servers from `mcp-servers.yaml` (filtered by `runs_in.copilot-coding-agent: true`) with the exact server config blocks ready to paste into the GitHub settings UI.
- The generator validates: any server with `runs_in.copilot-coding-agent: true` must have `auth: api_key | bearer | none` — never `auth: oauth`, because the Coding Agent does not support OAuth-authenticated MCP. Hard validation error V12.
- The generator validates: any env var name in `runs_in.copilot-coding-agent: true` servers must be prefixed `COPILOT_MCP_` per [GitHub's secret-scoping requirement](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp). Hard validation error V13.

### Generator's role in Copilot flows

- Emit instructions (`copilot-instructions.md` + per-skill `.instructions.md` files).
- Emit `.github/copilot-mcp.recommended.md` documenting the cloud-safe server set.
- Validate OAuth and `COPILOT_MCP_*` env var conventions.
- (Stretch) Emit a `.github/instructions/contributing.instructions.md` referencing the canonical `commits.md` and `pr-descriptions.md` so the Coding Agent's PRs follow conventions.

### Why this is mostly self-driving

Compared to Cursor Background Agents, Copilot Coding Agent needs no workflow YAML — it's invoked via GitHub UI and runs server-side. The generator's job is purely "make the instruction files correct".

## OpenAI Codex Cloud

### What the generator emits

`<repo>/AGENTS.md` (cloud-safe filtered when target is `codex-cloud`).

### AGENTS.md discovery and concatenation — confirmed

Per [OpenAI Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md):

1. Global: `~/.codex/AGENTS.override.md` then `~/.codex/AGENTS.md`.
2. Project: walks **down** from git root to current working directory, checking each level for `AGENTS.override.md`, then `AGENTS.md`, then any filenames listed in `project_doc_fallback_filenames`.
3. All discovered files are **concatenated** (joined by blank lines), with files closer to the current working directory appended later (and therefore overriding).
4. Combined size limit: **32 KiB** (configurable via `project_doc_max_bytes` in `~/.codex/config.toml`).

Implication: the generator can emit **nested** `AGENTS.md` files for path-scoped rules (e.g. one in `tests/AGENTS.md`, one in `src/AGENTS.md`). This is the cleanest way to honour `applies_to` globs without inflating the root file. Phase 4 candidate.

The 32 KiB limit is real — current `AGENTS.md` files in the workspace are ~31 KiB and getting close. Generator should warn when output approaches 28 KiB.

### Codex CLI vs Codex Cloud — config

CLI: `~/.codex/config.toml` (global) and `.codex/config.toml` per-project. MCP servers configured under `[mcp_servers.<name>]` — supports stdio and Streamable HTTP. SSE is not listed.

Cloud: official docs do not confirm MCP support. Snapshot export (`.ai-context/`) is the recommended workaround for prior context.

### Snapshot export — for Codex Cloud and any cloud agent

ContextStream-equivalent context is unreachable in any cloud sandbox. The generator can compensate via committed snapshots:

```
<repo>/.ai-context/
  decisions.md            ← from `mcp__contextstream__memory(action="decisions")`
  lessons.md              ← from `mcp__contextstream__session(action="get_lessons")`
  recent-architecture.md  ← curated query against ContextStream
```

Generator behaviour:

- `dotnet ai-config emit --include-snapshot` queries the user's local ContextStream MCP at emit-time.
- Snapshot files are non-deterministic (ContextStream evolves) — they carry an explicit "snapshotted on YYYY-MM-DD" header and are excluded from `check` mode's drift detection.
- AGENTS.md (cloud variant) ends with: *"For prior context not captured here, consult `.ai-context/decisions.md` and `.ai-context/lessons.md`."*
- Opt-in per-repo via `repos.yaml > <repo>.snapshot_export: true`. Default off — public OSS repos likely don't want this committed.

### Generator's role in Codex flows

- Emit cloud-safe `AGENTS.md` (root + optional nested for tight `applies_to` globs).
- Emit optional `.ai-context/` snapshot.
- Warn when AGENTS.md approaches the 32 KiB ceiling.
- Nothing else needed — Codex Cloud is invoked from OpenAI's UI; Codex CLI reads the same files locally.

## Gemini Code Assist / Gemini CLI

### What the generator emits

`<repo>/GEMINI.md`.

### Discovery — confirmed

Gemini CLI: `~/.gemini/GEMINI.md` (global), then project hierarchy from current directory up to `.git` root or home directory, then subdirectories (up to 200 files by default; configurable via `loadFromIncludeDirectories`). More-specific (deeper) files supplement or override more-general ones.

### MCP — separate from GEMINI.md

MCP is configured in `settings.json`, **not** in `GEMINI.md`. Locations: `~/.gemini/settings.json` (global) and `.gemini/settings.json` (project). Supported transports: stdio (`command`), SSE (`url`), Streamable HTTP (`httpUrl`). Precedence if multiple are specified: `httpUrl > url > command`.

### Cloud surface

No Gemini-equivalent of Codex Cloud or Cursor Background Agents identified from primary sources. Gemini Code Assist agent mode runs inside the IDE (VS Code extension). The generator therefore treats Gemini as a single target without a cloud variant.

### Generator's role

- Emit `<repo>/GEMINI.md`.
- Optionally emit `<repo>/.gemini/settings.json` MCP block from `mcp-servers.yaml` (target `gemini`, all transports).

## Windsurf

### What the generator emits

`<repo>/.windsurf/rules/*.md` (workspace-level, 12 KiB per file).

### Frontmatter — confirmed (correcting earlier draft)

Three fields:

| Field | Values | Effect |
|---|---|---|
| `trigger` | `always_on`, `model_decision`, `glob`, `manual` | Activation mode |
| `globs` | string or string array | Required when `trigger: glob` |
| `description` | string | Surfaces in Cascade memories UI |

Earlier draft used `always` / `manual` / `model_decision` — **incorrect.** Confirmed values are `always_on`, `model_decision`, `glob`, `manual`. The emitter mapping should be:

- priority `critical` ⇒ `always_on`
- priority `high` and globs present ⇒ `glob`
- priority `normal` and globs present ⇒ `glob`
- priority `low` ⇒ `manual` or `model_decision`
- no globs ⇒ `model_decision` (description-driven)

### Other Windsurf surfaces — not generator targets

- `~/.codeium/windsurf/memories/global_rules.md` — global, 6 KiB. Personal; not generated.
- `AGENTS.md` — Windsurf reads it too. Already emitted by the Codex target; generator does not re-emit for Windsurf.
- Legacy `.windsurfrules` (root) — deprecated; not emitted.

### MCP

Configured at `~/.codeium/windsurf/mcp_config.json` (global only — no per-project). Supports stdio, Streamable HTTP, SSE, and OAuth per transport. 100-tool limit globally.

The generator does not emit a Windsurf MCP file (it's global, personal). Instead, it can emit a `<repo>/.windsurf/mcp_config.recommended.json` advisory file mirroring the cloud-safe section, mainly for documentation parity with the Copilot recommended file.

### Cloud surface

No first-party Windsurf headless / cloud agent identified. Windsurf 2.0 (April 2026) integrates Devin via Cognition AI, but Devin runs on its own infrastructure — out of scope for this generator. Treat Windsurf as a local target.

## MCP cross-agent compatibility — quick truth table

Confirmed against primary sources, April 2026:

| Agent | stdio | Streamable HTTP | SSE | OAuth | Config location |
|---|---|---|---|---|---|
| Cursor CLI / IDE | yes | yes | yes | not documented | `.cursor/mcp.json` (project), `~/.cursor/mcp.json` (global) |
| Cursor Background Agent (cloud) | partial / broken | partial / broken | partial / broken | no | `cursor.com/agents` UI only — no API |
| Copilot Coding Agent | yes | yes | yes | **no** | GitHub repo settings UI (no committed file) |
| Copilot IDE Chat | yes | yes | yes | yes | `.vscode/mcp.json` |
| Codex CLI | yes | yes | not listed | unclear | `~/.codex/config.toml`, `.codex/config.toml` |
| Codex Cloud | unverified | unverified | unverified | unverified | unverified |
| Gemini CLI | yes | yes | yes | not documented | `~/.gemini/settings.json`, `.gemini/settings.json` |
| Windsurf (local) | yes | yes | yes | yes | `~/.codeium/windsurf/mcp_config.json` (global only) |

**No `mcp.json` location is read by more than one agent natively.** Each agent walks its own paths. The shared `mcpServers` JSON object structure (`command`, `args`, `env`) is a de-facto cross-tool format for stdio servers, but the file paths and surrounding wrappers differ. Confirmed by [MCP cross-agent overview](https://platform.uno/blog/mcp-configuration-across-ai-agents/).

The generator therefore emits **multiple MCP files** — one per agent — from a single `mcp-servers.yaml`. There's no shortcut.

## Cross-cutting: CI verification of generated content

Every sibling repo gets a workflow `mrploch/ploch-github-actions/ai-config-check@v1` that runs:

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-dotnet@v4
- run: dotnet tool restore
- run: dotnet ai-config check --strict
```

Failure modes:
- `out-of-date` — a canonical edit landed in `mrploch-development` but the per-repo files were never regenerated.
- `extra-files` — someone hand-edited a generator-managed file. Diagnostic includes the edited file path.
- `missing-files` — generator-managed file deleted.
- `validation-error` — V12 or V13 tripped (OAuth on Copilot Coding Agent, or missing `COPILOT_MCP_` prefix).

Should run in under 5 seconds — parse + emit + compare in memory.

## Cross-cutting: generator-as-cron pattern

For sibling repos that have been quiet, regenerated content can fall behind canonical:

```yaml
# Emitted into each sibling repo by the generator
name: ai-config sweep

on:
  workflow_dispatch:
  schedule:
    - cron: '0 6 * * 1'   # Monday 06:00 UTC

jobs:
  sweep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: mrploch/ploch-github-actions/ai-config-sweep@v1
        with:
          canonical-repo: mrploch/mrploch-development
          canonical-ref: main
          create-pr: true
          pr-title: 'chore: regenerate AI agent config'
```

A canonical edit lands once; PRs flow into siblings on the next sweep without manual intervention.

## Cross-cutting: pre-commit hook (optional)

```yaml
# .pre-commit-config.yaml stub the generator can emit
repos:
  - repo: local
    hooks:
      - id: ai-config-check
        name: ai-config check
        entry: dotnet ai-config check
        language: system
        pass_filenames: false
        files: ^\.(claude|cursor|github|windsurf|gemini)/|^(AGENTS|CLAUDE|GEMINI)\.md$
```

Off by default; enabled per-developer.

## Open questions (post-research)

1. **`.cursor/skills/` schema.** Mirror Claude's skill folder layout, or follow whatever the Cursor SDK beta defines? Decision deferred until the SDK leaves beta and the schema stabilises.
2. **Copilot org-level MCP allowlist.** The generator can flag entries with `runs_in.copilot-coding-agent: true` and recommend them, but it cannot read the org's MCP allowlist via API to verify they're actually permitted. The check stays advisory until that API exists.
3. **Codex Cloud MCP.** If OpenAI ships MCP support to Codex Cloud during this design's lifetime, drop the "MCP unsupported in cloud" caveat and emit Codex MCP config blocks. Re-evaluate quarterly.
4. **Snapshot export of ContextStream — pull vs push.** Pull (generator queries at emit-time) is simpler but ties freshness to local development cadence. Pull is the Phase 5 default; revisit if it gets in the way.
5. **Auth secret distribution for cloud-agent workflows.** `CURSOR_API_KEY`, `OPENAI_API_KEY`, etc. need to land in every sibling repo's secrets. Pattern: org-level GitHub Actions secrets, referenced from emitted workflows. Public repos need explicit secret-scope configuration.

---

## Summary of generator deliverables for cloud-agent support

| Deliverable | Phase | Notes |
|---|---|---|
| `audience: cloud-safe` filter logic | 1 | core IR feature |
| `runs_in.<cloud-target>` MCP filtering | 1 | core IR feature |
| `.github/copilot-instructions.md` + `.instructions/*` emitter | 3 | cheapest cloud win |
| Cloud-safe `AGENTS.md` (codex-cloud variant) | 3 | reuses codex emitter with `cloud_mode: true` |
| `.cursor/rules/*.mdc` emitter (editor + Background-Agent UI consumption) | 3 | reuses cursor emitter |
| Cloud-safe `.cursor/mcp.json` | 3 | filtered subset |
| `.cursor/skills/*` emitter (SDK-driven flows) | 4 | depends on SDK schema stabilising |
| `.github/copilot-mcp.recommended.md` advisory file | 3 | because Copilot MCP is settings-UI only |
| OAuth + `COPILOT_MCP_*` validation (V12, V13) | 3 | hard validators |
| `.ai-context/` snapshot export | 5 | opt-in; depends on local ContextStream availability |
| `mrploch/ploch-github-actions/cursor-cloud-agent` composite action | 5 | uses Cursor CLI install + headless `--print` |
| `ai-config-check` workflow template | 1 | CI verification of drift |
| `ai-config sweep` scheduled workflow template | 5 | decouples canonical edits from per-repo cycles |

---

## Sources (verified April 2026)

**Cursor**
- [Cursor CLI](https://cursor.com/cli)
- [Cursor CLI headless](https://cursor.com/docs/cli/headless)
- [Cursor CLI GitHub Actions](https://cursor.com/docs/cli/github-actions)
- [Cursor Rules docs](https://cursor.com/docs/context/rules)
- [Cursor SDK announcement](https://cursor.com/blog/typescript-sdk)
- [Cursor Cloud Agents blog](https://cursor.com/blog/cloud-agents)
- [Cursor environment.json reference](https://stevekinney.com/courses/ai-development/cursor-environment-configuration)
- [Cursor forum: Cloud Agents + MCP](https://forum.cursor.com/t/cloud-agents-mcp/152033)
- [MarkTechPost — Cursor SDK coverage, 2026-04-29](https://www.marktechpost.com/2026/04/29/cursor-introduces-a-typescript-sdk-for-building-programmatic-coding-agents-with-sandboxed-cloud-vms-subagents-hooks-and-token-based-pricing/)

**GitHub Copilot Coding Agent**
- [Custom instructions support reference](https://docs.github.com/en/copilot/reference/custom-instructions-support)
- [Extending coding agent with MCP](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/extending-copilot-coding-agent-with-mcp)
- [MCP and coding agent concepts](https://docs.github.com/en/copilot/concepts/agents/coding-agent/mcp-and-coding-agent)
- [Changelog: AGENTS.md support, 2025-08-28](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)
- [Changelog: .instructions.md support, 2025-07-23](https://github.blog/changelog/2025-07-23-github-copilot-coding-agent-now-supports-instructions-md-custom-instructions/)

**OpenAI Codex**
- [AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)
- [Config reference](https://developers.openai.com/codex/config-reference)
- [MCP docs](https://developers.openai.com/codex/mcp)

**Google Gemini**
- [Gemini Code Assist agent mode](https://developers.google.com/gemini-code-assist/docs/use-agentic-chat-pair-programmer)
- [Gemini CLI configuration](https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html)
- [Gemini CLI MCP](https://geminicli.com/docs/tools/mcp-server/)

**Windsurf**
- [Cascade memories/rules](https://docs.windsurf.com/windsurf/cascade/memories)
- [Cascade MCP](https://docs.windsurf.com/windsurf/cascade/mcp)

**MCP cross-agent**
- [MCP server handbook 2026 (Apify)](https://use-apify.com/blog/mcp-server-handbook-2026)
- [MCP JSON configuration standard](https://gofastmcp.com/integrations/mcp-json-configuration)
- [MCP configuration across AI agents (Uno Platform)](https://platform.uno/blog/mcp-configuration-across-ai-agents/)
- [AGENTS.md community spec](https://github.com/agentsmd/agents.md)
