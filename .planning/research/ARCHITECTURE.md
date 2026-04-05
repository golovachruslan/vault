# Architecture Research

**Domain:** Claude Code plugin — AI-powered Obsidian vault management
**Researched:** 2026-03-28
**Confidence:** HIGH (verified against official Claude Code plugin documentation and local installed plugin inspection)

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                         User Interface Layer                          │
│                                                                       │
│  /vault:setup   /vault:capture   /vault:organize   /vault:dashboard  │
│  /vault:analyze  /vault:generate-context  /vault:new-template        │
│  (skills/commands — slash commands user invokes directly)            │
└─────────────────────────┬────────────────────────────────────────────┘
                          │ invokes
┌─────────────────────────▼────────────────────────────────────────────┐
│                       Orchestration Layer                             │
│                                                                       │
│   skills/               agents/               hooks/                 │
│   ┌────────────┐         ┌────────────────┐    ┌─────────────────┐   │
│   │ vault-     │         │ inbox-          │    │ SessionStart    │   │
│   │ structure  │         │ organizer       │    │ (context inject)│   │
│   │ (knowledge)│         │                 │    └─────────────────┘   │
│   └────────────┘         │ vault-analyzer  │    ┌─────────────────┐   │
│   ┌────────────┐         │                 │    │ PostToolUse     │   │
│   │ para-      │         │ context-        │    │ (future: lint   │   │
│   │ routing    │         │ generator       │    │  vault rules)   │   │
│   │ (knowledge)│         └────────────────┘    └─────────────────┘   │
│   └────────────┘                                                      │
└─────────────────────────┬────────────────────────────────────────────┘
                          │ reads/writes
┌─────────────────────────▼────────────────────────────────────────────┐
│                         Data Layer                                    │
│                                                                       │
│   Vault (plain .md files)       Plugin state / generated indexes     │
│   ┌──────────────────────┐      ┌──────────────────────────────────┐  │
│   │ 00 Inbox/            │      │ CLAUDE.md  (agent context index) │  │
│   │ 01 Projects/         │      │ .cursorrules  (Cursor context)   │  │
│   │   └── project-name/  │      │ organization.md (vault rules)    │  │
│   │       architecture/  │      └──────────────────────────────────┘  │
│   │       requirements/  │                                             │
│   │       decisions/     │      scripts/  (setup + utility helpers)   │
│   │       notes/         │      ┌──────────────────────────────────┐  │
│   │ 02 Areas/            │      │ create-vault-structure.sh        │  │
│   │ 03 Resources/        │      │ validate-vault.sh                │  │
│   │ 04 Archive/          │      └──────────────────────────────────┘  │
│   │ 10 MOCs/             │                                             │
│   │ 20 Templates/        │                                             │
│   └──────────────────────┘                                             │
└──────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **Skills (user-invoked)** | Slash commands users run directly. Drive conversation and gather input, then delegate heavy work to agents. | `skills/<name>/SKILL.md` with `description`, `argument-hint`, `allowed-tools` frontmatter |
| **Skills (auto-invoked)** | Domain knowledge Claude loads automatically when context matches — PARA rules, routing logic, template specs. | `skills/<name>/SKILL.md` with third-person description triggering on relevant phrases |
| **Agents** | Autonomous multi-step tasks: scanning vault, proposing destinations, generating CLAUDE.md. Run in isolation with own toolset. | `agents/<name>.md` with frontmatter (`model`, `maxTurns`, `tools`) and system prompt |
| **Hooks** | Automatic triggers tied to Claude Code lifecycle events. SessionStart injects vault context; PostToolUse can enforce rules. | `hooks/hooks.json` referencing scripts in `scripts/` via `${CLAUDE_PLUGIN_ROOT}` |
| **Scripts** | Shell/Python utilities invoked by hooks or commands. Vault structure creation, CLAUDE.md generation, validation. | `scripts/*.sh` or `scripts/*.py`, chmod+x |
| **Templates** | Markdown note templates written to vault's `20 Templates/`. Not plugin components — output artifacts. | Inline in skill instructions or bundled as `templates/*.md` |
| **plugin.json** | Plugin identity, namespace (`vault:`), and component wiring. | `.claude-plugin/plugin.json` |

---

## Recommended Project Structure

