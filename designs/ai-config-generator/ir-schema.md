# `ai-config-generator` — IR & canonical-source schema

This document specifies the canonical-source layout and the in-memory intermediate representation (IR) the parser produces. It is the contract between the canonical source (what authors write) and the emitters (what each target agent receives).

## Source-tree contract

```
mrploch-development/.claude/
  rules/<name>.md                 ← rule documents
  skills/<name>/SKILL.md          ← skills (folders allow attachments)
  skills/<name>/<attachment>      ← optional helper files for a skill
  agents/<name>.md                ← Claude sub-agent definitions
  mcp-servers.yaml                ← MCP server registry
  config/audience.yaml            ← audience tag definitions
  config/targets.yaml             ← per-target output settings
  config/repos.yaml               ← sibling-repo metadata
```

The parser refuses any file under `.claude/` that doesn't match this layout. Stray files are loud failures, not silent skips.

## Frontmatter — full schema

All `rules/*.md`, `skills/*/SKILL.md`, and `agents/*.md` files MUST start with YAML frontmatter delimited by `---` lines. Schema:

```yaml
# ── Required fields ───────────────────────────────────────────
name: string                       # kebab-case identifier; must equal the file basename
description: string                # one-line summary; used by tools that support skill discovery
rule_type: rule | skill | agent | meta
audience: [audience-tag, ...]      # values defined in config/audience.yaml

# ── Optional fields ───────────────────────────────────────────
scope: [scope-tag, ...]            # repo-scope tags from config/repos.yaml; defaults to ["all"]
priority: low | normal | high | critical
applies_to: [glob, ...]            # path globs; emitters that support globs use these
trigger:                           # only meaningful for rule_type: skill
  description: string
  keywords: [string, ...]
  globs: [glob, ...]               # optional override of applies_to for trigger purposes
emit_strategy:                     # per-target emission hint; emitter-specific keys
  claude: skill | rule | inline
  cursor: rule_with_glob | rule_always | omit
  copilot: instructions_file | repository_instructions | omit
  codex: agents_section | omit
  gemini: gemini_section | omit
  windsurf: rule | omit
front_matter_extras:               # passthrough fields injected into the target's frontmatter
  cursor:
    alwaysApply: bool
    globs: [string, ...]           # overrides applies_to in cursor output
  copilot:
    applyTo: string                # single comma-joined glob string
  windsurf:
    trigger: always | manual | model_decision
deprecates: [name, ...]            # list of older rule/skill names this replaces
references: [name, ...]            # rules/skills that should be linked from this one
```

The body — everything after the closing `---` — is markdown.

### Validation rules

| # | Rule | Failure mode |
|---|---|---|
| V1 | `name` matches file basename. | hard error |
| V2 | `name` is kebab-case (`^[a-z][a-z0-9-]*$`). | hard error |
| V3 | `audience` is a non-empty list of known audience tags. | hard error |
| V4 | `rule_type` matches the source folder (`rules/` ⇒ rule; `skills/` ⇒ skill; `agents/` ⇒ agent). | hard error |
| V5 | `applies_to` globs parse as valid globs. | hard error |
| V6 | Skill `trigger.description` exists. | hard error |
| V7 | `emit_strategy` keys are known target names. | hard error |
| V8 | `references` resolve to existing canonical names. | warning unless `--strict` |
| V9 | Body contains no inline audience markers nested incorrectly. | hard error |
| V10 | `deprecates` names exist somewhere in archived history (informational). | warning |

## Inline audience markers

Bodies may carry per-block audience filters:

```markdown
Some general guidance everyone gets.

<!-- begin: claude-only -->
Use the `Skill` tool to invoke the brainstorming skill.
<!-- end: claude-only -->

<!-- begin: cloud-safe -->
For cloud agents, write decisions to a committed `.ai-context/decisions.md` file.
<!-- end: cloud-safe -->

Continued shared content.
```

Rules:

- `begin:` and `end:` markers must match. Nesting is forbidden — fail validation V9.
- Tag names match `audience.yaml`.
- The same block may be tagged multiple times: `<!-- begin: claude-only,cursor-only -->` ⇒ union of the targets.

## Audience tags

`config/audience.yaml`:

