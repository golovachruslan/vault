# Phase 1: Foundation + Setup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 01-foundation-setup
**Areas discussed:** Init wizard flow, Vault config format, Plugin structure

---

## Init Wizard Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-detect + confirm | Detect if vault exists, propose structure, user approves one shot | ✓ |
| Interactive Q&A | Ask about vault path, folder preferences, which templates to install | |
| Opinionated defaults | Just create everything with sensible defaults, user customizes after | |

**User's choice:** Auto-detect + confirm
**Notes:** None

### Brownfield Adaptation

| Option | Description | Selected |
|--------|-------------|----------|
| Additive only | Only create missing folders/files, never touch existing structure | |
| Propose migration | Suggest moving existing notes into PARA structure, user confirms each | ✓ |
| Hybrid | Add missing structure; flag mismatches but don't propose moves in v1 | |

**User's choice:** Propose migration
**Notes:** None

### Vault Path

| Option | Description | Selected |
|--------|-------------|----------|
| CWD is the vault | User runs /vault:init inside their Obsidian vault directory | ✓ |
| Ask for path | Prompt user for vault path, store in plugin config | |
| Both | Default to CWD, but allow specifying a path as argument | |

**User's choice:** CWD is the vault
**Notes:** None

---

## Vault Config Format

### Config Content (multiSelect)

| Option | Description | Selected |
|--------|-------------|----------|
| Folder conventions | Where projects, areas, resources, archive, inbox live + naming rules | ✓ |
| Frontmatter spec | Required fields (tags, status, type, date) and allowed values | ✓ |
| Linking rules | Wikilinks vs markdown links, tag format, naming | ✓ |
| Agent instructions | How agents should behave: read before writing, update MOCs, etc. | ✓ |

**User's choice:** All four types
**Notes:** None

### Reference Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Inline include | Conventions embedded directly in CLAUDE.md | |
| Pointer + file | CLAUDE.md says 'Read vault:config.md for conventions' — separate file | ✓ |
| Both generated | CLAUDE.md has summary, vault:config.md has full spec | |

**User's choice:** Pointer + file
**Notes:** None

---

## Plugin Structure

### Skills vs Commands

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, SKILL.md only | All slash commands as user-invocable skills (current best practice) | ✓ |
| You decide | Claude picks the right format based on plugin conventions | |

**User's choice:** Yes, SKILL.md only
**Notes:** None

### Skill Layout

| Option | Description | Selected |
|--------|-------------|----------|
| One skill per command | vault-init/, vault-capture/, vault-organize/ etc. | ✓ |
| Grouped by domain | vault-setup/, vault-workflow/, vault-context/ | |
| You decide | Claude picks based on conventions | |

**User's choice:** One skill per command
**Notes:** None

---

## Claude's Discretion

- Template content details (specific sections, frontmatter fields for the 3 core templates)

## Deferred Ideas

None
