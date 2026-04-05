# Phase 1: Foundation + Setup - Research

**Researched:** 2026-04-04
**Domain:** Claude Code plugin scaffolding + Obsidian vault initialization (PARA method)
**Confidence:** HIGH

## Summary

Phase 1 delivers two things: the plugin scaffold (plugin.json, skill directories, hooks skeleton) and the `/vault:init` skill that creates or adapts an Obsidian vault with PARA folder structure, core templates, and a machine-readable `vault:config.md`. This is a greenfield project -- no existing plugin code exists. The vault directory itself already has a PARA folder structure (`00 Inbox/` through `40 Daily Notes/`), an `organization.md` with vault rules, basic templates, and MOCs created during early exploration. The plugin must be built from scratch, but the vault content provides a working reference for conventions.

The plugin format is well-documented by Anthropic (verified against official docs at code.claude.com, April 2026). The critical pattern is: `.claude-plugin/plugin.json` at plugin root, `skills/` and `agents/` and `hooks/` directories at the same level (NOT inside `.claude-plugin/`). Skills use `SKILL.md` files with YAML frontmatter. Hooks use `hooks/hooks.json`. Dependencies install lazily via a SessionStart hook into `${CLAUDE_PLUGIN_DATA}`.

**Primary recommendation:** Build the plugin scaffold first (plugin.json + skill directories), then implement `/vault:init` as a single user-invoked skill that handles both greenfield and brownfield paths with explicit user approval before any file mutation.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Auto-detect + confirm flow. Wizard detects if a vault exists, proposes the full structure, user approves in one shot. No multi-step interactive Q&A.
- **D-02:** CWD is the vault. User runs `/vault:init` inside their Obsidian vault directory. No path argument needed.
- **D-03:** Brownfield: propose migration. When existing vault detected, suggest moving existing notes into PARA structure with user confirming each move. Not just additive -- actively helps restructure.
- **D-04:** vault:config.md encodes ALL four convention types: folder conventions, frontmatter spec, linking rules, and agent instructions.
- **D-05:** Pointer + file pattern. CLAUDE.md and AGENTS.md say "Read vault:config.md for conventions" -- the full spec lives in a separate file, not inlined.
- **D-06:** SKILL.md only -- no legacy commands/ directory. All slash commands are user-invocable skills.
- **D-07:** One skill per command. Each command gets its own skill directory: vault-init/, vault-capture/, vault-organize/, vault-project/, vault-suggest/, vault-sync/.
- **D-08:** Auto-invoked reference skills (vault-schema, agent-context, vault-analysis) are separate non-user-invocable skills that provide knowledge to commands and agents.

### Claude's Discretion
- Template content details (specific sections, frontmatter fields for the 3 core templates) -- Claude decides based on research and Obsidian conventions.

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SETUP-01 | User can run `/vault:init` to scaffold a new vault with PARA folder structure (inbox/, daily/, projects/, areas/, resources/, archive/, templates/) | Plugin scaffold pattern verified; PARA folder structure documented; greenfield path uses mkdir + Write tools |
| SETUP-02 | User can run `/vault:init` on an existing vault and the wizard detects existing structure, proposes additions non-destructively | Brownfield pattern documented in ARCHITECTURE.md and PITFALLS.md; skill uses Glob + Read first, presents diff-style proposal, gates writes on user confirmation |
| SETUP-03 | Setup wizard creates core note templates in the vault's templates/ folder (project dashboard, task list, inbox note) | Existing templates in `20 Templates/` provide baseline; new templates (project dashboard with category subfolders, task list) need to be designed per Claude's discretion |
| SETUP-04 | Plugin generates a `vault:config.md` referenced from CLAUDE.md and AGENTS.md so any agent knows the vault conventions | vault:config.md design verified; existing `organization.md` provides content baseline; pointer pattern (CLAUDE.md references config, not inlines it) per D-05 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code Plugin format | Current (2026-04) | Plugin container | Official distribution mechanism. `.claude-plugin/plugin.json` at root. Verified against code.claude.com April 2026. |
| SKILL.md skills | -- | Slash commands (`/vault:init`) | Canonical skill format. Supports frontmatter, supporting files, `$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`. Replaces legacy `commands/`. |
| Plain markdown (.md) | -- | All vault content, templates, config | Obsidian-native. Cross-agent compatible. No cloud dependencies. |
| Bash scripts | sh/bash | Hook handlers, utility scripts | Hook `type: command` calls shell. Zero install overhead. Scripts at `${CLAUDE_PLUGIN_ROOT}/scripts/`. |

