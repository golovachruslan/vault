# Project Research Summary

**Project:** vault — AI-agent-friendly Obsidian vault management
**Domain:** Claude Code plugin for Obsidian PKM
**Researched:** 2026-03-28
**Confidence:** HIGH

## Executive Summary

This project is a Claude Code plugin that makes Obsidian vaults intelligible to any AI agent. The core thesis is that any agent session — Claude Code, Cursor, Gemini CLI, or future tools — should start with accurate, current context about the vault owner's active projects without requiring manual setup. Research confirms this is a real gap: no existing tool in the Claude Code plugin ecosystem (second-brain, obsidian-claude-pkm, COG) ships automatic session-start context injection, cross-agent context file generation, or a non-destructive brownfield setup path as first-class features. The product is best built as a Claude Code plugin using SKILL.md skills, agent markdown files, bash hook scripts, and plain markdown — all verified against official documentation with HIGH confidence.

The recommended approach follows a strict dependency order: scaffold the plugin and encode PARA knowledge first, add the setup wizard second (it creates the structure every other command depends on), then layer capture, inbox organization, project dashboards, context generation, and finally proactive vault analysis. The architecture separates user-facing skills (thin, conversational, confirmation-gated) from autonomous agents (read-only scanners that return proposals) — a pattern that satisfies the hard constraint that no file should ever be moved, renamed, or deleted without explicit per-item user approval.

The most critical risks are: (1) brownfield vault destruction if setup moves files without confirmation — this is catastrophic and irreversible; (2) CLAUDE.md context drift if generation is AI-prose-based rather than deterministic frontmatter extraction; and (3) SessionStart hook context overflow if the hook scans live vault content rather than a pre-generated index. All three risks are design decisions that must be locked in on the first day of implementation — they cannot be retrofitted cheaply.

---

## Key Findings

### Recommended Stack

The plugin lives entirely within the Claude Code plugin format: a `.claude-plugin/plugin.json` manifest at root, `skills/` for slash commands, `agents/` for autonomous multi-step tasks, `hooks/hooks.json` for lifecycle events, and `scripts/` for shell handlers. No npm dependencies are required at install time — the lazy-install pattern via a `SessionStart` hook copies `package.json` to `${CLAUDE_PLUGIN_DATA}` on first run, keeping the plugin installable with zero setup overhead.

The only optional dependencies are `gray-matter@4.0.3` (frontmatter parse/write), `fast-glob@3.x` (large vault traversal), and `js-yaml@4.x` (frontmatter serialization). All are needed only if scripts require structured frontmatter manipulation; basic capture and setup can use bash alone. The `SKILL.md` format strictly supersedes legacy `commands/` flat files and must be used for all new skills.

**Core technologies:**
- Claude Code plugin format (SKILL.md skills, agents, hooks): Distribution mechanism, slash commands, agent delegation, lifecycle hooks — this IS the container, not optional
- Bash scripts: Hook handlers, vault scanning, CLAUDE.md injection — zero install overhead, universal on macOS/Linux
- Plain markdown (.md): All vault content and cross-agent context files — required for portability across Claude, Cursor, Gemini CLI, and any markdown-aware agent
- gray-matter@4.0.3: Parse and write YAML frontmatter — needed for deterministic CLAUDE.md generation from project dashboard metadata
- fast-glob@3.x: Recursive vault scanning — needed for inbox organization and context generation on vaults with 200+ notes

### Expected Features

Research identified 7 table-stakes features (expected by users who have used any comparable tool), 6 differentiators, and a clear set of anti-features to avoid. The dependency graph is strict: vault setup must precede all other commands; templates must exist before capture works; project dashboards must exist before context generation can index project state.

