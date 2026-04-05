# Requirements: vault

**Defined:** 2026-04-04
**Core Value:** Any AI agent session starts with full, accurate context about all active projects -- no re-explaining needed.

## v1 Requirements

### Setup

- [ ] **SETUP-01**: User can run `/vault:init` to scaffold a new vault with PARA folder structure (inbox/, daily/, projects/, areas/, resources/, archive/, templates/)
- [ ] **SETUP-02**: User can run `/vault:init` on an existing vault and the wizard detects existing structure, proposes additions non-destructively (never moves/renames without explicit approval)
- [ ] **SETUP-03**: Setup wizard creates core note templates in the vault's templates/ folder (project dashboard, task list, inbox note)
- [ ] **SETUP-04**: Plugin generates a `vault:config.md` referenced from CLAUDE.md and AGENTS.md so any agent knows the vault conventions

### Capture

- [ ] **CAPT-01**: User can run `/vault:capture` with freeform text and the agent creates a structured note with frontmatter and timestamp
- [ ] **CAPT-02**: Capture command analyzes content and suggests the most likely destination (specific project, area, or inbox) with a confidence indicator
- [ ] **CAPT-03**: User can accept the suggested destination or override to a different location (including inbox as zero-friction fallback)
- [ ] **CAPT-04**: Captured note uses the appropriate template based on content type and destination

### Organization

- [ ] **ORG-01**: User can run `/vault:organize-inbox` to process all files in inbox/
- [ ] **ORG-02**: For each inbox item, agent proposes a destination (project/area/resource) with rationale
- [ ] **ORG-03**: User confirms or overrides each proposed move before execution
- [ ] **ORG-04**: After moves, agent updates relevant MOCs and wikilinks

### Projects

- [ ] **PROJ-01**: User can run `/vault:project-dashboard` to create a new project folder with category subfolders (architecture/, requirements/, decisions/, notes/) and a Dashboard.md + Tasks.md
- [ ] **PROJ-02**: User can run `/vault:project-dashboard` on an existing project to refresh the dashboard by re-deriving task counts, linked notes, and last-updated status from actual vault content
- [ ] **PROJ-03**: Project dashboard displays current phase, status, open task count, key links, and recent activity

### Context

- [ ] **CTX-01**: User can run `/vault:sync-context` to regenerate CLAUDE.md from current vault state (active projects, recent inbox, vault map, conventions)
- [ ] **CTX-02**: CLAUDE.md is deterministically generated (not AI prose) with a `generated:` timestamp so staleness is visible
- [ ] **CTX-03**: Plugin generates .vault-index.md with YAML frontmatter listing all projects, statuses, file paths, and metrics for fast machine reading
- [ ] **CTX-04**: SessionStart hook detects if cwd is inside a configured vault and injects condensed context (under 6K chars) as a system message
- [ ] **CTX-05**: SessionStart hook reads pre-generated .vault-index.md (not a full vault scan) to stay fast
- [ ] **CTX-06**: vault:config.md is referenced from CLAUDE.md and AGENTS.md so cross-agent tools (Cursor, Gemini CLI) can read vault conventions

### Analysis

- [ ] **ANLZ-01**: User can run `/vault:suggest` to get proactive improvement suggestions
- [ ] **ANLZ-02**: Analysis detects orphaned notes (no incoming or outgoing links)
- [ ] **ANLZ-03**: Analysis detects stale project dashboards (tasks older than 2 weeks with no status change)
- [ ] **ANLZ-04**: Analysis suggests new MOC candidates (clusters of 5+ notes on the same topic with no MOC)
- [ ] **ANLZ-05**: Analysis detects tag inconsistencies (variant spellings, suggest normalization)
- [ ] **ANLZ-06**: Suggestions are actionable -- user can approve them one by one for execution

## v2 Requirements

### Automation

- **AUTO-01**: SessionStart hook checks inbox count and prompts user to organize if items are waiting
- **AUTO-02**: Automatic hook-based inbox processing (file watcher triggers organize suggestions)
- **AUTO-03**: Session-end summary automatically saved to relevant project notes

### Integration

- **INTG-01**: MCP integration for Jira ticket import (pull tickets into project task lists)
- **INTG-02**: MCP integration for Linear issue sync
- **INTG-03**: GitHub Issues / PR linking via MCP

### Templates

- **TMPL-01**: Architecture doc template
- **TMPL-02**: ERD doc template
- **TMPL-03**: PRD/requirements doc template
- **TMPL-04**: ADR (Architecture Decision Record) doc template
- **TMPL-05**: Daily note template

### Advanced

- **ADV-01**: Multi-vault support (project-specific vaults with separate contexts)
- **ADV-02**: Vault migration tool (convert between organizational systems)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Obsidian community plugin (native app plugin) | Different tech stack (TypeScript Plugin API); this is a Claude Code plugin |
| Full-text semantic search | Covered by obsidian-copilot / Smart Connections; different problem |
| Note formatting and MOC creation | Handled by existing obsidian@claude-pro-skills plugin |
| Real-time sync with external tools | Sync state is hard; v1 is local-only manual capture |
| Auto-generated session summaries / TLDRs | Covered by second-brain plugin; different workflow |
| Watch-based auto-organization | File watchers unreliable; silent moves break trust |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SETUP-01 | Phase 1 — Foundation + Setup | Pending |
| SETUP-02 | Phase 1 — Foundation + Setup | Pending |
| SETUP-03 | Phase 1 — Foundation + Setup | Pending |
| SETUP-04 | Phase 1 — Foundation + Setup | Pending |
| CAPT-01 | Phase 2 — Daily Workflows | Pending |
| CAPT-02 | Phase 2 — Daily Workflows | Pending |
| CAPT-03 | Phase 2 — Daily Workflows | Pending |
| CAPT-04 | Phase 2 — Daily Workflows | Pending |
| ORG-01 | Phase 2 — Daily Workflows | Pending |
| ORG-02 | Phase 2 — Daily Workflows | Pending |
| ORG-03 | Phase 2 — Daily Workflows | Pending |
| ORG-04 | Phase 2 — Daily Workflows | Pending |
| PROJ-01 | Phase 2 — Daily Workflows | Pending |
| PROJ-02 | Phase 2 — Daily Workflows | Pending |
| PROJ-03 | Phase 2 — Daily Workflows | Pending |
| CTX-01 | Phase 3 — Context + Analysis | Pending |
| CTX-02 | Phase 3 — Context + Analysis | Pending |
| CTX-03 | Phase 3 — Context + Analysis | Pending |
| CTX-04 | Phase 3 — Context + Analysis | Pending |
| CTX-05 | Phase 3 — Context + Analysis | Pending |
| CTX-06 | Phase 3 — Context + Analysis | Pending |
| ANLZ-01 | Phase 3 — Context + Analysis | Pending |
| ANLZ-02 | Phase 3 — Context + Analysis | Pending |
| ANLZ-03 | Phase 3 — Context + Analysis | Pending |
| ANLZ-04 | Phase 3 — Context + Analysis | Pending |
| ANLZ-05 | Phase 3 — Context + Analysis | Pending |
| ANLZ-06 | Phase 3 — Context + Analysis | Pending |

**Coverage:**
- v1 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0

---
*Requirements defined: 2026-04-04*
*Last updated: 2026-03-28 after roadmap creation*