### Supporting (Phase 1 does NOT need npm dependencies)
Phase 1 creates folders, writes markdown files, and generates config. All operations use Claude's built-in Read/Write/Bash/Glob tools. No gray-matter, fast-glob, or js-yaml needed until Phase 2+ when programmatic frontmatter parsing is required.

The `package.json` and SessionStart lazy-install hook should still be scaffolded in Phase 1 so the infrastructure is ready, but no `npm install` runs yet.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SKILL.md skills | Legacy `commands/*.md` | Never -- skills strictly supersede commands per D-06 |
| Plain markdown templates | Handlebars/Mustache | Overkill for v1 -- plain markdown with `{{date}}` placeholder is sufficient |
| Bash script for folder creation | Node.js script | Bash is simpler for mkdir operations; Node.js adds startup latency |

## Architecture Patterns

### Plugin Directory Structure
```
vault/                              # Plugin root (also the git repo root)
├── .claude-plugin/
│   └── plugin.json                 # ONLY plugin.json goes here
│
├── skills/
│   │   # --- User-invoked skills (Phase 1) ---
│   ├── vault-init/
│   │   ├── SKILL.md                # /vault:init -- setup wizard
│   │   └── templates/              # Bundled note templates
│   │       ├── project-dashboard.md
│   │       ├── task-list.md
│   │       └── inbox-note.md
│   │
│   │   # --- Stub directories for future phases ---
│   ├── vault-capture/
│   │   └── SKILL.md                # Stub: /vault:capture (Phase 2)
│   ├── vault-organize/
│   │   └── SKILL.md                # Stub: /vault:organize (Phase 2)
│   ├── vault-project/
│   │   └── SKILL.md                # Stub: /vault:project (Phase 2)
│   ├── vault-suggest/
│   │   └── SKILL.md                # Stub: /vault:suggest (Phase 3)
│   ├── vault-sync/
│   │   └── SKILL.md                # Stub: /vault:sync (Phase 3)
│   │
│   │   # --- Auto-invoked reference skills ---
│   ├── vault-schema/
│   │   └── SKILL.md                # Vault structure knowledge (user-invocable: false)
│   └── agent-context/
│       └── SKILL.md                # Agent context conventions (user-invocable: false)
│
├── agents/                         # Empty for Phase 1 -- agents come in Phase 2+
│
├── hooks/
│   └── hooks.json                  # SessionStart hook skeleton (no-op for Phase 1)
│
├── scripts/
│   └── session-init.sh             # Skeleton: lazy dependency install + context injection
│
├── package.json                    # Dependencies for future phases (gray-matter, fast-glob)
└── README.md
```

### Pattern 1: Auto-Detect + Confirm Setup Flow (D-01, D-02)
**What:** The `/vault:init` skill detects existing vault state via Glob/Read, generates a complete proposal, and presents it to the user for one-shot approval.
**When to use:** Always -- this is the only setup flow.
**Example:**
```markdown
# skills/vault-init/SKILL.md frontmatter
---
name: vault-init
description: Initialize or adapt an Obsidian vault with PARA structure, templates, and agent context files
disable-model-invocation: true
allowed-tools: Read Write Bash Glob Grep
argument-hint: "[--dry-run]"
---
```

The skill body instructs Claude to:
1. Check CWD for existing vault markers (`.obsidian/`, `organization.md`, numbered folders)
2. Scan existing structure with Glob
3. Build a proposal: folders to create, templates to install, config to generate
4. For brownfield: include migration suggestions (D-03)
5. Present the complete proposal to the user
6. Execute only after user confirms

### Pattern 2: Pointer + File for Conventions (D-05)
**What:** `vault:config.md` contains the full convention spec. CLAUDE.md and AGENTS.md contain a short pointer: "Read vault:config.md for vault conventions."
**When to use:** Always -- keeps CLAUDE.md small, avoids drift.
**Example:**
```markdown
# CLAUDE.md (generated by /vault:init)
## Vault Context
This directory is an Obsidian vault managed by the vault plugin.
Read `vault:config.md` for folder conventions, frontmatter spec, linking rules, and agent instructions.

## Active Projects
(populated by /vault:sync in Phase 3)
```