**Must have (table stakes):**
- Vault setup wizard (`/vault:setup`) — all reference tools start here; must handle greenfield and brownfield non-destructively
- CLAUDE.md generation + condensed vault index — the core deliverable; must be deterministic, regeneratable, timestamped
- Note templates (project dashboard, ADR, PRD, architecture doc, task list, inbox note) — required before capture produces useful output
- Quick capture (`/vault:capture`) — primary daily-use command; must suggest routing destination, not just dump to inbox
- Inbox organization (`/vault:organize`) — on-demand triage with user confirmation before any file moves
- Project dashboard creation (`/vault:dashboard`) — creates project folder with category subfolders + linked dashboard note
- Cross-agent context files (AGENTS.md, .cursorrules, GEMINI.md) — low effort, high value for the core cross-agent proposition

**Should have (competitive):**
- Smart capture routing with confidence signal — no reference tool suggests a destination; showing top 2-3 candidates with confidence labels is the differentiator
- SessionStart hook for automatic context injection — no reference tool does this; removes all friction from the "start every session with context" thesis
- Project dashboard auto-refresh (`/vault:refresh-dashboard`) — stale dashboards are a known PKM failure mode; add after v1 usage confirms the pain
- Proactive vault health analysis (`/vault:analyze`) — orphan detection, stale link detection, tag inconsistencies; add after vault conventions are stable

**Defer (v2+):**
- Watch-based auto-organization — file watchers add complexity and trust problems; on-demand is acceptable
- External sync (Jira, Linear, GitHub Issues) — MCP integrations add auth complexity; local-only builds trust first
- Multi-vault support — path complexity throughout; most engineers use one vault
- Semantic search — already covered by obsidian-copilot; duplicating it adds maintenance burden

### Architecture Approach

The plugin uses a three-layer architecture: a user interface layer of slash commands (skills), an orchestration layer of skills + agents + hooks, and a data layer of plain markdown files on the local filesystem. The canonical pattern is Skill-Delegates-to-Agent: a user-invoked skill gathers input and confirmation interactively, then spawns a read-only agent to do autonomous multi-file analysis and return proposals. The skill owns all write operations — agents are never given `Write`, `Edit`, or `Bash` tools. This architecture satisfies the non-destructive constraint at the component boundary level, not just at the UI level.

**Major components:**
1. User-invoked skills (setup, capture, organize, dashboard, generate-context, analyze) — thin conversation drivers that confirm intent and gate writes
2. Auto-invoked skills (vault-structure, para-routing) — domain knowledge Claude loads automatically when context matches; no tool access
3. Agents (inbox-organizer, context-generator, vault-analyzer) — autonomous read-only scanners; return structured proposals to calling skill
4. Hooks (SessionStart) — inject pre-generated CLAUDE.md into session context; must stay under 6,000 characters injected
5. Shell scripts (detect-vault, inject-context, create-structure, validate-vault) — thin orchestration; complex logic belongs in agent system prompts
6. Generated context artifacts (CLAUDE.md, AGENTS.md, .cursorrules, GEMINI.md) — output of the plugin, not plugin components; live in vault root

### Critical Pitfalls

1. **Brownfield vault destruction** — The setup wizard must never move or rename files without per-item user confirmation. Test against a 100-note vault with existing folders before any release. Offer frontmatter-overlay PARA adaptation as an alternative to folder restructuring for users who cannot tolerate moves.

2. **CLAUDE.md context drift** — Never write CLAUDE.md as AI-generated prose. Generate it deterministically from project dashboard frontmatter (`project:`, `status:`, `last_active:` fields). Include a `generated:` timestamp. A stale timestamp is the only signal users get that context has drifted.

3. **SessionStart hook context overflow** — The hook injection cap is 10,000 characters; design for 6,000 to leave headroom. Never scan note bodies in the hook. Use a two-tier strategy: hook injects a condensed summary (project names, statuses, counts); CLAUDE.md carries the full payload as a file Claude can read on demand.

4. **Note routing overconfidence** — LLMs use confident language 34% more often when hallucinating. Always show confidence level alongside routing suggestions. When confidence is low, route to inbox with an explanation. Make inbox the zero-friction fallback, not a failure case.

5. **Plugin directory misplacement** — Only `plugin.json` belongs inside `.claude-plugin/`. Skills, agents, hooks, and scripts must be at the plugin root. This is non-obvious and silently breaks all commands. Validate with a smoke test after every install.

---

## Implications for Roadmap