```
vault-manager/
├── .claude-plugin/
│   └── plugin.json                    # name: "vault", version, description
│
├── skills/
│   │
│   │   # --- User-invoked skills (slash commands) ---
│   ├── setup/
│   │   ├── SKILL.md                   # /vault:setup — wizard: new vault or adapt existing
│   │   └── scripts/
│   │       └── create-structure.sh   # Creates PARA folder scaffold
│   │
│   ├── capture/
│   │   ├── SKILL.md                   # /vault:capture — smart content routing
│   │   └── templates/
│   │       └── inbox-note.md         # Fallback template when destination unclear
│   │
│   ├── organize/
│   │   ├── SKILL.md                   # /vault:organize — on-demand inbox triage
│   │   └── references/
│   │       └── routing-rules.md      # PARA destination decision tree
│   │
│   ├── dashboard/
│   │   ├── SKILL.md                   # /vault:dashboard — create/refresh project dashboard
│   │   └── templates/
│   │       ├── project-dashboard.md
│   │       ├── architecture-doc.md
│   │       ├── requirements-prd.md
│   │       ├── adr.md
│   │       └── task-list.md
│   │
│   ├── analyze/
│   │   └── SKILL.md                   # /vault:analyze — proactive improvement suggestions
│   │
│   ├── generate-context/
│   │   └── SKILL.md                   # /vault:generate-context — rebuild CLAUDE.md + .cursorrules
│   │
│   ├── new-template/
│   │   └── SKILL.md                   # /vault:new-template — install template into vault
│   │
│   │   # --- Auto-invoked skills (domain knowledge) ---
│   ├── vault-structure/
│   │   ├── SKILL.md                   # Loaded when discussing vault layout, folders, PARA
│   │   └── reference.md              # Canonical folder spec and numbering rationale
│   │
│   └── para-routing/
│       ├── SKILL.md                   # Loaded when routing notes, categorizing content
│       └── decision-tree.md          # Projects vs Areas vs Resources vs Archive rules
│
├── agents/
│   ├── inbox-organizer.md             # Scans inbox, proposes destinations per item
│   ├── vault-analyzer.md              # Full vault scan: orphans, stale links, tag gaps
│   └── context-generator.md          # Reads all active projects, writes CLAUDE.md
│
├── hooks/
│   └── hooks.json                     # SessionStart: detect vault, inject context
│
├── scripts/
│   ├── detect-vault.sh               # Find vault root from cwd (reads organization.md)
│   ├── inject-context.sh             # Read CLAUDE.md, echo to stdout for hook injection
│   └── validate-vault.sh             # Checks folder structure integrity
│
├── templates/                         # Bundled note templates (copied to vault on install)
│   ├── daily-note.md
│   ├── project-dashboard.md
│   ├── architecture-doc.md
│   ├── requirements-prd.md
│   ├── adr.md
│   ├── task-list.md
│   └── inbox-note.md
│
└── README.md
```

### Structure Rationale

- **`skills/` preferred over `commands/`:** Official docs mark `commands/` as legacy. All slash commands should be skills with `SKILL.md`. Both user-invoked (slash commands with `argument-hint` and `allowed-tools`) and auto-invoked (knowledge-only, no frontmatter tools) live in `skills/`.
- **Agents separate from skills:** Agents are for autonomous multi-step work (inbox scan, full vault analysis). Skills handle conversation-driven tasks where the user is in the loop. Mixing the two creates unpredictable behavior.
- **scripts/ at plugin root:** Hook commands reference `${CLAUDE_PLUGIN_ROOT}/scripts/`. Scripts must be chmod+x. Keep them thin — complex logic belongs in agent system prompts, not shell scripts.
- **templates/ bundled in plugin:** Templates get installed into vault's `20 Templates/` by the setup skill. Keeping them in the plugin lets the plugin version them independently of the vault.
- **Namespace `vault:`:** Plugin name `vault` gives short, memorable slash commands: `/vault:setup`, `/vault:capture`, etc. Short enough to type, clear enough to understand.

---

## Architectural Patterns

### Pattern 1: Skill-Delegates-to-Agent

**What:** User-invoked skill gathers minimal input interactively, then spawns an agent to do the autonomous work. Skill stays thin; agent is self-contained.

**When to use:** Any task that requires reading multiple files, making multiple decisions, or producing multiple file writes. Specifically: organize, analyze, generate-context.

