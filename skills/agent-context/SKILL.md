---
name: agent-context
description: "Cross-agent context file conventions. Use when generating or updating CLAUDE.md, AGENTS.md, .cursorrules, or vault:config.md."
user-invocable: false
---

# Agent Context Conventions

Reference knowledge for generating and maintaining cross-agent context files.

## Canonical Source

`vault:config.md` is the single source of truth for all vault conventions. It contains:

1. **Folder Conventions** -- PARA structure, folder purposes, routing rules
2. **Frontmatter Spec** -- required fields per note type
3. **Linking Rules** -- how notes reference each other
4. **Agent Instructions** -- rules for any AI agent working in the vault

All other context files are pointers to `vault:config.md`, not duplicates of its content.

## Context File Roles

| File | Read By | Content |
|------|---------|---------|
| `vault:config.md` | All agents | Full vault conventions (canonical source) |
| `CLAUDE.md` | Claude Code | Vault context pointer + active project listings |
| `AGENTS.md` | Cursor, Gemini CLI, other markdown-aware agents | Vault context pointer + conventions summary |
| `.cursorrules` | Cursor | Mirrors AGENTS.md content for Cursor compatibility |

## Generation Rules

- All generated context files MUST include `generated: YYYY-MM-DD` in YAML frontmatter
- Content must be deterministic and structured (not AI prose)
- CLAUDE.md includes an "Active Projects" section (populated by `/vault:sync` in Phase 3)
- AGENTS.md serves Cursor, Gemini CLI, and any markdown-aware agent
- `.cursorrules` mirrors AGENTS.md content exactly

## CLAUDE.md Structure

```markdown
## Vault Context
This directory is an Obsidian vault managed by the vault plugin.
Read `vault:config.md` for folder conventions, frontmatter spec, linking rules, and agent instructions.

## Active Projects
(populated by /vault:sync in Phase 3)
```

## AGENTS.md Structure

```markdown
## Vault Context
This directory is an Obsidian vault managed by the vault plugin.
Read `vault:config.md` for folder conventions, frontmatter spec, linking rules, and agent instructions.
```

## Update Protocol

When vault structure changes (new projects, archived items, convention updates):
1. Update `vault:config.md` first (it is the canonical source)
2. Regenerate CLAUDE.md, AGENTS.md, and .cursorrules from vault:config.md
3. Update the `generated:` timestamp in all regenerated files
4. Never manually edit generated files -- always regenerate from source