Based on research, the architecture's build-order analysis and feature dependency graph suggest a 7-phase structure that maps directly to the component dependency graph. The ordering is not arbitrary — each phase creates the filesystem artifacts or knowledge structures that the next phase requires.

### Phase 1: Plugin Foundation and Vault Knowledge
**Rationale:** The plugin scaffold and PARA knowledge skills have no dependencies and unblock every subsequent phase. Plugin namespace, directory structure, and routing knowledge must exist before any user-facing command can work.
**Delivers:** Working plugin installation, `/vault:` namespace, auto-invoked vault-structure and para-routing knowledge skills, organization.md conventions document
**Addresses:** Table-stakes vault knowledge foundation; all user-invoked commands will reference these skills automatically
**Avoids:** Plugin directory misplacement pitfall — get the structure right from the first file; use smoke test after install

### Phase 2: Setup Wizard
**Rationale:** All other commands operate on vault structure that the setup wizard creates. Without a correctly structured vault, capture and organize have nowhere to route notes. Brownfield non-destructiveness must be built in from the start — retrofitting it later is the most dangerous shortcut in the pitfalls research.
**Delivers:** `/vault:setup` skill (greenfield and brownfield paths), folder creation scripts, template installation, all note templates bundled in plugin
**Addresses:** Vault setup wizard (table stakes), brownfield adoption (table stakes), note templates (table stakes)
**Avoids:** Brownfield vault destruction pitfall — non-destructive diff-style proposal, per-item confirmation gate, dry-run mode

### Phase 3: Quick Capture
**Rationale:** This is the highest-frequency daily workflow. Must be solid before building inbox organization on top of it (inbox organization assumes capture has been running). Smart routing destination suggestion is the core differentiator vs. reference tools — implement with confidence signal and inbox fallback from day one.
**Delivers:** `/vault:capture` skill with smart routing, confidence signal, top 2-3 candidate display, inbox fallback
**Addresses:** Quick capture (table stakes), smart capture routing (differentiator)
**Avoids:** Note routing overconfidence pitfall — confidence signal is a UX contract, not a nice-to-have

### Phase 4: Inbox Organization
**Rationale:** Requires populated inbox (Phase 3 creates notes) and routing knowledge (Phase 1). Establishes the Skill-Delegates-to-Agent pattern that the context generator and vault analyzer will replicate.
**Delivers:** `/vault:organize` skill, `inbox-organizer` agent (read-only), routing-rules reference document, per-item confirmation flow
**Addresses:** Inbox processing (table stakes)
**Avoids:** Agent-writes-without-confirmation anti-pattern — inbox-organizer agent has `disallowedTools: ["Write", "Edit", "Bash"]`; all moves go through the skill after user approval

### Phase 5: Project Dashboard Creation
**Rationale:** Requires vault structure (Phase 2). Independent of capture/organize. Project dashboards are the structured input that CLAUDE.md generation (Phase 6) reads — their frontmatter schema must be defined and validated before the context generator is built.
**Delivers:** `/vault:dashboard` skill, project dashboard template with category subfolders (architecture/, requirements/, decisions/, notes/), all document templates
**Addresses:** Project dashboard creation (table stakes)
**Avoids:** Monolithic CLAUDE.md anti-pattern — dashboard frontmatter schema established here becomes the deterministic source for context generation

### Phase 6: Context Generation and SessionStart Hook
**Rationale:** Context generation reads project dashboards (Phase 5). The SessionStart hook reads the generated CLAUDE.md — it cannot be built before CLAUDE.md generation exists. This phase delivers the core value proposition: any agent session starts with full, accurate context.
**Delivers:** `/vault:generate-context` skill, `context-generator` agent, `hooks/hooks.json` (SessionStart), `inject-context.sh`, CLAUDE.md with `generated:` timestamp, AGENTS.md, .cursorrules, GEMINI.md
**Addresses:** CLAUDE.md generation (table stakes), cross-agent context files (table stakes), SessionStart hook (differentiator), condensed vault index (differentiator)
**Avoids:** CLAUDE.md context drift pitfall (deterministic frontmatter extraction, not AI prose); SessionStart hook context overflow pitfall (two-tier strategy, pre-generated index, 6K character ceiling); cross-agent format incompatibility pitfall (plain markdown, no XML tags, overlay file pattern)

