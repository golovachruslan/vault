# Stack Research

**Domain:** Claude Code plugin for AI-agent-friendly Obsidian vault management
**Researched:** 2026-03-28
**Confidence:** HIGH (core plugin format verified against official docs; supporting library versions verified via npm)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code Plugin format | Current (plugin system) | Plugin container and distribution | This IS the distribution mechanism — not optional. Defines the directory structure, `plugin.json` manifest, skills, agents, hooks, and how the plugin installs into user scope or project scope. Official format: `.claude-plugin/plugin.json` at root. |
| SKILL.md skills | — | Slash commands (`/vault-setup`, `/capture`, `/organize-inbox`, etc.) | The canonical way to define `/name` commands in Claude Code plugins. Replaces legacy `commands/` flat files. Skills support frontmatter, supporting files, subagent delegation, and dynamic shell injection. Each skill is a directory with `SKILL.md`. |
| Agent markdown files | — | Specialized subagents (vault-organizer, context-generator) | `.md` files in `agents/` with YAML frontmatter (`name`, `description`, `model`, `effort`, `maxTurns`). Claude invokes them automatically or user delegates. Correct for complex multi-step tasks like inbox analysis. |
| Bash scripts | sh/bash | Hook handlers, vault scanning, CLAUDE.md generation | Hook `type: command` calls shell scripts. Scripts live in `scripts/` and are referenced via `${CLAUDE_PLUGIN_ROOT}/scripts/`. No runtime dependency needed — shell is universal on macOS/Linux. Chosen over Node.js for hooks because it adds zero install overhead. |
| Plain markdown (.md) | — | All vault content (notes, templates, CLAUDE.md, context files) | Obsidian is markdown-native. Cross-agent context files (CLAUDE.md, .cursorrules) must be plain markdown to work with Claude Code, Cursor, Gemini CLI, and any markdown-aware agent. No cloud dependencies. All stays local. |

### Supporting Libraries (for scripts that need structured parsing)

> These are optional — only needed if a hook script or skill script needs to parse/write frontmatter programmatically. The plugin itself has zero npm dependencies at install time; dependencies are managed via `${CLAUDE_PLUGIN_DATA}` and a `SessionStart` hook.

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| gray-matter | 4.0.3 | Parse and write YAML frontmatter in `.md` files | Use in any script that reads/updates note metadata (tags, status, date, type). Stable, battle-tested, used by Gatsby/Astro/VitePress. Last published 5 years ago — mature, not abandoned. |
| fast-glob | 3.x | Recursive glob traversal of vault directories | Use when scanning vault for `.md` files by pattern (e.g., `Projects/**/*.md`, `Inbox/*.md`). Significantly faster than built-in `glob` for large vaults. |
| js-yaml | 4.x | YAML serialization for writing frontmatter back to files | Use alongside gray-matter when you need to serialize updated frontmatter objects back to YAML string. gray-matter uses js-yaml internally — pin same version to avoid conflicts. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `claude --plugin-dir ./` | Test plugin locally during development | Loads the plugin for the duration of one session without installing. Essential for the inner development loop. |
| `claude plugin validate` | Validate plugin.json and frontmatter syntax | Runs schema checks on manifest, skill/agent frontmatter, and hooks.json. Run before every commit. |
| `chmod +x scripts/*.sh` | Make hook scripts executable | Hooks fail silently if the script is not executable. Must be done after any new script is added. |
| `claude --debug` | Inspect plugin loading, hook registration, MCP init | Shows which skills/agents/hooks registered. Required for debugging missing commands. |

## Installation