```yaml
audiences:
  cross-tool:
    description: Safe for any AI agent.
    targets: [claude, codex, copilot, gemini, cursor, windsurf]

  claude-only:
    description: Uses Claude-specific features (Skill tool, ContextStream MCP, sub-agents).
    targets: [claude]

  cursor-only:
    description: Uses Cursor-specific UI affordances (fetch_rules tool, Composer flows).
    targets: [cursor]

  cloud-safe:
    description: Works in cloud sandboxes — no local-process MCP, no desktop apps.
    targets: [codex-cloud, copilot-coding-agent, cursor-bg-agent]

  ide-only:
    description: Assumes a UI; not for headless cloud agents.
    targets: [claude, cursor, copilot-ide]

  copilot-coding-agent-only:
    description: Specific to GitHub Copilot Coding Agent flows (issue assignment, PR creation).
    targets: [copilot-coding-agent]
```

The set of targets is closed; adding one is a config change. The closure makes filter logic auditable.

## Per-target output settings

`config/targets.yaml`:

```yaml
targets:
  claude:
    enabled: true
    output:
      orientation_file: CLAUDE.md
      rules_dir: .claude/rules/
      skills_dir: .claude/skills/
      agents_dir: .claude/agents/
      mcp_file: .mcp.json
    options:
      include_skill_index_in_orientation: true
      preserve_frontmatter_extras: true

  codex:
    enabled: true
    output:
      flat_file: AGENTS.md
    options:
      emit_nested_agents_md_for_globs: false   # phase 4 candidate
      include_mcp_section: true
      mcp_section_title: "Available MCP tools"

  copilot:
    enabled: true
    output:
      repo_instructions: .github/copilot-instructions.md
      per_skill_instructions_dir: .github/instructions/
      mcp_file: .github/copilot/mcp.json
    options:
      one_file_per_skill: true
      use_applyTo_globs: true

  gemini:
    enabled: true
    output:
      flat_file: GEMINI.md

  cursor:
    enabled: true
    output:
      rules_dir: .cursor/rules/
      mcp_file: .cursor/mcp.json
      legacy_cursorrules: false                # set true to emit a redirect comment
    options:
      use_alwaysApply: true

  windsurf:
    enabled: true
    output:
      rules_dir: .windsurf/rules/

  codex-cloud:
    enabled: true
    inherits: codex
    options:
      cloud_mode: true                         # forces cloud-safe filter on MCP and audience

  copilot-coding-agent:
    enabled: true
    inherits: copilot
    options:
      cloud_mode: true

  cursor-bg-agent:
    enabled: true
    inherits: cursor
    options:
      cloud_mode: true
```

`inherits` lets a cloud variant share output paths with its IDE sibling but layer on `cloud_mode: true`, which the IR honours by:

- filtering MCP servers via `runs_in.<target>` flags
- filtering inline-audience blocks
- never emitting attachments that aren't safe to commit (e.g. `.contextstream/` snapshots)

## Repos config

`config/repos.yaml`:

```yaml
repos:
  ploch-common:
    path: ../ploch-common
    scope_tags: [common, library, foundation]
    targets: [claude, codex, copilot, gemini, cursor]
    snapshot_export: false

  ploch-data:
    path: ../ploch-data
    scope_tags: [common, library, data]
    targets: [claude, codex, copilot, gemini, cursor, windsurf]
    snapshot_export: false

  ploch-lists:
    path: ../ploch-lists
    scope_tags: [application, data]
    targets: [claude, codex, copilot]

  ploch-ai-tools:
    path: ../ploch-ai-tools
    scope_tags: [application, mcp-server]
    targets: [claude, codex]

  # ... 12 more siblings ...
```

A canonical entry's `scope: [data]` means it's only emitted into repos whose `scope_tags` includes `data`. A canonical entry's default `scope: [all]` is emitted everywhere the target is enabled.

`targets` in `repos.yaml` is the **opt-in list** for that repo — anything not listed gets no output. Default if omitted: `[claude, codex, copilot]`.

## MCP server registry

`mcp-servers.yaml` — full schema:

```yaml
servers:
  - id: string                        # kebab-case identifier
    transport: stdio | http | sse
    command: [string, ...]            # required for stdio
    url: string                       # required for http / sse
    env: { string: string }           # passed to spawned process; `${REPO_NAME}` etc. allowed
    auth: none | api_key | oauth | bearer
    auth_env: string                  # env var name carrying the secret
    deps: [tag, ...]                  # capability tags: local-desktop, internet, github-app, etc.
    description: string
    notes: string                     # free-form markdown for "Available tools" sections
    runs_in:
      claude: bool
      codex-cli: bool
      cursor-local: bool
      cursor-bg-agent: bool
      copilot-coding-agent: bool
      copilot-ide: bool
      codex-cloud: bool
      gemini: bool
      windsurf: bool

defaults:
  runs_in:
    claude: true
    codex-cli: true
    cursor-local: true
    cursor-bg-agent: false
    copilot-coding-agent: false
    copilot-ide: true
    codex-cloud: false
    gemini: true
    windsurf: true
```

If `runs_in` is omitted on an entry, defaults apply. Defaults are deliberately conservative for cloud sandboxes — opt in explicitly with `runs_in.<cloud-target>: true`.

## IR object model (sketch)

```csharp
public sealed record CanonicalIR(
    IReadOnlyList<RuleEntry>    Rules,
    IReadOnlyList<SkillEntry>   Skills,
    IReadOnlyList<AgentEntry>   Agents,
    IReadOnlyList<McpServer>    McpServers,
    AudienceConfig              Audiences,
    TargetsConfig               Targets,
    ReposConfig                 Repos);

public abstract record CanonicalEntry(
    string                      Name,
    string                      Description,
    EntryType                   Type,
    IReadOnlySet<string>        Audience,
    IReadOnlySet<string>        Scope,
    Priority                    Priority,
    IReadOnlyList<string>       AppliesTo,
    IReadOnlyDictionary<string,EmitStrategy> Strategies,
    IReadOnlyDictionary<string,JsonNode>     FrontMatterExtras,
    string                      Body,
    IReadOnlyList<AudienceBlock> InlineBlocks);

public sealed record AudienceBlock(
    int                         StartIndex,
    int                         EndIndex,
    IReadOnlySet<string>        Audience);

public sealed record McpServer(
    string                      Id,
    Transport                   Transport,
    IReadOnlyList<string>       Command,
    string?                     Url,
    AuthMode                    Auth,
    string?                     AuthEnv,
    IReadOnlyDictionary<string,string> Env,
    IReadOnlySet<string>        Deps,
    string                      Description,
    string                      Notes,
    IReadOnlyDictionary<string,bool> RunsIn);
```

The IR is **immutable** — emitters never mutate it. They consume the IR plus a target name and produce a `FileTree` (path → bytes).

## Emitter contract

```csharp
public interface IEmitter
{
    string Target { get; }                         // e.g. "claude", "codex-cloud"

    EmitResult Emit(CanonicalIR ir, EmitContext ctx);
}

public sealed record EmitContext(
    string                      RepoPath,
    string                      RepoName,
    IReadOnlySet<string>        RepoScopeTags,
    bool                        DryRun);

public sealed record EmitResult(
    IReadOnlyDictionary<string,byte[]> Files,      // path relative to RepoPath
    IReadOnlyList<string>      Diagnostics);       // warnings/info, not failures
```

Emitter contract guarantees:

- **Determinism.** Two `Emit` calls with the same `(ir, ctx)` produce byte-identical output. No timestamps, no system-locale-dependent ordering, no random GUIDs.
- **Idempotence.** Running `emit` twice in a row leaves the working tree unchanged on the second run.
- **Purity.** Emitters do not perform I/O or call external services. The CLI host writes the `Files` dictionary to disk.
- **Auditable diagnostics.** Anything skipped (e.g. an MCP server filtered out for being local-only) appears in `Diagnostics` with a one-line reason.

These guarantees power the `check` mode (CI-friendly drift detection) and unit/snapshot tests.

## Determinism rules

To make output deterministic across machines:

- File ordering: emitters iterate IR collections sorted by `Name`.
- Map ordering: emitters serialise dictionaries with sorted keys.
- Newlines: LF only, regardless of host OS. Generator writes bytes; no `StreamWriter` text mode.
- Trailing newline: every file ends with a single LF.
- YAML: stable serialiser configured with sorted keys and explicit indent.
- Markdown: emitters use a single canonical heading style (`#` ATX, no setext).
- Generated-file header: every emitted file starts with a fixed comment containing **no timestamps and no version** — only a stable provenance line:
  ```
  <!-- generated by ai-config-generator from mrploch-development/.claude/ — do not edit -->
  ```
  The lack of a timestamp is intentional — timestamps would make `check` mode useless.