### Pattern 3: Non-User-Invocable Reference Skills (D-08)
**What:** Skills with `user-invocable: false` that Claude loads automatically when context matches their description.
**When to use:** For domain knowledge (vault structure rules, PARA routing logic) that Claude should know when relevant but users should not invoke directly.
**Example:**
```yaml
# skills/vault-schema/SKILL.md
---
name: vault-schema
description: Vault folder structure, PARA routing rules, frontmatter conventions, and naming standards. Use when creating, moving, or organizing notes in this vault.
user-invocable: false
---
```

### Anti-Patterns to Avoid
- **Placing directories inside `.claude-plugin/`:** Only `plugin.json` goes there. Skills, agents, hooks at plugin root.
- **Running npm install at plugin root:** Dependencies go to `${CLAUDE_PLUGIN_DATA}` via lazy SessionStart hook.
- **Writing CLAUDE.md as AI prose:** Must be deterministic, structured markdown. Use `generated:` timestamp.
- **Moving files without confirmation gate:** Every file operation in brownfield path requires explicit user approval.
- **Deeply nested YAML frontmatter:** Obsidian's property panel handles flat YAML only. Keep frontmatter flat.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML frontmatter parsing | Custom regex parser | `gray-matter` (Phase 2+) | Edge cases with multiline values, quotes, special chars |
| Vault file discovery | Custom recursive walk | Claude's built-in `Glob` tool | Already available, handles ignore patterns |
| Template rendering | Custom string substitution engine | Plain markdown with `{{date}}` placeholder | Obsidian's Templater and core templates use this convention |
| Plugin directory structure | Manual setup | Follow official docs exactly | One wrong directory placement silently breaks everything |

## Common Pitfalls

### Pitfall 1: Plugin Directory Misplacement
**What goes wrong:** Skills/agents/hooks placed inside `.claude-plugin/` instead of at plugin root. Commands silently do nothing.
**Why it happens:** Intuitive to put everything in the named plugin container. Official docs state only `plugin.json` goes inside.
**How to avoid:** Follow the directory structure above exactly. Run `claude --plugin-dir ./ --debug` to verify all commands register.
**Warning signs:** Slash commands appear in `/help` but do not execute, or do not appear at all.

### Pitfall 2: Brownfield Vault Destruction
**What goes wrong:** Setup wizard moves/renames existing files without per-file user approval. Wikilinks break silently.
**Why it happens:** Tested only against empty vaults. Assumption that "better structure" justifies automatic migration.
**How to avoid:** Discovery-only mode first (Glob + Read). Present diff-style proposal. Gate every file operation on user confirmation. Offer frontmatter-based overlay (add `project:` tags) instead of moving files.
**Warning signs:** Setup code contains `mv` or rename calls without a confirmation gate. No brownfield tests.

### Pitfall 3: vault:config.md Becomes Stale Organization.md Copy
**What goes wrong:** vault:config.md is generated once during init and never updated. Conventions drift as users add folders and change patterns.
**Why it happens:** Config is treated as a setup artifact, not a living document.
**How to avoid:** Include a `generated:` timestamp. Design vault:config.md as the source of truth that organization.md conventions derive from (or vice versa -- pick one canonical source and make the other a pointer). For Phase 1, vault:config.md IS the canonical conventions file.
**Warning signs:** Two files (organization.md and vault:config.md) defining the same conventions with different content.

### Pitfall 4: Hook Script Not Executable
**What goes wrong:** SessionStart hook script exists but is not `chmod +x`. Hook fails silently -- no error message, no context injection.
**Why it happens:** Forgot to run `chmod +x` after creating the script. Git may not preserve execute bits depending on config.
**How to avoid:** Add `chmod +x scripts/*.sh` as a post-create step. Include `.gitattributes` with `scripts/*.sh eol=lf` and ensure execute bit is tracked.
**Warning signs:** `claude --debug` shows hook registered but never fires.

### Pitfall 5: Template Conflicts with Existing Vault
**What goes wrong:** `/vault:init` overwrites user's existing templates in `20 Templates/` with plugin versions.
**Why it happens:** Init assumes templates don't exist. Writes without checking.
**How to avoid:** Check for existing templates before writing. If a template exists, propose the new version alongside the existing one (e.g., "Project Dashboard Template.md" vs existing "Project Template.md"). Never overwrite without confirmation.
**Warning signs:** User's customized templates replaced after running init.