```bash
# No npm install at the plugin root — dependencies install lazily via SessionStart hook.
# The plugin.json SessionStart hook pattern (from official docs):

# In hooks/hooks.json:
# diff -q "${CLAUDE_PLUGIN_ROOT}/package.json" "${CLAUDE_PLUGIN_DATA}/package.json" >/dev/null 2>&1 ||
#   (cd "${CLAUDE_PLUGIN_DATA}" && cp "${CLAUDE_PLUGIN_ROOT}/package.json" . && npm install) ||
#   rm -f "${CLAUDE_PLUGIN_DATA}/package.json"

# If scripts need node dependencies (gray-matter, fast-glob):
# package.json at plugin root (not installed there — copied to CLAUDE_PLUGIN_DATA on first run):
npm install gray-matter fast-glob js-yaml  # in CLAUDE_PLUGIN_DATA, not plugin root

# Install the plugin (project scope — checked into git, available to team):
claude plugin install . --scope project

# Or user scope (personal, available across all projects):
claude plugin install . --scope user
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SKILL.md skills | Legacy `commands/*.md` flat files | Never for new plugins — skills strictly supersede commands. Existing commands still work but don't support supporting files, `context: fork`, or hooks. |
| Bash scripts for hooks | Node.js scripts for hooks | Use Node.js hook scripts only if the logic is too complex for shell and you need structured JSON manipulation beyond what `jq` handles. Node.js adds a startup latency (~100ms) on hook invocation vs. instant for bash. |
| gray-matter | remark-frontmatter | Use remark-frontmatter if you need full AST-level markdown processing (e.g., rewriting link syntax). For simple parse/update of frontmatter key-value pairs, gray-matter is lighter and does not require ESM. |
| fast-glob | Node.js built-in `fs.glob` (Node 22+) | Use built-in only if targeting Node 22+ exclusively and want zero dependencies. fast-glob is faster, more battle-tested, and supports older Node. |
| Plain markdown for templates | Handlebars/Mustache templates | Use templating engines only if template logic becomes complex (conditional blocks, loops). For v1 note templates, plain markdown with `$ARGUMENTS` substitution in skills is sufficient and avoids a dependency. |
| SessionStart hook for context injection | MCP server with vault index | Use an MCP server approach if you need real-time tool access (query the vault mid-session). For the initial context injection use case (inject CLAUDE.md summary at session start), a SessionStart hook + bash script is simpler and has no persistent process. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Obsidian community plugin (TypeScript + Obsidian API) | The project.md explicitly rules this out. Obsidian plugins run inside the Obsidian app, require the Obsidian API, and cannot be invoked from Claude Code sessions. | Claude Code plugin (this stack) |
| Automatic file watchers / `chokidar` | PROJECT.md marks automatic hook-based inbox processing as out of scope for v1. File watching adds complexity, runs continuously, and risks accidental moves before user approval. | On-demand `/organize-inbox` skill invoked by user |
| MCP server for vault access in v1 | MCP servers add a persistent subprocess and protocol overhead. v1 vault operations (read/write .md files) are fully achievable with Claude's built-in Read/Write/Bash tools via skills. MCP is appropriate if you later need transactional operations or external tool integration. | Claude's built-in file tools (Read, Write, Bash, Glob) called from skills |
| Cloud storage or sync services | PROJECT.md constraint: local-only, all data stays on user's machine. | Plain .md files on local filesystem |
| Deeply nested YAML frontmatter | Obsidian's property panel and Dataview handle flat YAML well; deeply nested objects are not rendered and not queried by standard tools. | Flat frontmatter: `tags`, `type`, `status`, `project`, `created`, `updated` |
| Python scripts for vault logic | Python 3.8+ is not guaranteed to be in PATH for all users; version conflicts are common. bash + node (via `${CLAUDE_PLUGIN_DATA}/node_modules`) is more portable. Exception: if user already uses Python as per the reference project (earlyaidopters/second-brain). | Bash for simple scripts, Node.js (via plugin data dir) for complex parsing |

## Stack Patterns by Variant

**If the plugin needs to parse/update frontmatter (e.g., tagging inbox notes):**
- Install `gray-matter` + `js-yaml` via the `SessionStart` lazy-install pattern
- Reference scripts via `${CLAUDE_PLUGIN_DATA}/node_modules` in NODE_PATH
- Because: scripts run at hook time or inside skill `context: fork` subagents — not at plugin load time

**If the plugin needs to scan large vaults (1000+ notes):**
- Add `fast-glob` to the package.json alongside gray-matter
- Because: native `find` in bash is fast enough for simple filename patterns, but fast-glob handles complex multi-pattern vault traversal more reliably and returns structured results

**If a skill needs to be user-only (e.g., `/vault-setup`, destructive operations):**
- Add `disable-model-invocation: true` to SKILL.md frontmatter
- Because: you do not want Claude autonomously running vault restructuring based on context

**If a skill is reference knowledge (e.g., vault conventions, folder structure rules):**
- Add `user-invocable: false` to SKILL.md frontmatter
- Because: conventions load automatically when relevant but `/vault-conventions` is not a meaningful user action

**If CLAUDE.md injection is dynamic (session-specific project state):**
- Use a `SessionStart` hook with `hookSpecificOutput.additionalContext` JSON output
- Because: static CLAUDE.md loads once but does not update between sessions; the hook runs after `/compact` and `/clear` too, keeping context alive

**If cross-agent context files (.cursorrules) need to differ from CLAUDE.md:**
- Generate them as separate files in the vault root from the same skill
- Because: `.cursorrules` is read by Cursor; `GEMINI.md` or `AGENTS.md` by other agents; CLAUDE.md by Claude Code — they can share content but are separate files

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| gray-matter@4.0.3 | Node.js 10+ | Stable. Uses `js-yaml` 3.x internally. If you add `js-yaml` separately, pin to 3.14.x to avoid serialization differences. |
| fast-glob@3.x | Node.js 12+ | v3.x is the stable ESM-compatible branch. Do not use v2.x (EOL). |
| js-yaml@4.x | Node.js 12+ | v4.x drops `safeLoad` (use `load` instead). Breaking from v3.x API. Choose one version and stick with it across the plugin. |
| Claude Code plugin format | Claude Code current | Verified against official docs at code.claude.com as of 2026-03-28. Skills, agents, hooks, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}` all confirmed current. |

## Key Format References

### plugin.json (minimal)
```json
{
  "name": "vault",
  "version": "1.0.0",
  "description": "AI-agent-friendly Obsidian vault management",
  "skills": "./skills/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json"
}
```

### SKILL.md frontmatter (user-only command)
```yaml
---
name: vault-setup
description: Initialize or adapt an Obsidian vault with PARA structure and AI-agent context files
disable-model-invocation: true
allowed-tools: Read Write Bash Glob
---
```

### SKILL.md frontmatter (Claude-invocable reference skill)
```yaml
---
name: vault-conventions
description: Vault folder structure, naming conventions, and frontmatter schema. Use when creating or organizing notes.
user-invocable: false
---
```

### SessionStart hook (context injection)
```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/inject-vault-context.sh"
        }
      ]
    }
  ]
}
```

The script outputs:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<content of CLAUDE.md summary>"
  }
}
```

## Sources

- [Claude Code Plugins Reference — code.claude.com](https://code.claude.com/docs/en/plugins-reference) — Plugin manifest schema, directory structure, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, hook types — HIGH confidence (official docs, fetched 2026-03-28)
- [Claude Code Skills Reference — code.claude.com](https://code.claude.com/docs/en/skills) — SKILL.md frontmatter fields, invocation control, `context: fork`, `$ARGUMENTS`, supporting files — HIGH confidence (official docs, fetched 2026-03-28)
- [Claude Code Hooks Reference — code.claude.com](https://code.claude.com/docs/en/hooks) — SessionStart JSON output schema, `hookSpecificOutput.additionalContext`, all hook event names — HIGH confidence (official docs, fetched 2026-03-28)
- [gray-matter — npm](https://www.npmjs.com/package/gray-matter) — Version 4.0.3 confirmed current, 3549 dependents, YAML/JSON/TOML support — HIGH confidence
- [fast-glob — GitHub](https://github.com/mrmlnc/fast-glob) — v3.x stable branch — HIGH confidence
- [kepano/obsidian-skills — GitHub](https://github.com/kepano/obsidian-skills) — Reference implementation: Agent Skills open standard, Obsidian-specific markdown conventions — MEDIUM confidence
- [earlyaidopters/second-brain — GitHub](https://github.com/earlyaidopters/second-brain) — Reference project: 4 slash commands, Python scripts, skills-based structure, vault folder layout — MEDIUM confidence (WebSearch verified, not directly fetched)
- [PARA Method in Obsidian — obsidianstats / forum](https://forum.obsidian.md/t/para-method-folder-structure-generator/86891) — Projects/Areas/Resources/Archives canonical structure — HIGH confidence (well-established method, multiple sources)

---
*Stack research for: Claude Code plugin — AI-agent-friendly Obsidian vault management*
*Researched: 2026-03-28*
