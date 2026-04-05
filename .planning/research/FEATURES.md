# Feature Research

**Domain:** AI-powered Obsidian vault management (Claude Code plugin)
**Researched:** 2026-03-28
**Confidence:** HIGH for ecosystem patterns; MEDIUM for cross-agent context specifics

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that any AI-augmented vault management tool must have. Missing these makes the product feel broken relative to the reference ecosystem (second-brain, obsidian-copilot, COG, obsidian-claude-pkm).

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Vault setup wizard | Every tool in the ecosystem starts with an interactive setup. Users won't manually create folder hierarchies. | MEDIUM | second-brain `/vault-setup`, obsidian-claude-pkm `/onboard`, COG onboarding — all do this. Must generate CLAUDE.md + folder structure in one pass. |
| CLAUDE.md / agent context file generation | Anthropic's own best practices specify CLAUDE.md as the entry point for agent context. Users expect the tool to generate this automatically. | MEDIUM | Must be accurate, pruned, and not grow unboundedly. Stale CLAUDE.md is worse than none. |
| Quick note capture command | Every mature PKM tool has a capture shortcut. Engineers expect "I can type a thought and it goes somewhere useful" with zero friction. | MEDIUM | Routing suggestion (vs. always dumping to inbox) is the differentiation point. Capture itself is table stakes. |
| Inbox processing / triage | GTD-trained users and every comparable tool (obsidian-claude-pkm `/note-organizer`, second-brain `/file-intel`) include inbox triage. | MEDIUM | On-demand (not watch-based) is acceptable for v1. User confirms before moves. |
| Note templates for common document types | Templates for project dashboards, ADRs, PRDs, daily notes. Users treat these as non-negotiable plumbing — they just expect them to exist. | LOW | ADR and PRD templates have established formats (adr.github.io). Project dashboards vary by team. |
| Brownfield adoption (existing vault support) | Users almost always have an existing vault. Tools that require a fresh start get rejected immediately. | MEDIUM | Non-destructive requirement is critical — never move/delete without explicit approval. obsidian-claude-pkm `/adopt` is the reference pattern. |
| Project dashboard creation | Engineers managing multiple projects expect one place to track project status, tasks, and linked docs. All reference tools include this. | MEDIUM | Must create with category subfolders (architecture/, requirements/, decisions/, notes/) for multi-document support. |

### Differentiators (Competitive Advantage)