## Code Examples

### plugin.json (verified against official docs, April 2026)
```json
{
  "name": "vault",
  "version": "1.0.0",
  "description": "AI-agent-friendly Obsidian vault management -- setup, capture, organize, and context generation",
  "author": {
    "name": "Ruslan Halavach"
  }
}
```
Source: https://code.claude.com/docs/en/plugins

### SKILL.md for /vault:init (user-invoked, destructive operation)
```yaml
---
name: vault-init
description: Initialize or adapt an Obsidian vault with PARA structure, templates, and agent context files
disable-model-invocation: true
allowed-tools: Read Write Bash Glob Grep
argument-hint: "[--dry-run]"
---
```
Source: https://code.claude.com/docs/en/skills

### SKILL.md for vault-schema (auto-invoked reference skill)
```yaml
---
name: vault-schema
description: Vault folder structure, PARA routing rules, frontmatter conventions, and naming standards. Use when creating, moving, or organizing notes in this vault.
user-invocable: false
---
```
Source: https://code.claude.com/docs/en/skills

### hooks.json skeleton (SessionStart)
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/session-init.sh"
          }
        ]
      }
    ]
  }
}
```
Source: https://code.claude.com/docs/en/hooks

### session-init.sh skeleton (Phase 1 -- lazy install only, no context injection yet)
```bash
#!/usr/bin/env bash
# Lazy dependency installation for future phases
# Context injection will be added in Phase 3
diff -q "${CLAUDE_PLUGIN_ROOT}/package.json" "${CLAUDE_PLUGIN_DATA}/package.json" >/dev/null 2>&1 || \
  (cd "${CLAUDE_PLUGIN_DATA}" && cp "${CLAUDE_PLUGIN_ROOT}/package.json" . && npm install --silent) || \
  rm -f "${CLAUDE_PLUGIN_DATA}/package.json"
```
Source: https://code.claude.com/docs/en/plugins (lazy install pattern)

### vault:config.md structure (D-04: all four convention types)
```markdown
---
type: vault-config
generated: 2026-04-04
plugin-version: 1.0.0
---

# Vault Configuration

## Folder Conventions
[PARA structure with numbered prefixes, folder definitions]

## Frontmatter Spec
[Required fields per note type: type, tags, status, created, etc.]

## Linking Rules
[Projects link to areas, areas list projects, resources stay passive, etc.]

## Agent Instructions
[When creating notes: read this file first, place in correct folder, include frontmatter, update MOCs, never nest >1 level deep, use templates]
```

### Project Dashboard Template (Claude's discretion -- recommended design)
```markdown
---
type: project
status: active
area: "[[]]"
tags: []
created: {{date}}
updated: {{date}}
---

# {{title}}

## Overview
What is this project and what does done look like?

## Status
- **Phase:**
- **Priority:**
- **Last updated:** {{date}}

## Tasks
- [ ]

## Key Links
- Architecture: [[]]
- Requirements: [[]]
- Decisions: [[]]

## Notes
-

## References
-
```

### Task List Template (Claude's discretion -- recommended design)
```markdown
---
type: task-list
project: "[[]]"
tags: []
created: {{date}}
updated: {{date}}
---

# Tasks: {{title}}

## Active
- [ ]

## Completed
- [x]

## Blocked
- [ ] [BLOCKED]
```

### Inbox Note Template (matches existing pattern)
```markdown
---
type: inbox
tags: []
created: {{date}}
---

#

-
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `commands/*.md` flat files | `skills/<name>/SKILL.md` with frontmatter | 2025 (Claude Code skills launch) | Skills supersede commands; support directories, frontmatter, context: fork |
| Hooks in `settings.json` | `hooks/hooks.json` in plugin root | 2025 (plugin hooks) | Plugins manage their own hooks independently |
| Manual `CLAUDE.md` maintenance | Generated CLAUDE.md with `generated:` timestamp | 2026 (best practice) | Deterministic generation prevents drift |
| Single context file for all agents | CLAUDE.md + AGENTS.md + .cursorrules | 2026 (AGENTS.md standard) | Each agent tool reads its own file; shared content in separate vault:config.md |

## Open Questions