**Trade-offs:** Agent adds a turn of latency and uses more tokens. But agents can be granted restricted toolsets (`disallowedTools`) and have isolated context, which is correct for vault-wide scans.

**Example (organize skill → inbox-organizer agent):**
```markdown
# skills/organize/SKILL.md frontmatter
---
description: Organize inbox notes...
allowed-tools: ["Task"]
---
# Body: confirm vault path with user, then:
Use the Task tool to invoke the inbox-organizer agent.
Pass the vault inbox path as context.
Present the agent's proposed destinations to the user for confirmation.
Only proceed with file moves after explicit user approval.
```

```markdown
# agents/inbox-organizer.md
---
name: inbox-organizer
description: Scans vault inbox, proposes PARA destinations for each note...
model: sonnet
maxTurns: 30
tools: ["Read", "Glob", "Grep"]
disallowedTools: ["Write", "Edit", "Bash"]
---
System prompt: scan 00 Inbox/, read each note, propose destination...
```

The agent reads only — it never writes. The skill confirms with the user, then performs the writes. This satisfies the non-destructive constraint.

### Pattern 2: SessionStart Hook for Context Injection

**What:** A `SessionStart` hook detects whether the current working directory is inside a vault and, if so, reads the pre-generated `CLAUDE.md` and injects its contents into the session context.

**When to use:** Always. This is the core value proposition — any agent session starts with full project context.

**Trade-offs:** The hook runs on every session start, including non-vault sessions. The detect-vault script must exit cleanly (exit 0, no output) when no vault is present, so non-vault sessions are unaffected.

**Example (hooks/hooks.json):**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/inject-context.sh"
          }
        ]
      }
    ]
  }
}
```

```bash
# scripts/inject-context.sh
#!/usr/bin/env bash
# Find organization.md upward from cwd — marks vault root
VAULT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
CONTEXT_FILE="${VAULT_ROOT}/CLAUDE.md"
if [ -f "$CONTEXT_FILE" ]; then
  cat "$CONTEXT_FILE"
fi
# Exit 0 silently if no vault found — hook output only emitted when non-empty
```

### Pattern 3: Non-Destructive Brownfield Adaptation

**What:** The setup skill reads existing vault structure before proposing changes. It presents a diff-style plan ("I will create these folders; I will not touch these existing files") and requires explicit confirmation before any file system mutation.

**When to use:** Vault setup on an existing vault. Never assume a clean slate.

**Trade-offs:** More complex setup flow. But the alternative — silently reorganizing someone's vault — is catastrophic and irreversible. This is a hard constraint, not an option.

**Implementation notes:**
- Setup skill uses `Glob` and `Read` to map existing structure first.
- Presents summary: existing folders found, new folders to create, nothing to move/rename.
- Only after user types "confirm" or similar does it proceed with `Bash` or `Write`.
- The skill's `allowed-tools` should include `Read`, `Glob`, `Bash`, `Write`, `AskUserQuestion` but NOT include agents that auto-write.

### Pattern 4: Pre-Generated Context Index

**What:** `CLAUDE.md` is a generated artifact, not a manually maintained file. The `generate-context` skill (and `context-generator` agent) rebuild it on demand by scanning active projects. It is a snapshot, not a live view.

**When to use:** User runs `/vault:generate-context` after significant vault changes. SessionStart hook reads it — the hook should never regenerate it on every session (too slow).

**Trade-offs:** Context can go stale between generations. This is acceptable for v1. Stale context is better than no context. A reminder in `CLAUDE.md` itself ("Last generated: {{date}}") signals staleness to agents reading it.

**CLAUDE.md structure (generated output):**
```markdown
# Vault Context — Generated {{date}}

## Active Projects
- [[Project A]] — status: active, phase: 2, last updated: {{date}}
- [[Project B]] — status: in-progress

## Recent Inbox (last 7 days)
- {{note title}} — captured {{date}}

## Vault Map
- 01 Projects/: N notes
- 00 Inbox/: N unprocessed

## Conventions
- PARA structure (see organization.md for rules)
- Project subfolders: architecture/, requirements/, decisions/, notes/
- Templates in 20 Templates/