Features that go beyond what comparable tools offer. These are where this plugin competes on its stated core value: "Any AI agent session starts with full, accurate context about all active projects."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Smart capture routing (destination suggestion, not inbox dump) | Reduces organize-inbox workload. obsidian-claude-pkm always routes to inbox; second-brain always routes to inbox; this plugin analyzes content and suggests the right folder before accepting. Saves the triage step for content that clearly belongs somewhere. | HIGH | Requires reading vault structure, understanding project taxonomy, and making a confident suggestion. May need fallback to inbox when confidence is low. |
| Cross-agent context files (.cursorrules, Gemini CLI compatible markdown) | Other tools are Claude-only. COG comes closest with multi-agent support (Kiro, Gemini CLI, Codex), but most tools don't explicitly generate Cursor or Gemini-compatible context files. | MEDIUM | Plain markdown with no Claude-specific syntax is the key design constraint. Cross-agent portability is a real differentiator for engineers who switch tools. |
| SessionStart hook for automatic context injection | No reference tool auto-injects context at session start via a hook. Users currently either manually reference CLAUDE.md or rely on Claude Projects. A hook that detects vault and prepopulates context removes all friction. | HIGH | Claude Code hooks are the mechanism. Must be fast (condensed index, not full vault scan) to not slow session startup. |
| Proactive vault health analysis | Active AI-driven suggestions: orphaned notes, stale dashboards, missing links, tag inconsistencies, MOC candidates. obsidian-copilot does passive semantic search; Steward plugin does some automation. No Claude Code plugin does this proactively as a command. | HIGH | Requires vault traversal and heuristic rules. Must surface actionable suggestions, not just a wall of findings. |
| Auto-refresh project dashboards | Stale dashboards are a known failure mode in PKM. A refresh command that re-derives task counts, linked notes, and last-updated status from actual vault content keeps dashboards honest. | MEDIUM | Requires structured frontmatter conventions established at dashboard creation time. |
| Condensed vault index for fast agent context loading | CLAUDE.md best practices warn against bloat (>50KB gets ignored). A pre-generated condensed index (active projects, recent inbox, vault map) means agents never need to scan files at session start. | MEDIUM | Index must be regenerated on demand and ideally on vault change. v1 is on-demand only. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Automatic watch-based inbox processing | "I want my inbox to auto-sort as soon as I drop notes in" — feels like full automation | File watchers in Claude Code plugins are unreliable across OS/sleep states. Silent moves without user review create trust problems — users lose notes and don't know where they went. Debugging is hard when no human approved the action. | On-demand `/organize-inbox` command. User reviews proposed moves before execution. Explicit beats implicit for destructive operations. |
| Real-time vault sync with external tools (Jira, Linear, GitHub Issues) | Engineers want their Jira tickets auto-imported | Sync state is hard: deletions, renames, field changes all create edge cases. MCP integrations add external dependencies and auth complexity. v1 trust is built with local-only operation. | Manual capture with structured templates. User pastes Jira content; AI structures it. External sync is a v2 feature when trust is established. |
| Full-text semantic search within the plugin | "Ask questions about my vault" (obsidian-copilot's core feature) | Semantic search requires embeddings, vector storage, and either a local model or a cloud API call per search. This overlaps with obsidian-copilot, Smart Connections, and existing installed plugins. Duplicating it adds maintenance burden with no advantage. | This plugin operates at structure and context level. Semantic search is delegated to obsidian-copilot or Smart Connections, which the user likely already has. |
| Obsidian community plugin (native app plugin) | "Just build a plugin I can install in Obsidian settings" | Building a community plugin requires Obsidian Plugin API (TypeScript), separate release/review process, and no Claude Code integration. Completely different tech stack from the stated constraint. Out of scope by definition. | Claude Code plugin operates at CLI level, works on the vault as a filesystem. Complementary, not competing. |
| Auto-generated session summaries / TLDRs saved to vault | second-brain `/tldr` does this; COG has daily briefs | Useful but already covered by second-brain. Adding it here creates overlap with tools the user may already have. It's also a different workflow (session capture vs. vault management). | Delegate to second-brain or similar. This plugin focuses on structure and context, not session journaling. |
| Multi-vault support | Power users sometimes want project-specific vaults | Significant complexity increase: conventions, paths, and CLAUDE.md all need to be scoped per vault. Most engineers use one vault with good folder structure. | Single vault, well-structured. Multi-vault is a v2 consideration if demand is validated. |
| Note formatting and MOC creation | "AI should format my notes and build Maps of Content" | User already has obsidian@claude-pro-skills for this. Duplicating it creates conflicts and confusion about which plugin to use. | Explicitly delegate to obsidian@claude-pro-skills. Document this boundary in CLAUDE.md conventions. |

---

## Feature Dependencies

```
[Vault Setup Wizard]
    └──generates──> [CLAUDE.md / Agent Context File]
    └──creates──> [Note Templates]
    └──creates──> [Folder Structure]
                      └──required by──> [Quick Capture Routing]
                      └──required by──> [Inbox Processing]
                      └──required by──> [Project Dashboard Creation]

[Project Dashboard Creation]
    └──required by──> [Auto-Refresh Project Dashboards]

[CLAUDE.md / Agent Context File]
    └──required by──> [SessionStart Hook]
    └──required by──> [Condensed Vault Index]

[Condensed Vault Index]
    └──enhances──> [SessionStart Hook] (fast injection)
    └──enhances──> [Proactive Vault Health Analysis] (traversal input)

[Note Templates]
    └──required by──> [Quick Capture Routing] (structured output format)
    └──required by──> [Project Dashboard Creation] (dashboard template)

[Cross-Agent Context Files]
    └──depends on──> [CLAUDE.md / Agent Context File] (content source)

[Smart Capture Routing]
    └──enhances──> [Quick Capture] (makes capture smarter, not a prerequisite)

[Brownfield Adoption]
    └──conflicts with──> [Destructive Setup] (must never replace existing files without approval)
```

### Dependency Notes

- **Vault Setup Wizard must come first:** All other features depend on the folder structure and CLAUDE.md it creates. A brownfield setup that only adds missing structure is an acceptable variant.
- **Note Templates are required before capture works:** The capture command needs templates to structure the note it creates; generating unformatted notes defeats the purpose.
- **Condensed Vault Index enhances but does not block SessionStart Hook:** Hook can inject raw CLAUDE.md as fallback; index makes injection fast and token-efficient.
- **Smart routing requires knowing the folder structure:** It can only suggest a destination if it knows what destinations exist. Setup must run first.
- **Cross-agent files are a packaging concern:** They derive from CLAUDE.md content; generate them at the same time CLAUDE.md is refreshed.

---

## MVP Definition

### Launch With (v1)

Minimum viable product to validate the core thesis: "AI agent sessions start with full context about active projects."

- [ ] **Vault Setup Wizard** (`/vault-setup`) — Without this, nothing else works. Creates folder structure, CLAUDE.md, and installs note templates in one pass. Handles both greenfield and brownfield.
- [ ] **CLAUDE.md Generation + Condensed Vault Index** — The core value is delivered here. Must be regeneratable on demand. Keeps context current.
- [ ] **Note Templates** (project dashboard, ADR, PRD, architecture doc, task list, inbox note) — Required for capture and dashboard commands to produce useful output.
- [ ] **Quick Capture** (`/capture`) — The primary daily-use command. Takes content, suggests destination based on vault structure, creates structured note from template.
- [ ] **Inbox Organization** (`/organize-inbox`) — On-demand triage. Proposes moves, user confirms. MVP: text-based proposal listing; not required to auto-move without confirmation.
- [ ] **Project Dashboard Creation** (`/project-dashboard`) — Create a new project with subfolders and linked dashboard note. Engineers need this from day one.
- [ ] **Cross-Agent Context Files** — Generate .cursorrules and plain-markdown equivalent alongside CLAUDE.md. Low effort, high value for the cross-agent use case.

### Add After Validation (v1.x)

Features to add once the core workflow is in use and feedback is gathered.

- [ ] **SessionStart Hook** — Technically straightforward once CLAUDE.md exists, but requires testing across Claude Code versions. Add after v1 usage shows how large CLAUDE.md grows in practice.
- [ ] **Project Dashboard Refresh** (`/refresh-dashboard`) — Add once dashboards exist in production use and stale data is reported as a pain point.
- [ ] **Proactive Vault Health Analysis** (`/vault-health`) — Requires confidence in heuristics (orphan detection, stale detection). Premature suggestions annoy users. Add once vault conventions are proven stable.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Watch-based auto-organization** — Deferred (see anti-features). Re-evaluate if users consistently request it after experiencing on-demand flow.
- [ ] **External tool sync (Jira, Linear, GitHub)** — Deferred. Requires MCP integrations and external auth. Significant complexity increase.
- [ ] **Multi-vault support** — Deferred. Adds path complexity throughout. Most users won't need it v1.
- [ ] **Smart Capture routing with ML confidence scoring** — v1 routing is heuristic (folder name matching, keyword analysis). True ML routing requires embeddings. Defer until heuristic routing is validated as insufficient.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Vault Setup Wizard | HIGH | MEDIUM | P1 |
| CLAUDE.md Generation + Index | HIGH | MEDIUM | P1 |
| Note Templates | HIGH | LOW | P1 |
| Quick Capture (basic, inbox fallback) | HIGH | MEDIUM | P1 |
| Project Dashboard Creation | HIGH | MEDIUM | P1 |
| Inbox Organization (on-demand) | HIGH | MEDIUM | P1 |
| Cross-Agent Context Files | MEDIUM | LOW | P1 |
| Smart Capture Routing (destination suggestion) | HIGH | HIGH | P1 |
| SessionStart Hook | HIGH | MEDIUM | P2 |
| Project Dashboard Refresh | MEDIUM | MEDIUM | P2 |
| Proactive Vault Health Analysis | MEDIUM | HIGH | P2 |
| Watch-based auto-organization | LOW | HIGH | P3 |
| External sync (Jira, Linear) | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | second-brain (earlyaidopters) | obsidian-claude-pkm (ballred) | COG (huytieu) | This Plugin |
|---------|-------------------------------|-------------------------------|--------------|-------------|
| Setup wizard | `/vault-setup` — role-based interview | `/onboard` — personalized setup | Role packs + onboarding | `/vault-setup` — PARA + category subfolders |
| Capture | `/tldr` (session summaries), `/file-intel` (folder synthesis) | Braindump skill | Braindump + meeting transcripts | `/capture` — smart routing suggestion |
| Inbox triage | No explicit inbox command | `/note-organizer` agent | Inbox processor agent | `/organize-inbox` — on-demand, user confirms |
| CLAUDE.md / agent context | CLAUDE.md generated at setup | Not explicitly mentioned | Markdown files per-agent directory | CLAUDE.md + condensed index, regeneratable |
| Cross-agent support | Claude Code only | Claude Code only | Claude, Kiro, Gemini CLI, Codex | Claude, Cursor (.cursorrules), Gemini CLI, any markdown agent |
| Session start context | Memory.md updated each session | Not explicit | Via role packs | SessionStart hook + pre-generated index |
| Project dashboard | No | `/project` command | `04-projects/` folder | `/project-dashboard` with category subfolders |
| Vault health analysis | No | `note-organizer` agent (reactive) | No | `/vault-health` (proactive, P2) |
| Brownfield support | Partial ("supports existing vaults") | `/adopt` command | Framework files separated from user content | `/vault-setup` — non-destructive, approval-required |
| Note templates | No explicit templates | Not mentioned | No | Full template library (ADR, PRD, arch doc, task list) |
| External integrations | Gemini synthesis for PDFs/docs | None | GitHub, Linear, Slack, PostHog (v2 features) | None v1; MCP integrations deferred |

**Key gaps this plugin fills vs. the field:**
1. Smart capture routing (no reference tool suggests a destination — they all dump to inbox)
2. Cross-agent context file generation as a first-class feature (COG comes closest but is manual)
3. Note templates as a first-class library (no reference tool ships a template set)
4. Non-destructive brownfield with explicit approval gates (most tools assume greenfield)
5. Condensed index pattern for token-efficient context loading (not found in any reference tool)

---

## Sources

- [second-brain (earlyaidopters)](https://github.com/earlyaidopters/second-brain) — reference project, 4 slash commands, shell-based setup
- [obsidian-claude-pkm (ballred)](https://github.com/ballred/obsidian-claude-pkm) — 10 skills including `/adopt` for brownfield
- [COG second-brain (huytieu)](https://github.com/huytieu/COG-second-brain) — 17 skills, multi-agent (Claude, Kiro, Gemini CLI, Codex)
- [Obsidian Copilot (logancyang)](https://github.com/logancyang/obsidian-copilot) — semantic search, vault Q&A, agent mode (5,776 stars)
- [Steward plugin (Obsidian Forum)](https://forum.obsidian.md/t/new-plugin-steward-ai-powered-search-vault-management-and-automation-workflows/107537) — TF-IDF search, custom automation workflows, batch file ops
- [Awesome Obsidian AI Tools (danielrosehill)](https://github.com/danielrosehill/Awesome-Obsidian-AI-Tools) — 86 plugins across 17 categories, ecosystem map
- [Context Engineering for Claude Code (Anthropic)](https://code.claude.com/docs/en/best-practices) — CLAUDE.md size limits, pointer-not-copy pattern, 50KB threshold
- [Writing a good CLAUDE.md (HumanLayer)](https://www.humanlayer.dev/blog/writing-a-good-claude-md) — prune ruthlessly; hallucinations compound
- [Building a PKM with Obsidian and Claude (krucho.ski)](https://krucho.ski/building-a-pkm-with-obsidian-and-claude-a-practical-guide/) — atomic notes, Claude Refs folder pattern
- [Obsidian AI explained (eesel AI)](https://www.eesel.ai/blog/obsidian-ai) — ecosystem overview 2025

---

*Feature research for: AI-powered Obsidian vault management (Claude Code plugin)*
*Researched: 2026-03-28*
