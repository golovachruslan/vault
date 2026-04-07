# vault

A Claude Code plugin for AI-agent-friendly Obsidian vault management.

Designed for engineers managing multiple projects who want both humans and AI agents to have structured, instant access to project information. Any AI agent session starts with full, accurate context about all active projects -- no re-explaining needed.

## What it does

- **Vault setup** -- Initialize a new vault or adapt an existing one with PARA folder structure (Projects, Areas, Resources, Archive), note templates, and agent context files
- **Quick capture** -- Capture notes with smart destination routing that suggests the right location (project, area, or inbox)
- **Inbox organization** -- Triage inbox notes with per-item destination proposals and user confirmation before any file moves
- **Project dashboards** -- Create or refresh project folders with category subfolders (architecture/, requirements/, decisions/, notes/) and linked Dashboard.md + Tasks.md
- **Context generation** -- Auto-generate CLAUDE.md, AGENTS.md, and .cursorrules so Claude Code, Cursor, Gemini CLI, and other agents get instant vault context
- **Vault health** -- Proactive suggestions for orphaned notes, stale dashboards, missing links, tag inconsistencies, and MOC candidates

## Current status

**v1.0.0-alpha** -- Phase 1 (Foundation + Setup) is complete. Phase 2 (Daily Workflows) and Phase 3 (Context + Analysis) are in progress.

| Command | Status |
|---------|--------|
| `/vault:init` | Available |
| `/vault:capture` | Planned (Phase 2) |
| `/vault:organize` | Planned (Phase 2) |
| `/vault:project` | Planned (Phase 2) |
| `/vault:sync` | Planned (Phase 3) |
| `/vault:suggest` | Planned (Phase 3) |

## Installation

### From marketplace

```
/plugin marketplace add golovachruslan/vault
/plugin install vault@vault-plugins
/reload-plugins
```

### From local clone (for development)

```bash
git clone git@github.com:golovachruslan/vault.git
cd vault
```

Then from Claude Code:

```
/plugin marketplace add ./
/plugin install vault@vault-plugins
/reload-plugins
```

Or load directly for a single session without installing:

```bash
claude --plugin-dir ./
```

## Requirements

- [Claude Code](https://claude.ai/code) (latest version with plugin support)
- No additional dependencies -- the plugin uses Claude's built-in file tools (Read, Write, Bash, Glob, Grep)

## How it works

- **Skills** define slash commands (`/vault:init`, `/vault:capture`, etc.) as markdown files with frontmatter
- **Hooks** run at session start to detect the vault and inject context automatically
- **Reference skills** (`schema`, `agent-context`) provide vault conventions that Claude uses when creating or organizing notes -- not invoked directly by users
- All vault content is plain markdown files with YAML frontmatter, compatible with Obsidian and any markdown editor
- Everything stays local on your machine -- no cloud services, no sync, no external dependencies

## Constraints

- **Local-only**: All data stays on your machine as plain .md files
- **Non-destructive**: The setup wizard never moves or renames existing files without explicit approval
- **Cross-agent**: Context files work for Claude Code, Cursor, Gemini CLI, and any markdown-aware agent
- **Complementary**: Works alongside existing Obsidian plugins (obsidian-skills, claude-pro-skills) without duplicating their features

## License

MIT