## Agent Instructions
When creating notes, always read organization.md first.
Never move files without user confirmation.
```

---

## Data Flow

### Capture Command Flow

```
User runs /vault:capture "Meeting notes about auth design"
    │
    ▼
capture/SKILL.md loads
    │
    ├─ Loads para-routing skill (auto: routing knowledge)
    ├─ Reads vault organization.md for conventions
    ├─ Analyzes content → determines destination
    │     (01 Projects/auth-service/architecture/ vs 00 Inbox/)
    │
    ├─ Presents proposed destination to user
    │     "Route to: 01 Projects/auth-service/architecture/meeting-2026-03-28.md
    │      Confirm? (yes / inbox instead)"
    │
    └─ On confirm: Write note to proposed path
         └─ Note includes frontmatter: type, date, project link, tags
```

### Organize Inbox Flow

```
User runs /vault:organize
    │
    ▼
organize/SKILL.md loads
    │
    ├─ Loads vault-structure skill
    ├─ Confirms vault path with user
    │
    └─ Spawns inbox-organizer agent (Task tool)
         │
         ▼
         inbox-organizer agent
         ├─ Glob: list all files in 00 Inbox/
         ├─ Read: each inbox note (title, content, tags)
         ├─ For each note: propose PARA destination + rationale
         └─ Returns structured proposal list
              │
              ▼
         organize/SKILL.md resumes
         ├─ Presents proposals as numbered list to user
         ├─ User approves/modifies each destination
         └─ Executes confirmed moves (Write + delete original or Bash mv)
```

### SessionStart Context Injection Flow

```
Claude Code session starts (any cwd)
    │
    ▼
SessionStart hook fires
    │
    └─ inject-context.sh
         ├─ Search upward for organization.md (vault marker)
         ├─ If not found: exit 0 (no output, no injection)
         └─ If found: cat CLAUDE.md to stdout
              │
              ▼
              Hook output injected into session context
              Claude begins session with full project map
```

### Generate Context Flow

```
User runs /vault:generate-context
    │
    ▼
generate-context/SKILL.md loads
    │
    └─ Spawns context-generator agent (Task tool)
         │
         ▼
         context-generator agent
         ├─ Glob: all .md files in 01 Projects/
         ├─ Read: each project dashboard (status, phase, last updated)
         ├─ Glob: recent files in 00 Inbox/ (last 7 days by mtime)
         ├─ Compile: vault statistics, conventions from organization.md
         └─ Write: CLAUDE.md at vault root
              │
         Also writes: .cursorrules at vault root (same content, Cursor format)
              │
              ▼
         generate-context/SKILL.md resumes
         └─ Reports: "CLAUDE.md updated. N projects indexed."