### Phase 7: Vault Health Analysis
**Rationale:** Requires a populated vault with dashboards and context (Phases 2-6). Vault analyzer is the "should have" enhancement — the vault is fully functional without it. Build last because it is the most complex agent (scans everything) and the most likely to produce premature suggestions if vault conventions are not yet stable.
**Delivers:** `/vault:analyze` skill, `vault-analyzer` agent (orphan detection, stale link detection, tag inconsistency analysis, MOC candidate suggestions)
**Addresses:** Proactive vault health analysis (differentiator)
**Avoids:** Proactive suggestions anti-pattern — vault health analysis only runs on explicit `/vault:analyze` invocation; never auto-runs mid-session

### Phase Ordering Rationale

- Knowledge skills (Phase 1) precede all commands because auto-invoked skills load by context match — they must be registered before any user-facing skill can benefit from them
- Setup (Phase 2) must precede everything that reads vault structure — no folder hierarchy means no valid routing destinations
- Capture (Phase 3) precedes organize (Phase 4) because organize assumes inbox has notes to triage; building organize first would require test fixture notes instead of real production data
- Dashboards (Phase 5) precede context generation (Phase 6) because the context generator reads dashboard frontmatter; the schema must be stable before the generator is built
- Context generation (Phase 6) precedes vault analysis (Phase 7) because the vault analyzer needs a populated, structured vault to analyze; it also benefits from reading existing CLAUDE.md for project context
- This ordering directly mirrors the hard dependency graph in ARCHITECTURE.md's "Build Order" section — not coincidental

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Quick Capture routing):** Smart routing confidence thresholds and decision algorithm need validation — what constitutes "low confidence" that should trigger inbox fallback is not established by research; needs experimentation or domain-expert input
- **Phase 6 (Context Generation):** Optimal CLAUDE.md structure for cross-agent readability needs testing against real non-Claude agents (Cursor, Gemini CLI) — the AGENTS.md standard is emerging (supported by Codex, Cursor, Windsurf, GitHub Copilot) but specification details are still evolving as of 2026-03-28
- **Phase 6 (SessionStart Hook):** Hook injection character count behavior under real vault conditions needs empirical measurement — the 10,000-character cap is documented but the behavior of truncation (silent vs. error) should be verified against the current Claude Code version

Phases with standard patterns (skip research-phase):
- **Phase 1 (Foundation):** Plugin scaffold structure is definitively documented in official Claude Code plugin docs; SKILL.md format is verified
- **Phase 2 (Setup Wizard):** PARA folder structure is a well-established method with multiple reference implementations; non-destructive brownfield pattern is well-documented in PITFALLS.md
- **Phase 4 (Inbox Organization):** Skill-Delegates-to-Agent pattern is clearly specified in ARCHITECTURE.md; implementation is straightforward once the pattern is established in Phase 4
- **Phase 5 (Dashboards):** Template creation is standard file writing; dashboard frontmatter schema follows established Obsidian conventions

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core plugin format verified against official Claude Code docs (code.claude.com, accessed 2026-03-28); npm package versions verified; existing installed plugins inspected at local filesystem |
| Features | HIGH (ecosystem), MEDIUM (cross-agent specifics) | Ecosystem patterns verified against 4 reference projects and 86-plugin taxonomy; cross-agent context format standards (AGENTS.md) are emerging and specifications may shift |
| Architecture | HIGH | Verified against official Claude Code plugin documentation; existing installed plugin (obsidian@claude-pro-skills v2.3.0) inspected locally for structural patterns; build order derived from hard dependency analysis |
| Pitfalls | HIGH | Multiple independent sources (post-mortems, official docs, community guides, MIT research); character cap limit and truncation behavior from official hooks reference |

**Overall confidence:** HIGH

### Gaps to Address

