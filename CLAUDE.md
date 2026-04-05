<!-- GSD:project-start source:PROJECT.md -->
## Project

**vault**

A Claude Code plugin that helps users create and manage AI-agent-friendly Obsidian vaults. It provides slash commands, agents, and hooks for vault setup, quick note capture with smart routing, inbox organization, project dashboard management, proactive improvement suggestions, and auto-generated agent context files. Designed for engineers managing multiple projects who want both humans and AI agents to have structured, instant access to project information.

**Core Value:** Any AI agent session starts with full, accurate context about all active projects — no re-explaining needed.

### Constraints

- **Plugin format**: Must be a Claude Code plugin (plugin.json, commands, skills, agents, hooks)
- **Local-only**: All data stays on the user's machine as plain .md files
- **Cross-agent**: Context files must work for Claude Code, Cursor, Gemini CLI, and any markdown-aware agent
- **Non-destructive**: Brownfield vault setup must never move or rename existing files without explicit user approval
- **Fast context loading**: Agents shouldn't need to scan hundreds of files — use pre-generated index and CLAUDE.md
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

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
# No npm install at the plugin root — dependencies install lazily via SessionStart hook.
# The plugin.json SessionStart hook pattern (from official docs):
# In hooks/hooks.json:
# diff -q "${CLAUDE_PLUGIN_ROOT}/package.json" "${CLAUDE_PLUGIN_DATA}/package.json" >/dev/null 2>&1 ||
#   (cd "${CLAUDE_PLUGIN_DATA}" && cp "${CLAUDE_PLUGIN_ROOT}/package.json" . && npm install) ||
#   rm -f "${CLAUDE_PLUGIN_DATA}/package.json"
# If scripts need node dependencies (gray-matter, fast-glob):
# package.json at plugin root (not installed there — copied to CLAUDE_PLUGIN_DATA on first run):
# Install the plugin (project scope — checked into git, available to team):
# Or user scope (personal, available across all projects):
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
- Install `gray-matter` + `js-yaml` via the `SessionStart` lazy-install pattern
- Reference scripts via `${CLAUDE_PLUGIN_DATA}/node_modules` in NODE_PATH
- Because: scripts run at hook time or inside skill `context: fork` subagents — not at plugin load time
- Add `fast-glob` to the package.json alongside gray-matter
- Because: native `find` in bash is fast enough for simple filename patterns, but fast-glob handles complex multi-pattern vault traversal more reliably and returns structured results
- Add `disable-model-invocation: true` to SKILL.md frontmatter
- Because: you do not want Claude autonomously running vault restructuring based on context
- Add `user-invocable: false` to SKILL.md frontmatter
- Because: conventions load automatically when relevant but `/vault-conventions` is not a meaningful user action
- Use a `SessionStart` hook with `hookSpecificOutput.additionalContext` JSON output
- Because: static CLAUDE.md loads once but does not update between sessions; the hook runs after `/compact` and `/clear` too, keeping context alive
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
### SKILL.md frontmatter (user-only command)
### SKILL.md frontmatter (Claude-invocable reference skill)
### SessionStart hook (context injection)
## Sources
- [Claude Code Plugins Reference — code.claude.com](https://code.claude.com/docs/en/plugins-reference) — Plugin manifest schema, directory structure, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, hook types — HIGH confidence (official docs, fetched 2026-03-28)
- [Claude Code Skills Reference — code.claude.com](https://code.claude.com/docs/en/skills) — SKILL.md frontmatter fields, invocation control, `context: fork`, `$ARGUMENTS`, supporting files — HIGH confidence (official docs, fetched 2026-03-28)
- [Claude Code Hooks Reference — code.claude.com](https://code.claude.com/docs/en/hooks) — SessionStart JSON output schema, `hookSpecificOutput.additionalContext`, all hook event names — HIGH confidence (official docs, fetched 2026-03-28)
- [gray-matter — npm](https://www.npmjs.com/package/gray-matter) — Version 4.0.3 confirmed current, 3549 dependents, YAML/JSON/TOML support — HIGH confidence
- [fast-glob — GitHub](https://github.com/mrmlnc/fast-glob) — v3.x stable branch — HIGH confidence
- [kepano/obsidian-skills — GitHub](https://github.com/kepano/obsidian-skills) — Reference implementation: Agent Skills open standard, Obsidian-specific markdown conventions — MEDIUM confidence
- [earlyaidopters/second-brain — GitHub](https://github.com/earlyaidopters/second-brain) — Reference project: 4 slash commands, Python scripts, skills-based structure, vault folder layout — MEDIUM confidence (WebSearch verified, not directly fetched)
- [PARA Method in Obsidian — obsidianstats / forum](https://forum.obsidian.md/t/para-method-folder-structure-generator/86891) — Projects/Areas/Resources/Archives canonical structure — HIGH confidence (well-established method, multiple sources)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