```

---

## Component Boundaries

| Boundary | Communication | Direction | Notes |
|----------|---------------|-----------|-------|
| User ↔ Skill | Slash command invocation, conversational turns | Bidirectional | User provides arguments and confirmations |
| Skill → Agent | `Task` tool call with context payload | Skill→Agent | Skill owns the conversation; agent owns the analysis |
| Agent → Vault (read) | `Read`, `Glob`, `Grep` tools | Agent→Vault | Agents read freely; never write without skill orchestration |
| Skill → Vault (write) | `Write`, `Bash` (after user confirmation) | Skill→Vault | All destructive operations go through user-facing skill, not agent |
| Hook → Script | Shell exec via `command` type | Hook→Script | Scripts output context to stdout; hook injects it |
| Script → Vault | File read only in v1 (inject-context.sh) | Script→Vault | Scripts should be read-only unless user explicitly approved setup |
| Auto-invoked Skill → Conversation | Claude loads skill when context matches description | Runtime→Skill | No explicit call; description triggers automatic loading |

---

## Build Order (Phase Dependencies)

The components have hard dependencies that dictate build order:

### Phase 1 — Foundation (no dependencies)
**What:** Plugin scaffold, plugin.json, vault-structure skill, para-routing skill, organization.md conventions encoded.

**Why first:** Every other component depends on knowing the vault structure and PARA routing rules. Auto-invoked skills are pure knowledge — no vault interaction, so they can be built and tested in isolation.

**Deliverables:**
- `.claude-plugin/plugin.json` with name `vault`
- `skills/vault-structure/SKILL.md` + reference.md
- `skills/para-routing/SKILL.md` + decision-tree.md
- `organization.md` conventions document
- Plugin loads, `/vault:` namespace registered

### Phase 2 — Setup Wizard (depends on Phase 1)
**What:** `/vault:setup` skill + folder creation scripts. Greenfield and brownfield paths.

**Why second:** Setup creates the vault structure that all subsequent commands operate on. Without a correctly structured vault, capture and organize have nowhere to route notes.

**Deliverables:**
- `skills/setup/SKILL.md`
- `scripts/create-structure.sh`
- `scripts/detect-vault.sh`
- `scripts/validate-vault.sh`
- Template installation into `20 Templates/`
- All note templates in `templates/`

### Phase 3 — Quick Capture (depends on Phase 1 + Phase 2)
**What:** `/vault:capture` skill. Smart routing to suggest destination.

**Why third:** Requires vault to exist (Phase 2) and routing knowledge (Phase 1). This is the highest-frequency daily workflow — must be solid before building organize on top of it.

**Deliverables:**
- `skills/capture/SKILL.md`
- `skills/capture/templates/inbox-note.md`

### Phase 4 — Inbox Organization (depends on Phase 3)
**What:** `/vault:organize` skill + `inbox-organizer` agent.

**Why fourth:** Requires inbox to have notes (Phase 3 creates them) and routing knowledge (Phase 1). Agent pattern established here becomes the template for vault-analyzer.

**Deliverables:**
- `skills/organize/SKILL.md`
- `agents/inbox-organizer.md`
- `skills/organize/references/routing-rules.md`

### Phase 5 — Project Dashboard (depends on Phase 2)
**What:** `/vault:dashboard` skill. Create/refresh project dashboards with category subfolders.

**Why fifth:** Requires vault structure (Phase 2). Independent of capture/organize. Needed before context generation can index project state.

**Deliverables:**
- `skills/dashboard/SKILL.md`
- `skills/dashboard/templates/` (all doc templates)

### Phase 6 — Context Generation + SessionStart Hook (depends on Phase 5)
**What:** `/vault:generate-context` skill + `context-generator` agent + `SessionStart` hook.

**Why sixth:** Context generation reads project dashboards (Phase 5). The SessionStart hook reads the generated CLAUDE.md — it cannot be built before CLAUDE.md exists. This is the phase that delivers the core value proposition.

**Deliverables:**
- `skills/generate-context/SKILL.md`
- `agents/context-generator.md`
- `hooks/hooks.json` (SessionStart)
- `scripts/inject-context.sh`
- `.cursorrules` generation

### Phase 7 — Vault Analysis (depends on Phase 6)
**What:** `/vault:analyze` skill + `vault-analyzer` agent. Proactive suggestions.

**Why last:** Requires a populated vault with dashboards and context (Phases 2-6). Vault analyzer is the "nice to have" — vault is already functional without it. Also the most complex agent (scans everything).

**Deliverables:**
- `skills/analyze/SKILL.md`
- `agents/vault-analyzer.md`

---

## Anti-Patterns

### Anti-Pattern 1: Agent Writes Without User Confirmation

**What people do:** Give agents `Write` and `Edit` tools and let them move/create notes autonomously.

**Why it's wrong:** Irreversible. An inbox-organizer that misroutes 50 notes is a catastrophe. The user constraint is explicit: "Non-destructive — never move or rename existing files without explicit user approval."

**Do this instead:** Agents read only (`tools: ["Read", "Glob", "Grep"]`, `disallowedTools: ["Write", "Edit", "Bash"]`). Agents return proposals. The calling skill presents proposals to the user and performs writes only after confirmation.

### Anti-Pattern 2: Hooks That Regenerate CLAUDE.md on Every Session

**What people do:** Put the full context-generation logic in the SessionStart hook so context is always fresh.

**Why it's wrong:** Context generation scans every project file — on a large vault this takes 10-30 seconds. Running this on every session start is unacceptable latency. It also burns tokens on sessions where vault hasn't changed.

**Do this instead:** SessionStart hook reads the pre-generated CLAUDE.md (fast file read). User runs `/vault:generate-context` manually after significant vault changes. CLAUDE.md includes a "Last generated" timestamp so agents know if context is stale.

### Anti-Pattern 3: User-Invoked Skill That Does Everything

**What people do:** Put all logic directly in the skill SKILL.md — file scanning, routing logic, write operations — rather than delegating to agents.

**Why it's wrong:** Skills are not designed for multi-step autonomous work. They lack agent isolation, tool restriction, and turn limits. Complex logic in skills becomes unmaintainable and risks runaway file operations.

**Do this instead:** Skills handle user interaction and confirmation. Agents handle multi-file scanning and complex analysis. Use the Task tool in skills to delegate to agents.

### Anti-Pattern 4: Single Monolithic CLAUDE.md Section Per Project

**What people do:** Dump all project information in one flat section in CLAUDE.md with no structure.

**Why it's wrong:** Agents reading CLAUDE.md get flooded with unstructured detail. Context window fills quickly. No clear signal of what is active vs archived.

**Do this instead:** CLAUDE.md has strict sections (Active Projects, Recent Inbox, Vault Map, Conventions, Agent Instructions). Each project entry is a one-liner with a wiki link to the dashboard. Agents can follow the link if they need detail.

---

## Integration Points

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `vault:capture` skill ↔ `para-routing` skill | Auto-load: capture skill triggers para-routing by mentioning routing topics | No explicit call needed |
| `vault:organize` skill ↔ `inbox-organizer` agent | `Task` tool with vault path argument | Agent returns structured proposal; skill presents to user |
| `vault:generate-context` skill ↔ `context-generator` agent | `Task` tool with vault root path | Agent writes CLAUDE.md and .cursorrules directly (only agent that writes) |
| `SessionStart` hook ↔ `inject-context.sh` | Shell exec, stdout injected as context | Script must be chmod+x and handle missing vault gracefully |
| `vault:setup` skill ↔ `create-structure.sh` | Bash tool call within skill | Skill confirms plan with user first |

### Complementary Plugin Boundaries

| Plugin | What It Owns | What vault-manager Owns |
|--------|-------------|------------------------|
| `obsidian@claude-pro-skills` | Note creation, MOCs, canvas, Bases views, formatting | Vault folder structure, project dashboards, context indexing, routing |
| `obsidian@obsidian-skills` | File-level editing operations | Vault-level organization strategy |
| **vault-manager (this plugin)** | Structure, routing, project dashboards, CLAUDE.md, cross-agent context | Does not create individual notes — uses obsidian@claude-pro-skills for that |

---

## Scaling Considerations

This is a local, single-user Claude Code plugin. Traditional scaling (users, servers) does not apply. Relevant scale is vault size.

| Vault Size | Architecture Adjustment |
|------------|------------------------|
| < 200 notes | No adjustment needed. Agents can scan all notes per session. |
| 200-1000 notes | CLAUDE.md becomes essential. Agents should filter by frontmatter status before full reads. Vault-analyzer should use Grep before Read. |
| 1000+ notes | Consider an index file per project folder listing note titles. context-generator should read index files, not all notes. Vault-analyzer needs incremental scan (modified since last run). |

**First bottleneck:** SessionStart hook latency if CLAUDE.md grows large. Mitigation: cap CLAUDE.md at ~100 lines; each project is a one-liner with a link, never full content.

**Second bottleneck:** inbox-organizer agent reading every inbox note. Mitigation: Glob with date filter (only notes newer than last organize run), stored in a `.vault-state` marker file.

---

## Sources

- Claude Code Plugin documentation: https://code.claude.com/docs/en/plugins (HIGH confidence — official docs, accessed 2026-03-28)
- Claude Code Plugin Reference: https://code.claude.com/docs/en/plugins-reference (HIGH confidence — official docs, accessed 2026-03-28)
- Inspected installed plugin: `obsidian@claude-pro-skills` v2.3.0 at `~/.claude/plugins/cache/claude-pro-skills/obsidian/2.3.0/` (HIGH confidence — local file system)
- Inspected installed plugin: `plugin-dev@claude-plugins-official` at `~/.claude/plugins/cache/claude-plugins-official/plugin-dev/` (HIGH confidence — local file system)
- Reference project: github.com/earlyaidopters/second-brain (MEDIUM confidence — simpler shell-based system, not plugin format)
- Existing vault structure at `/Users/ruslanhalavach/Documents/Projects/vault/` (HIGH confidence — local file system)

---
*Architecture research for: Claude Code plugin — AI-powered Obsidian vault management*
*Researched: 2026-03-28*
