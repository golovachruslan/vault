# vault

## What This Is

A Claude Code plugin that helps users create and manage AI-agent-friendly Obsidian vaults. It provides slash commands, agents, and hooks for vault setup, quick note capture with smart routing, inbox organization, project dashboard management, proactive improvement suggestions, and auto-generated agent context files. Designed for engineers managing multiple projects who want both humans and AI agents to have structured, instant access to project information.

## Core Value

Any AI agent session starts with full, accurate context about all active projects — no re-explaining needed.

## Requirements

### Validated

- [x] Setup wizard that creates a new vault or adapts an existing one with the canonical folder structure (PARA + project category subfolders) — Validated in Phase 1: Foundation + Setup
- [x] Note templates for all document types: project dashboard, architecture doc, ERD, requirements/PRD, ADR, task list, inbox note, daily note — Partially validated in Phase 1 (3 core templates: project dashboard, task list, inbox note)

### Active

- [ ] Quick capture command that analyzes content and auto-suggests the right destination (project/area/inbox), creating a structured note
- [ ] On-demand inbox organization that proposes destinations for each inbox item, user confirms, agent moves and links
- [ ] Project dashboard creation/refresh with category subfolders (architecture/, requirements/, decisions/, notes/) and task tracking
- [ ] Proactive vault analysis that suggests improvements: orphaned notes, missing links, stale dashboards, tag inconsistencies, new MOC candidates
- [ ] Auto-generated CLAUDE.md summarizing active projects, recent inbox, vault map, and conventions — so any agent gets instant context
- [ ] Cross-agent context files (.cursorrules for Cursor, readable by Gemini CLI and other markdown-aware agents)
- [ ] SessionStart hook that detects vault and injects condensed project context into the session
- [ ] Note templates for all document types: project dashboard, architecture doc, ERD, requirements/PRD, ADR, task list, inbox note, daily note

### Out of Scope

- Automatic hook-based inbox processing (watching for file changes) — future improvement, v1 is on-demand
- Session-start auto-organize — future improvement
- MCP integration for Jira/Linear/external tools — v1 is manual capture only
- Real-time sync between Obsidian and external project management tools
- Obsidian plugin (community plugin for Obsidian app itself) — this is a Claude Code plugin
- Note formatting and MOC creation — handled by existing obsidian@claude-pro-skills plugin

## Context

- Engineers leading multiple projects accumulate scattered info (Jira tickets, meeting notes, ERDs, PRDs) across tools
- AI agents starting sessions have no structured context, forcing users to re-explain project state
- Reference project: github.com/earlyaidopters/second-brain — similar concept but simpler (4 slash commands, shell-based setup)
- User already has obsidian@claude-pro-skills (note creation, MOCs, canvas, bases, formatting) and obsidian@obsidian-skills (file editing) — this plugin complements them at the vault-structure level
- Vault must be plain markdown (Obsidian-compatible) with no cloud dependencies
- Project folders use category subfolders: architecture/, requirements/, decisions/, notes/ — to support multiple ERDs, PRDs, and ADRs per project

## Constraints

- **Plugin format**: Must be a Claude Code plugin (plugin.json, commands, skills, agents, hooks)
- **Local-only**: All data stays on the user's machine as plain .md files
- **Cross-agent**: Context files must work for Claude Code, Cursor, Gemini CLI, and any markdown-aware agent
- **Non-destructive**: Brownfield vault setup must never move or rename existing files without explicit user approval
- **Fast context loading**: Agents shouldn't need to scan hundreds of files — use pre-generated index and CLAUDE.md

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Category subfolders per project (architecture/, requirements/, decisions/, notes/) | Single files don't scale for multiple ERDs/PRDs/ADRs | -- Pending |
| On-demand inbox organization for v1 | Simpler to implement and debug; hooks/auto can come later | -- Pending |
| Manual capture for external data (Jira, etc.) | MCP integrations add complexity; manual + smart structuring is sufficient for v1 | -- Pending |
| Complement existing obsidian plugins, not duplicate | User already has note creation/formatting plugins installed | -- Pending |
| Capture command suggests destination instead of always dumping to inbox | Reduces organize-inbox workload; faster user workflow | -- Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-05 after Phase 1 completion*
