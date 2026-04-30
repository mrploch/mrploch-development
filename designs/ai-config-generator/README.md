# `ai-config-generator` — design sketch

**Status:** draft, 2026-04-30
**Author:** Krzysztof Płoch (drafted with Claude)
**Related:** [`mrploch/mrploch-development#8`](https://github.com/mrploch/mrploch-development/issues/8) — sync strategy for Claude Code / agentic tooling config across sibling repos

## TL;DR

A single canonical source of AI-agent configuration in `mrploch-development/` (rules, skills, agents, MCP server lists), plus a generator that emits **per-agent** views of that source into every sibling repo:

- `AGENTS.md` (OpenAI Codex CLI + Codex Cloud + most "AGENTS.md-aware" tools)
- `CLAUDE.md` + `.claude/rules/*.md` + `.claude/skills/*/SKILL.md` (Claude Code)
- `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` (GitHub Copilot — IDE *and* Coding Agent)
- `GEMINI.md` (Gemini Code Assist / Gemini CLI)
- `.cursor/rules/*.mdc` (Cursor — local IDE *and* Background Agents)
- `.windsurf/rules/*.md` (Windsurf / Codeium)
- `.mcp.json` / `.cursor/mcp.json` / `.github/copilot/mcp/` (per-agent MCP server configs, fanned out from one canonical list)

Issue #8 settles **how** canonical content reaches each repo (junctions + bootstrap script). This design adds the **what** — a translation layer so the canonical content is authored *once* in a tool-agnostic form and emitted into the heterogeneous filenames each agent insists on.

The design also covers cloud agents (Cursor Background Agents via Cursor Agents SDK, GitHub Copilot Coding Agent, Codex Cloud) — what *can* be made consistent, and what genuinely cannot.

---

## Why this exists

Today the user maintains, in parallel:

| File | Consumer |
|---|---|
| `CLAUDE.md` | Claude Code |
| `.claude/rules/*.md` | Claude Code |
| `.claude/skills/<name>/SKILL.md` | Claude Code |
| `.claude/agents/*.md` | Claude Code sub-agents |
| `.mcp.json` | Claude Code MCP servers |
| `AGENTS.md` | Codex CLI / Codex Cloud / many AGENTS.md-aware tools |
| `GEMINI.md` | Gemini Code Assist / Gemini CLI |
| `.cursorrules` *(legacy)* + `.cursor/rules/*.mdc` *(modern)* + `.cursor/mcp.json` | Cursor (local + Background Agents) |
| `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` | GitHub Copilot (IDE + Coding Agent) |
| `.windsurf/rules/*.md` | Windsurf (Codeium) |

The current working tree of `ploch-common` has eight of these files modified at the same time as part of routine ContextStream rule edits. **That is the symptom this design treats.** The cause is that one logical change ("update the ContextStream startup rule") has to be hand-copied into eight files with different schemas, headings, and conventions. Drift happens silently — and *some* per-agent variation is correct (Codex Cloud has no MCP, so MCP rules don't belong in `AGENTS.md`).

A generator solves both ends: write once, emit appropriately, drop content blocks that don't apply to a given target.

---

## Non-goals

- **Not a propagation mechanism.** Issue #8 covers the file-level "how does the content reach a sibling repo" question. This design assumes one of options A/B/C from #8 and runs upstream of it.
- **Not a config aggregator across users/teams.** Personal-machine settings (`~/.claude/settings.json`, `~/.codex/config.toml`) stay personal. The generator is repo-scoped.
- **Not an MCP server itself.** The generator is offline/build-time; it doesn't run as an agent.
- **Not a Claude-skill-runner replacement for cloud agents.** Cloud agents that lack a Skill tool simply get inlined instructions — the generator does *not* try to emulate dynamic skill matching.

---

## Goals

| # | Goal | Acceptance |
|---|---|---|
| G1 | One canonical source of rules, skills, agents, MCP lists. | Editing one file changes every consumer in every repo on next regenerate. |
| G2 | Per-target emitters with explicit, auditable mapping rules. | Each target has a documented schema mapping. Diff between regenerates is reviewable. |
| G3 | Audience markers in canonical content. | A block can be tagged `audience: claude-only`, `audience: cloud-safe`, etc. Generator filters. |
| G4 | MCP server fan-out by capability. | One canonical server list; emitters output the cloud-safe subset for cloud agents and the full set for local agents. |
| G5 | Cloud-agent automation hooks. | Documented patterns to invoke Cursor Agents SDK / Copilot Coding Agent / Codex CLI from CI with the generator's output already in place. |
| G6 | CI verification of drift. | A repo-level workflow re-runs the generator and fails if `git diff` is non-empty. |
| G7 | Cheap to extend. | Adding a new target agent (e.g. JetBrains AI Assistant) is "add an emitter class + fixtures", not a refactor. |

Non-goals stated separately above.

---

## Architecture

```
                 ┌─────────────────────────────────┐
                 │  mrploch-development/.claude/   │ ← canonical source
                 │   rules/*.md   (+frontmatter)   │
                 │   skills/*/SKILL.md             │
                 │   agents/*.md                   │
                 │   mcp-servers.yaml              │
                 │   audience-tags.yaml            │
                 └────────────────┬────────────────┘
                                  │
                  ┌───────────────▼────────────────┐
                  │  Parser → Intermediate Form    │
                  │   (typed model, unit-tested)   │
                  └───────────────┬────────────────┘
                                  │
              ┌─────────┬─────────┼──────────┬─────────┐
              ▼         ▼         ▼          ▼         ▼
          Claude     Codex     Copilot     Cursor   Windsurf
          emitter   emitter   emitter     emitter   emitter
              │         │         │          │         │
              ▼         ▼         ▼          ▼         ▼
       per-repo .claude/   AGENTS.md   .github/...   .cursor/   .windsurf/
       (and CLAUDE.md)     (+ nested)  + mcp.json    rules+mcp  rules
```

Three pieces:

1. **Canonical source** in `mrploch-development/.claude/` (per issue #8 option C). Authored as plain markdown with extended frontmatter. One subtree per concept.
2. **Parser → IR**: builds a typed in-memory model from the source. Validates frontmatter, audience tags, MCP server entries, skill triggers.
3. **Emitters**: one per target agent. Each takes the IR and writes target-shaped files under a destination repo path. Pure functions of the IR.

The generator is a **dotnet local tool** (`Ploch.AiConfig.Tool` or similar) registered in `.config/dotnet-tools.json`. Reasons for this choice over Node, Python, PowerShell are below in [Implementation tech](#implementation-tech).

Operating modes:

- `dotnet ai-config emit --repo .` — regenerate per-agent files in the current repo from the workspace canonical source.
- `dotnet ai-config emit --all` — fan out across every repo listed in `mrploch-development/repositories/sibling-repos.yaml`.
- `dotnet ai-config validate` — parse the canonical source, run schema checks, emit nothing. CI-friendly.
- `dotnet ai-config check` — emit to a temp dir and compare against the in-tree files. Exits non-zero on drift. CI-friendly.
- `dotnet ai-config diff` — like `check` but prints a unified diff for human review.

---

## Canonical source layout

```
mrploch-development/.claude/
  rules/
    agent.md               ← Pre/post-code workflow (cross-tool)
    branch-naming.md       ← Cross-tool
    commits.md             ← Cross-tool
    code-quality.md        ← Cross-tool
    naming.md              ← Cross-tool
    pr-descriptions.md     ← Cross-tool
    project-structure.md   ← Cross-tool
    documentation.md       ← Cross-tool
    rules.md               ← Cross-tool (rules-about-rules / sync process)
    qa.md                  ← Cross-tool
    summaries.md           ← Cross-tool

    contextstream.md       ← Claude-only (uses mcp__contextstream__*)
    pr-checks-completion-gate.md ← Cross-tool but Claude-flavoured
    todo-tasks-execution.md      ← Mostly cross-tool

    # Domain rules — only relevant in some repos
    data-access.md         ← scope: ploch-data, ploch-lists, ploch-groupmatters
    data-project.md        ← scope: ditto
    data-provider-project.md ← scope: ditto
    domain-model.md        ← scope: ditto
    sample-apps.md         ← scope: ditto
    writing-dotnet-tests.md ← scope: all .NET repos

  skills/
    commit/SKILL.md
    pr/SKILL.md
    review-pr/SKILL.md
    review-pr-comments/SKILL.md
    implement/SKILL.md
    implement-issue/SKILL.md
    qa-explore/SKILL.md
    prompt-lookup/SKILL.md
    dotnet-dev-practical/SKILL.md
    dotnet-dev-finishing-touches/SKILL.md

  agents/
    *.md                   ← Claude sub-agent definitions (Claude-only by nature)

  mcp-servers.yaml         ← Canonical MCP server list (capability-tagged)
  config/
    audience.yaml          ← Audience tag definitions and inclusion matrices
    targets.yaml           ← Per-target file paths, header templates, escape settings
    repos.yaml             ← Sibling-repo metadata: scope tags, generator opt-in/out
```

### Frontmatter convention

Every canonical rule and skill carries extended YAML frontmatter:

```yaml
---
name: commits                      # required, lowercase, kebab-case
description: >
  Conventional Commits standard for all repos in the workspace.
audience: [cross-tool]             # see audience.yaml
scope: [all]                       # repo-scope tag(s); 'all' or repo names
rule_type: rule | skill | agent | meta
applies_to:                        # optional: globs that scope to file paths
  - "**/*.cs"
  - "**/*.csproj"
priority: normal | high | critical # used by emitters that support priority
front_matter_extras:               # passthrough for target-specific frontmatter
  cursor:
    alwaysApply: true
  copilot:
    applyTo: "**"
---

# Body content in ordinary markdown.
# Optional inline audience markers:

<!-- begin: claude-only -->
This block is emitted to Claude Code only.
<!-- end: claude-only -->
```

Audience tag values are defined in `config/audience.yaml`:

```yaml
audiences:
  cross-tool:
    description: Safe for any AI agent.
    targets: [claude, codex, copilot, gemini, cursor, windsurf]
  claude-only:
    targets: [claude]
  cursor-only:
    targets: [cursor]
  cloud-safe:
    description: Works in cloud sandboxes (no local-process MCP, no desktop apps).
    targets: [codex-cloud, copilot-coding-agent, cursor-bg-agent]
  ide-only:
    description: Has UI assumptions; not for headless cloud agents.
    targets: [claude, cursor, copilot-ide]
```

A block visible to N audiences is emitted to the union of their targets.

### Skills with non-portable triggers

Claude skills support a `Skill` tool, dynamic discovery via descriptions, and matchers. Cursor has glob-based `applyTo`. Codex/Gemini/Copilot have nothing comparable. The IR captures both:

```yaml
---
name: dotnet-dev-finishing-touches
audience: [cross-tool]
trigger:
  description: >
    Last-mile quality pass for .NET branches before merging.
  keywords: [finishing touches, finalise PR, polish branch]
  globs: ["**/*.cs", "**/*.csproj"]
emit_strategy:
  claude: skill              # → .claude/skills/dotnet-dev-finishing-touches/SKILL.md
  cursor: rule_with_glob     # → .cursor/rules/dotnet-dev-finishing-touches.mdc with applyTo
  copilot: instructions_file # → .github/instructions/dotnet-dev-finishing-touches.instructions.md
  codex: agents_section      # → AGENTS.md "Finishing touches" section
  gemini: gemini_section     # → GEMINI.md section
  windsurf: rule             # → .windsurf/rules/dotnet-dev-finishing-touches.md
---
```

The IR records the *user's intent* (matchers, keywords, globs) and per-target `emit_strategy` decides what each target gets. For agents without dynamic discovery, the body is included unconditionally — with a header explaining when to apply it.

---

## Per-target emitter spec

Each emitter is a pure function `(IR, TargetConfig) → FileTree`. Targets and their idiosyncrasies (full schema mapping table is in [`emitter-targets.md`](emitter-targets.md)):

### 1. Claude Code

**Outputs:**

- `<repo>/CLAUDE.md` — top-level orientation file. Renders the high-priority rules plus links to `.claude/rules/*.md`.
- `<repo>/.claude/rules/<name>.md` — one file per `rule_type: rule` IR entry whose audience includes `claude`.
- `<repo>/.claude/skills/<name>/SKILL.md` — one folder per `rule_type: skill` IR entry whose audience includes `claude`. Folder lets skill carry attachments.
- `<repo>/.claude/agents/<name>.md` — one file per `rule_type: agent`.
- `<repo>/.mcp.json` — synthesised from `mcp-servers.yaml` filtered by `target: claude`.

**Schema notes:** Claude reads `description` from frontmatter to decide skill relevance; preserve it verbatim. Tool list (`tools:`) for sub-agents passes through unchanged.

**Coupling note:** if issue #8 lands with junctions, this emitter writes into `mrploch-development/.claude/`-emitted-form, not directly into each sibling repo. Compose with the chosen propagation strategy.

### 2. OpenAI Codex (CLI + Cloud)

**Outputs:**

- `<repo>/AGENTS.md` — flat single-file concatenation of every cross-tool rule + every skill body whose audience includes `codex`. Section headings derived from rule names. Skills become `## Skill: <name>` sections with the `description` and `body` inlined.
- `<repo>/.github/AGENTS.md` *(optional, mirror)* — only if `targets.yaml` enables it.

**Schema notes:** AGENTS.md walks up from edited files; nested `AGENTS.md` files override or augment. Generator can emit nested AGENTS.md per directory if `applies_to` globs are tight (e.g. one in `tests/` and one in `src/`).

**MCP:** AGENTS.md *describes* MCP servers but Codex CLI configures them via `~/.codex/config.toml` (personal). Codex Cloud has its own setup-script flow. Generator emits a documentation-only "Available MCP tools" section listing only `cloud-safe` servers.

### 3. GitHub Copilot (IDE Chat + Coding Agent)

**Outputs:**

- `<repo>/.github/copilot-instructions.md` — repository-wide instructions. Concatenation of cross-tool rules + Copilot-relevant skills.
- `<repo>/.github/instructions/<name>.instructions.md` — per-skill or per-area file with `applyTo` glob frontmatter when the IR entry has `applies_to` globs.
- `<repo>/.github/copilot-mcp.recommended.md` — **advisory only**, not consumed by Copilot. Lists cloud-safe MCP servers in paste-ready blocks for the maintainer to enter via the GitHub Settings UI (Settings → Copilot → Cloud agent → MCP). The Coding Agent does not read MCP from a committed file.

**Schema notes:** `.github/instructions/*.instructions.md` requires only the `applyTo` frontmatter (single string glob, not array). Generator joins multiple globs with `,` per Copilot syntax. IDE Copilot Chat reads `.github/copilot-instructions.md`; Coding Agent reads it plus the per-area `.instructions.md` files plus root `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`. See [`cloud-agents.md`](cloud-agents.md) for the [confirmed reference table](https://docs.github.com/en/copilot/reference/custom-instructions-support).

**MCP validators (V12, V13):** the generator hard-fails when an MCP server is `runs_in.copilot-coding-agent: true` *and* either uses OAuth (Coding Agent does not support OAuth-authenticated MCP) or uses an env-var name that doesn't match `COPILOT_MCP_*` (Coding Agent secret-scoping requirement).

### 4. Gemini Code Assist / Gemini CLI

**Outputs:**

- `<repo>/GEMINI.md` — single concatenated file, similar to AGENTS.md. Audience `gemini` or `cross-tool`.

**Schema notes:** Gemini reads markdown only; no frontmatter convention. Generator strips frontmatter, prepends a generated header.

### 5. Cursor (IDE + Background Agents)

**Outputs:**

- `<repo>/.cursor/rules/<name>.mdc` — one file per IR entry whose audience includes `cursor`. Frontmatter mapped from IR:
  - `description` ← IR `description`
  - `globs` ← IR `applies_to`
  - `alwaysApply` ← IR `front_matter_extras.cursor.alwaysApply`
- `<repo>/.cursor/skills/<name>/...` — folder per skill, mirroring the Claude skill layout. The [Cursor TypeScript SDK](https://cursor.com/blog/typescript-sdk) (public beta, April 2026) prefers `.cursor/skills/` over `.cursor/rules/` for SDK-driven flows. The generator emits both so editor users get rules and SDK users get skills.
- `<repo>/.cursor/mcp.json` — full set for local Cursor; cloud-safe subset for `cursor-bg-agent` (filtered by `runs_in.cursor-bg-agent: true`).
- `<repo>/.cursorrules` — **deprecated**, generator emits a one-line redirect comment if `targets.yaml` requests legacy support.

**Cloud-agent caveats** (see [`cloud-agents.md`](cloud-agents.md) for sources):
- Cursor Background Agents are configured via `.cursor/environment.json` (not generator-managed — it's repo-specific toolchain setup).
- MCP for Background Agents is **partially broken** — configurable in the `cursor.com/agents` UI but not via the Cloud Agents API. Whether `.cursor/rules/*.mdc` are honoured by Background Agents is unconfirmed; the generator emits them anyway because they're free, but cloud-agent automation should not depend on them and should pass instructions inline via the prompt.

### 6. Windsurf (Codeium)

**Outputs:**

- `<repo>/.windsurf/rules/<name>.md` — frontmatter mapped (Windsurf supports `description`, `trigger`, `globs`). One file per IR entry whose audience includes `windsurf`.

### 7. Other (future)

- JetBrains AI Assistant
- Continue.dev
- Aider
- Anything else with a per-repo instruction file

Adding a target = drop in a new emitter that consumes the IR. No core changes.

---

## MCP server fan-out

`mrploch-development/.claude/mcp-servers.yaml` is the single registry. Each entry is capability-tagged:

```yaml
servers:
  - id: contextstream
    transport: stdio                # stdio | http | sse
    command: ["npx", "@contextstream/mcp"]
    deps: [local-desktop, contextstream-app]   # capability tags
    env:
      CONTEXTSTREAM_PROJECT: "${REPO_NAME}"
    runs_in:
      claude: true
      codex-cli: true
      cursor-local: true
      cursor-bg-agent: false        # cloud sandbox can't reach local desktop
      copilot-coding-agent: false
      codex-cloud: false
    notes: |
      Talks to a desktop application running on the user's machine.
      Cannot run in any cloud sandbox.

  - id: github
    transport: http
    url: https://api.githubcopilot.com/mcp
    auth: oauth
    deps: [internet]
    runs_in:
      claude: true
      codex-cli: true
      cursor-local: true
      cursor-bg-agent: true
      copilot-coding-agent: true
      codex-cloud: true

  - id: context7
    transport: http
    url: https://mcp.context7.com/mcp
    deps: [internet]
    runs_in:
      claude: true
      codex-cli: true
      cursor-local: true
      cursor-bg-agent: true
      copilot-coding-agent: true
      codex-cloud: true
```

Each emitter renders the MCP file format its target expects, filtered by the `runs_in` flag for that target. The generator validates that **every** local-only server is excluded from cloud-target MCP files — this is the safety net against accidentally shipping a stdio server to a cloud agent that can't run it.

---

## Cloud agent automation

This is where the design earns its keep. Three cloud agents matter; each plugs in differently. *(Specifics on each will be refined once the research agent's report lands; see [`cloud-agents.md`](cloud-agents.md) for the live notes.)*

### Cursor Background Agents — via Cursor Agents SDK

**Hypothesis** (to be confirmed by research): Cursor offers a programmatic SDK / `cursor-agent` CLI that can be invoked from a GitHub Actions runner to launch a Background Agent against a checked-out branch with custom prompt and MCP servers.

**Why this matters here:** if true, the generator's job is not only "emit `.cursor/rules/*.mdc`" but also "emit a `.github/workflows/cursor-bg-agent.yml` that uses the SDK to run agent tasks against the same canonical instructions". One fewer place to drift.

**Pattern proposed:**

```yaml
# .github/workflows/cursor-bg-agent.yml (generated)
on:
  issue_comment:
    types: [created]

jobs:
  cursor:
    if: contains(github.event.comment.body, '/cursor')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm i -g cursor-agent           # placeholder — depends on actual SDK distribution
      - run: cursor-agent run \
              --rules .cursor/rules \
              --mcp .cursor/mcp.json \
              --prompt "${{ github.event.comment.body }}"
        env:
          CURSOR_API_KEY: ${{ secrets.CURSOR_API_KEY }}
```

The point: the *same* `.cursor/rules/` and MCP config emitted by the generator drive both the local IDE Cursor and the cloud Background Agent.

### GitHub Copilot Coding Agent

**Pattern:** the agent reads `.github/copilot-instructions.md` + `.github/instructions/*.instructions.md` from the branch when it runs. The generator already emits these. No additional automation needed in CI — the agent runs server-side when an issue is assigned to Copilot.

**Constraint:** MCP servers usable by the Coding Agent must be HTTP/remote. The generator filters with `runs_in: copilot-coding-agent: true`. Anything else is silently dropped.

**Verification:** a `dotnet ai-config check --target copilot-coding-agent` in CI catches drift.

### OpenAI Codex Cloud

**Pattern:** Codex Cloud reads `AGENTS.md` from the repo root and runs a `setup_script` (configurable in the cloud UI / `.codex/setup.sh`). The generator emits a `cloud-safe`-filtered `AGENTS.md`. ContextStream-style instructions are dropped because the canonical content is tagged `audience: claude-only` for those blocks.

**Constraint:** No MCP for Codex Cloud as of this writing. The generator emits an "Available tools" section in AGENTS.md that documents what's *available locally* and notes "not available in Codex Cloud" — useful when the same repo is also worked by users running Codex CLI.

### Cross-cutting: snapshot export for cloud agents

Cloud agents can't reach ContextStream / local MCP. A clean fallback: the generator can optionally emit a **frozen snapshot** of recent decisions/lessons into a committed file:

```
<repo>/.ai-context/
  decisions.md            ← from `mcp__contextstream__memory(action="decisions")`
  lessons.md              ← from `mcp__contextstream__session(action="get_lessons")`
  recent-architecture.md  ← from a curated query
```

`AGENTS.md` then ends with: *"For prior context not in this file, consult `.ai-context/decisions.md` and `.ai-context/lessons.md`."* Cloud agents read these via plain file access. Snapshot export is an opt-in feature flag; default off (the user may not want lessons/decisions in public OSS history).

---

## Implementation tech

**Recommendation: dotnet local tool.** Trade-offs:

| Option | Pros | Cons |
|---|---|---|
| **dotnet local tool (chosen)** | Same toolchain as everything else here. Strong typing for the IR. Easy to hook into MSBuild and add a target like `BeforeBuild`. Distributed via `.config/dotnet-tools.json` like `nbgv`. | Requires .NET on contributors' machines — but that's already true for these repos. |
| Node CLI | Cheap to write. Good YAML/markdown ecosystem. | Adds a Node dependency to repos that don't have one. |
| Python CLI | Same as Node. | Same as Node. |
| PowerShell | Already used for `bootstrap-claude.ps1` (issue #8). | Weak typing, hard to test, terrible CI portability. |
| GitHub Action | "Just works" in CI. | Needs an out-of-band tool for local dev too — duplicates effort. |

A dotnet tool also lets us share IR types with potential analyzers / Roslyn tooling later.

**Project layout:**

```
mrploch-development/src/Ploch.AiConfig/
  Ploch.AiConfig.Core/           ← parser + IR + emitters (library)
    Parsing/
    Ir/
    Emitters/
      ClaudeEmitter.cs
      CodexEmitter.cs
      CopilotEmitter.cs
      CursorEmitter.cs
      WindsurfEmitter.cs
      GeminiEmitter.cs
    Validation/
  Ploch.AiConfig.Tool/           ← dotnet tool (CLI entry point)
  Ploch.AiConfig.Tests/          ← unit tests with rich fixtures
    Fixtures/canonical-source/
    Fixtures/expected-claude/
    Fixtures/expected-codex/
    ...
```

**Testing strategy:** snapshot tests using `Verify` against a representative canonical source. Each emitter has its own fixture set. Snapshot-based regression catches silent format drift.

**Parsing:** `Markdig` for markdown AST, `YamlDotNet` for frontmatter. Shared parser produces typed IR.

**CI integration:** `dotnet ai-config check` in every sibling repo's `build-dotnet.yml` workflow. Fails if the in-tree files don't match what the generator would produce now.

**Local dev integration:** an MSBuild target imported from `mrploch-development/dependencies/AiConfig.targets` that runs `dotnet ai-config emit --repo .` on `BeforeBuild` if `RegenerateAiConfig=true`. Off by default to keep builds fast.

---

## Phased rollout

### Phase 0 — close issue #8 first

The generator depends on a settled "where is the canonical source" answer. Pick option C (junctions) or B (committed copies) before building the generator. The generator works either way but emitter-output paths differ slightly.

### Phase 1 — minimum viable generator (1 week-ish)

- `Ploch.AiConfig.Core` with parser + IR + Claude emitter only.
- `dotnet ai-config emit --repo .` regenerates `.claude/rules/`, `.claude/skills/`, `CLAUDE.md`.
- `dotnet ai-config check` for CI.
- Tested against `ploch-common` only.

This phase already pays back: every Claude-rule edit becomes one-place edits.

### Phase 2 — second target

Add the **Codex emitter** (AGENTS.md). Validate by regenerating `mrploch-development/AGENTS.md` and `ploch-data/AGENTS.md`. Diff-review the result with the user.

### Phase 3 — cloud-relevant targets

Add **Copilot emitter** + **Cursor emitter**. These unlock cloud-agent consistency. Adds the MCP fan-out logic.

### Phase 4 — long tail

Gemini, Windsurf, JetBrains, etc. as needed.

### Phase 5 — automation polish

- CI workflow templated into every sibling repo (via `ploch-templates-dotnet-repository`).
- Cursor Agents SDK invocation pattern (if research confirms feasibility).
- Snapshot export for cloud agents.

---

## Open questions

1. **Should the canonical source live in `mrploch-development/.claude/` or in a new sibling like `mrploch-development/ai-config/`?** `.claude/` is recognised by Claude when the user opens `mrploch-development` itself, which is convenient. But it conflates "config the user runs" with "config the generator templates from". A separate `ai-config/` is cleaner conceptually. Decision deferred to issue #8 implementation.
2. **Audience tag granularity.** The `cloud-safe` tag conflates Codex Cloud, Copilot Coding Agent, and Cursor BG Agent. They have slightly different sandbox capabilities. For most rules this doesn't matter; for MCP it does (already handled by `runs_in`). Worth revisiting after Phase 3.
3. **How to handle skill bodies that are *very* tool-specific?** Some Claude skills call `mcp__contextstream__*` directly. If `audience: claude-only` is honest, fine — the body is dropped from other targets. But sometimes you want a "cross-tool version" with the same intent and a Claude-specific implementation. The IR could support per-target body overrides — useful but expensive in maintenance. Keep simple for Phase 1; revisit in Phase 4.
4. **ContextStream snapshot export — push or pull?** Should the generator query ContextStream MCP at emit-time (pull), or should ContextStream emit on its own schedule (push)? Pull is simpler but ties generator runs to the user's running ContextStream. Push is decoupled but needs ContextStream itself to grow this feature. Punt to Phase 5.
5. **Per-repo overrides and exemptions.** Currently `repos.yaml` controls scope tags but not per-repo block-level exclusions. Probably fine — if a rule needs to vary per repo, it should split into two canonical files or use audience/scope tags. Re-examine if it gets in the way.
6. **Deterministic output.** Markdown emitters must produce byte-identical output across runs (no timestamps, no random ordering). Mandatory for the `check` mode to work in CI. Test it explicitly.
7. **Canonical extension format for skills with attachments.** Some Claude skills bundle helper scripts (`SKILL.md` + `helper.py`). Decide whether `mrploch-development/.claude/skills/<name>/` mirrors that structure 1:1 or flattens. Probably 1:1.

---

## Alternatives considered (and why not)

- **Symlinks-only, no generator.** Issue #8 option C alone — propagate canonical Claude config via junctions and stop there. Doesn't solve "Codex Cloud needs `AGENTS.md` not `.claude/rules/`". Leaves manual translation in place.
- **One file per repo with includes.** Have a single `instructions.md` with `<!-- include: cross-tool/agent.md -->` directives that each agent processes. Nice idea, but no agent supports include directives consistently — they'd just see literal text.
- **Run Claude / Cursor in a "translate" mode at edit-time.** Use an agent to translate one source into all targets. Non-deterministic, untestable, expensive. Bad idea.
- **GitHub Action that watches `mrploch-development/.claude/` and opens PRs across siblings.** Could work as a delivery mechanism *in addition to* the generator, not as a replacement.
- **Vendor the generator into each repo.** Each repo carries its own copy of the tool. Bloat without benefit; central `mrploch-development` works fine.

---

## Concrete next actions

1. Land issue #8 propagation strategy (option C, probably).
2. Stand up canonical source skeleton at `mrploch-development/.claude/` per the layout above (move from per-repo locations; see sweep checklist in issue #8 acceptance criteria).
3. Spike `Ploch.AiConfig.Core` Claude-only emitter against `ploch-common` and confirm round-trip equality with hand-written content for a one-off regeneration.
4. Wire `dotnet ai-config check` into `ploch-common`'s `build-dotnet.yml`.
5. Add Codex emitter; regenerate `AGENTS.md` for the workspace + 2 sibling repos; review the diff together.
6. Iterate on the Cloud-agent automation patterns once the research agent's findings (filed as `cloud-agents.md`) are merged into this design.

---

## Companion docs

- [`ir-schema.md`](ir-schema.md) — full canonical-source schema spec
- [`emitter-targets.md`](emitter-targets.md) — per-target field-mapping table
- [`cloud-agents.md`](cloud-agents.md) — cloud-agent automation patterns and Cursor SDK research notes
