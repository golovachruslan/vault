# Roadmap: vault

## Overview

Build a Claude Code plugin that gives any AI agent instant, accurate context about active projects in an Obsidian vault. The journey starts by scaffolding the plugin and vault structure (Phase 1), adds the daily-use commands engineers reach for every day — capture, inbox triage, and project dashboards (Phase 2) — and finishes by delivering the core value proposition: deterministic CLAUDE.md generation, a SessionStart hook, and proactive vault health analysis (Phase 3).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation + Setup** - Plugin scaffold, vault init wizard, note templates, and vault config
- [ ] **Phase 2: Daily Workflows** - Capture with smart routing, inbox organization, and project dashboard creation
- [ ] **Phase 3: Context + Analysis** - CLAUDE.md generation, cross-agent context files, SessionStart hook, and vault health analysis

## Phase Details

### Phase 1: Foundation + Setup
**Goal**: Engineers can install the plugin, initialize a vault (new or existing), and have a correctly structured PARA vault with templates and a machine-readable config
**Depends on**: Nothing (first phase)
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04
**Success Criteria** (what must be TRUE):
  1. User can run `/vault:init` on an empty directory and get a complete PARA folder hierarchy
  2. User can run `/vault:init` on an existing vault and the wizard proposes additions without moving or renaming any file without explicit approval
  3. Note templates (project dashboard, task list, inbox note) exist in the vault's templates/ folder after init
  4. vault:config.md exists at vault root and is referenced from both CLAUDE.md and AGENTS.md so any agent can read vault conventions
**Plans:** 2 plans
Plans:
- [x] 01-01-PLAN.md — Plugin scaffold (plugin.json, skills, hooks, scripts, package.json)
- [x] 01-02-PLAN.md — Bundled note templates and end-to-end verification

### Phase 2: Daily Workflows
**Goal**: Engineers can capture a note with a smart destination suggestion, triage their inbox with per-item confirmation, and create or refresh project dashboards — all without leaving their terminal
**Depends on**: Phase 1
**Requirements**: CAPT-01, CAPT-02, CAPT-03, CAPT-04, ORG-01, ORG-02, ORG-03, ORG-04, PROJ-01, PROJ-02, PROJ-03
**Success Criteria** (what must be TRUE):
  1. User can run `/vault:capture` with freeform text and receive a structured note with frontmatter, timestamp, and the correct template applied
  2. Capture command displays a destination suggestion with a confidence indicator; user can accept or override to any location including inbox
  3. User can run `/vault:organize-inbox` and for each item see a proposed destination with rationale before confirming or overriding
  4. No inbox file is moved until the user explicitly confirms that specific item
  5. User can run `/vault:project-dashboard` to create a project folder with category subfolders and a linked Dashboard.md + Tasks.md, or to refresh an existing dashboard's task counts and status
**Plans**: TBD
**UI hint**: yes

### Phase 3: Context + Analysis
**Goal**: Any AI agent starting a session in the vault gets full, accurate project context instantly, and the engineer can run a single command to see proactive improvement suggestions for their vault
**Depends on**: Phase 2
**Requirements**: CTX-01, CTX-02, CTX-03, CTX-04, CTX-05, CTX-06, ANLZ-01, ANLZ-02, ANLZ-03, ANLZ-04, ANLZ-05, ANLZ-06
**Success Criteria** (what must be TRUE):
  1. User can run `/vault:sync-context` and CLAUDE.md is regenerated deterministically from vault state with a visible `generated:` timestamp
  2. .vault-index.md exists with YAML listing all projects, statuses, file paths, and metrics so agents can read project state without scanning hundreds of files
  3. SessionStart hook fires automatically, detects the vault, and injects condensed project context (under 6K chars) into the session — no manual action needed
  4. Cross-agent context files (AGENTS.md, .cursorrules) exist at vault root so Cursor, Gemini CLI, and other markdown-aware agents can read vault conventions
  5. User can run `/vault:suggest` and receive actionable improvement suggestions (orphaned notes, stale dashboards, MOC candidates, tag inconsistencies) approved one by one
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation + Setup | 0/2 | Planning complete | - |
| 2. Daily Workflows | 0/? | Not started | - |
| 3. Context + Analysis | 0/? | Not started | - |