- **Routing confidence thresholds:** Research confirms that routing overconfidence is a critical pitfall and that showing confidence levels is mandatory, but it does not specify the algorithm for computing confidence or the threshold below which inbox fallback should trigger. Address during Phase 3 planning — likely requires a simple heuristic (folder name keyword match score) with a defined floor, not ML.

- **AGENTS.md specification stability:** AGENTS.md is described as an "emerging cross-tool standard" supported by Codex, Cursor, Windsurf, and GitHub Copilot. The exact frontmatter schema and file location conventions may differ across tools. Validate the target format against current Cursor and Gemini CLI documentation during Phase 6 planning.

- **Vault detection heuristic in inject-context.sh:** The ARCHITECTURE.md reference implementation uses `git rev-parse --show-toplevel` to find vault root. This assumes vaults are git repositories, which may not hold for all users. A more robust detection strategy (e.g., presence of `organization.md` or `CLAUDE.md` at a directory) should be decided during Phase 6 planning before the hook is implemented.

- **Dashboard refresh timing:** FEATURES.md defers `/vault:refresh-dashboard` to v1.x (post-launch validation). If project dashboard creation (Phase 5) generates dashboards that become stale quickly, the refresh feature may need to be pulled into v1. Flag for reassessment after Phase 5 is in use.

---

## Sources

### Primary (HIGH confidence)
- [Claude Code Plugins Reference — code.claude.com](https://code.claude.com/docs/en/plugins-reference) — plugin manifest schema, `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, hook types
- [Claude Code Skills Reference — code.claude.com](https://code.claude.com/docs/en/skills) — SKILL.md frontmatter, invocation control, `context: fork`, `$ARGUMENTS`
- [Claude Code Hooks Reference — code.claude.com](https://code.claude.com/docs/en/hooks) — SessionStart JSON output schema, `hookSpecificOutput.additionalContext`, 10,000-character injection cap
- [gray-matter — npm](https://www.npmjs.com/package/gray-matter) — version 4.0.3 confirmed, 3549 dependents
- Local filesystem: `~/.claude/plugins/cache/claude-pro-skills/obsidian/2.3.0/` — structural pattern inspection

### Secondary (MEDIUM confidence)
- [COG second-brain (huytieu)](https://github.com/huytieu/COG-second-brain) — 17 skills, multi-agent (Claude, Kiro, Gemini CLI, Codex), reference for cross-agent patterns
- [obsidian-claude-pkm (ballred)](https://github.com/ballred/obsidian-claude-pkm) — `/adopt` brownfield pattern, `note-organizer` agent
- [second-brain (earlyaidopters)](https://github.com/earlyaidopters/second-brain) — 4 slash commands, shell-based vault setup, CLAUDE.md generation
- [Vibehackers: Building a Second Brain with Claude Code](https://vibehackers.io/blog/claude-code-second-brain) — post-mortem on stale context, 80% continuity ceiling
- [ClaudeFast: Session Lifecycle Hooks](https://claudefa.st/blog/tools/hooks/session-lifecycle-hooks) — 10,000-character injection cap, silent truncation
- [VibeCoding: AGENTS.md Cross-Agent Compatibility Guide](https://vibecoding.app/blog/agents-md-guide) — AGENTS.md vs CLAUDE.md vs GEMINI.md format standards
- [Context Engineering for Claude Code (Anthropic)](https://code.claude.com/docs/en/best-practices) — CLAUDE.md size limits, pointer-not-copy pattern, 50KB threshold

### Tertiary (LOW confidence / needs validation)
- MIT Research (January 2025) via WebSearch — LLMs use 34% more confident language when hallucinating; routing confidence signal rationale
- [Medium: 3 Steps for Adapting PARA to an Existing Vault](https://medium.com/the-shortform/3-steps-for-adapting-tiago-fortes-para-method-to-an-existing-system-dc44b5169b1d) — overlay-based PARA adaptation pattern
- [kepano/obsidian-skills — GitHub](https://github.com/kepano/obsidian-skills) — Agent Skills open standard; reference for skill structure conventions

---
*Research completed: 2026-03-28*
*Ready for roadmap: yes*