1. **Plugin name vs namespace collision**
   - What we know: Plugin name `vault` creates namespace `/vault:init`, `/vault:capture` etc.
   - What's unclear: Whether user has any other plugin named `vault` installed that would conflict.
   - Recommendation: Use `vault` as the name. If collision discovered during testing, rename to `obsidian-vault`.

2. **vault:config.md vs organization.md redundancy**
   - What we know: The vault already has `organization.md` with comprehensive conventions. D-04 requires `vault:config.md`.
   - What's unclear: Whether to migrate organization.md content into vault:config.md and deprecate organization.md, or keep both.
   - Recommendation: vault:config.md becomes the canonical source. During brownfield init, detect organization.md and offer to merge its content into vault:config.md. Keep organization.md as a read-only alias that says "See vault:config.md".

3. **Existing templates coexistence**
   - What we know: Vault already has `Project Template.md`, `Inbox Note Template.md`, `Daily Note Template.md`, `Resource Template.md` in `20 Templates/`.
   - What's unclear: Whether to replace them with richer versions or add new templates alongside.
   - Recommendation: Add new templates (Project Dashboard, Task List) without overwriting existing ones. Offer to upgrade existing Project Template to the richer Project Dashboard format.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Lazy dependency install (future) | Yes | v22.18.0 | -- |
| npm | Lazy dependency install (future) | Yes | 11.5.2 | -- |
| Claude Code CLI | Plugin testing | Yes | 2.1.92 | -- |
| bash | Hook scripts | Yes | (system) | -- |

**Missing dependencies with no fallback:** None -- all required tools are available.

## Project Constraints (from CLAUDE.md)

- **Plugin format**: Must be a Claude Code plugin (plugin.json, commands, skills, agents, hooks)
- **Local-only**: All data stays on the user's machine as plain .md files
- **Cross-agent**: Context files must work for Claude Code, Cursor, Gemini CLI, and any markdown-aware agent
- **Non-destructive**: Brownfield vault setup must never move or rename existing files without explicit user approval
- **Fast context loading**: Agents shouldn't need to scan hundreds of files -- use pre-generated index and CLAUDE.md
- **SKILL.md only**: No legacy commands/ directory (D-06)
- **No Python scripts**: Bash for simple scripts, Node.js for complex parsing
- **No deeply nested YAML frontmatter**: Flat frontmatter only
- **No MCP server for v1**: Use Claude's built-in file tools
- **No file watchers / chokidar**: On-demand commands only
- **GSD Workflow**: All code changes through GSD commands

## Sources

### Primary (HIGH confidence)
- [Claude Code Plugins docs](https://code.claude.com/docs/en/plugins) -- Plugin manifest schema, directory structure, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` (fetched 2026-04-04)
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) -- SKILL.md frontmatter fields, invocation control, `$ARGUMENTS`, supporting files, `${CLAUDE_SKILL_DIR}` (fetched 2026-04-04)
- [Claude Code Hooks docs](https://code.claude.com/docs/en/hooks) -- SessionStart hook format, hookSpecificOutput schema, 10K char injection cap (fetched 2026-04-04)
- [Claude Code Sub-agents docs](https://code.claude.com/docs/en/sub-agents) -- Agent frontmatter fields, tools/disallowedTools, model options (fetched 2026-04-04)
- Existing vault at `/Users/ruslanhalavach/Documents/Projects/vault/` -- organization.md, templates, folder structure (LOCAL)

### Secondary (MEDIUM confidence)
- `.planning/research/ARCHITECTURE.md` -- Component boundaries, data flow, project structure (researched 2026-03-28)
- `.planning/research/PITFALLS.md` -- Brownfield destruction risk, plugin directory rules, CLAUDE.md drift (researched 2026-03-28)
- `.planning/research/FEATURES.md` -- Feature dependencies, MVP definition (researched 2026-03-28)
- `.planning/research/STACK.md` -- Stack recommendations, version compatibility (researched 2026-03-28)

### Tertiary (LOW confidence)
- None -- all findings verified against official docs or local filesystem.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- verified against official Claude Code docs (April 2026)
- Architecture: HIGH -- plugin format verified; directory structure confirmed; existing vault provides concrete reference
- Pitfalls: HIGH -- documented in prior research and verified against official warnings in plugin docs

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (plugin format is stable; 30-day validity)
