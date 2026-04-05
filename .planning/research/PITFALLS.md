# Pitfalls Research

**Domain:** AI-powered Obsidian vault management Claude Code plugin
**Researched:** 2026-03-28
**Confidence:** HIGH (multiple sources, verified against official docs and community post-mortems)

---

## Critical Pitfalls

### Pitfall 1: Brownfield Vault Destructive Setup

**What goes wrong:**
The setup wizard scans an existing vault and imposes the canonical folder structure (PARA + category subfolders) by moving or renaming existing notes without explicit per-file user approval. A user with 500 notes in a personal folder hierarchy runs `/vault:setup` and returns to find notes reorganized, wikilinks broken, and their mental map of the vault destroyed. There is no undo.

**Why it happens:**
Greenfield testing makes this invisible. Developers test against empty vaults where the wizard always produces the right output. The assumption is that "better structure" justifies automatic migration. Obsidian internally updates links when files move via its API, but external moves (shell `mv`, Claude Code file tools) break wikilinks silently.

**How to avoid:**
- During setup, run discovery-only mode first: scan and report what exists, never touch files
- Present a diff-style proposal ("I would create these folders, no files will be moved")
- For brownfield vaults, offer to add frontmatter (`area:`, `project:` tags) to existing notes instead of moving them — the PARA structure can be overlay-based, not folder-based
- Gate any file operation on explicit per-file user confirmation in the interactive approval step
- Add a dry-run flag to every command that touches files

**Warning signs:**
- Setup command contains `mv`, `rename`, or `moveFile` calls without a confirmation gate
- Tests only cover empty vault scenarios
- No distinction between greenfield and brownfield paths in setup logic

**Phase to address:**
Setup wizard phase (Phase 1). Must be designed non-destructively from day one — retrofitting safety is harder than building it in.

---

### Pitfall 2: CLAUDE.md Context Drift and Stale State

**What goes wrong:**
The auto-generated CLAUDE.md summarizing active projects, inbox state, and vault map is generated once and never regenerated. Over days or weeks, projects change, notes are added, and the context drifts. Claude Code sessions use stale project state — agents reference projects that ended, miss new ones, and make suggestions based on outdated architecture docs. One developer reported debugging for an hour before realizing the agent was working from a November description of a system refactored in January.

**Why it happens:**
Generating CLAUDE.md requires scanning the vault, which has a cost (time, tokens for analysis). Developers defer regeneration to an explicit command rather than making it cheap and automatic. Users also do not realize their context file has drifted until a session produces obviously wrong output.

**How to avoid:**
- CLAUDE.md must be a thin, deterministic file — derived from structured frontmatter in project dashboards, not AI-written prose. Structured data does not drift; prose summaries do.
- Include a `generated:` timestamp at the top of CLAUDE.md so users see staleness immediately
- The `/vault:context` command (or equivalent) should regenerate the file in under 2 seconds by reading only project dashboard frontmatter, not full note content
- The SessionStart hook should display the CLAUDE.md generation timestamp so users know how fresh their context is
- Never rely on AI to decide what is "current" in CLAUDE.md — use deterministic extraction from project notes

**Warning signs:**
- CLAUDE.md is written as prose paragraphs by the AI rather than structured YAML/markdown sections
- No `generated:` or `last_updated:` field in the file
- Regeneration requires reading note bodies, not just frontmatter
- No reminder mechanism when CLAUDE.md is older than N days

**Phase to address:**
CLAUDE.md generation phase. Establish the deterministic template format before wiring up regeneration logic.

---

### Pitfall 3: SessionStart Hook Context Overflow

**What goes wrong:**
The SessionStart hook scans the vault, generates a summary of all active projects and recent inbox items, and injects it as context. On a vault with 50+ projects and a large inbox, the generated context exceeds the 10,000-character hook injection cap. Claude Code truncates the output and replaces it with a file path preview. The agent starts each session with incomplete context and no indication to the user that truncation occurred.

**Why it happens:**
Hook injection limits are not obvious during development when the vault is small. The hook is tested with 5 projects and 10 inbox notes — well under the limit. In production with a real engineer's 3-year-old vault, the same hook silently truncates.

**How to avoid:**
- Keep hook-injected context under 6,000 characters (budget well under the 10,000-character cap)
- Use a two-tier strategy: inject a condensed index (project names, statuses, counts) via the hook; put full context in a pre-generated CLAUDE.md file that Claude reads on demand
- Never scan note bodies in the SessionStart hook — read only pre-generated index files
- Log the injected context character count during development and add a test for vaults with 50+ projects

**Warning signs:**
- SessionStart hook reads note content rather than a pre-built index
- Hook output grows proportionally with vault size (no hard ceiling)
- No test for large vault scenarios
- Hook runtime exceeds 1 second on a 200-note vault

**Phase to address:**
SessionStart hook implementation phase. Design the two-tier architecture (hook injects summary pointer, CLAUDE.md carries the payload) from the beginning.

---

### Pitfall 4: Note Routing Overconfidence Without Fallback

**What goes wrong:**
The quick-capture command analyzes content and suggests a destination. The AI is confidently wrong — routing a meeting note about "Q3 planning" to a generic "Resources/Planning" folder when the user meant "Projects/Atlas/notes/". The user accepts the suggestion (because the interface presents it confidently), and the note is filed incorrectly. Over time, notes accumulate in wrong locations and the vault degrades.

**Why it happens:**
LLMs are 34% more likely to use confident language when hallucinating than when correct (MIT research, January 2025). Routing interfaces often display a single suggestion without communicating uncertainty. Users trust confident output, especially when they are in a fast-capture flow.

**How to avoid:**
- Always show confidence level alongside routing suggestions ("I'm fairly confident this belongs in Projects/Atlas — does that look right?")
- When confidence is below a threshold, route to inbox instead of a specific folder and explain why ("Not sure which project this belongs to — added to inbox for manual triage")
- Show the top 2-3 destination candidates, not just one
- Make "send to inbox instead" the zero-friction escape hatch — one keystroke, always available
- Never auto-file without user confirmation in v1

**Warning signs:**
- Routing command displays only one destination with no confidence signal
- No inbox fallback path in the routing logic
- User acceptance rate > 95% (indicates users are not reviewing suggestions critically)
- No mechanism to see what the runner-up destinations were

**Phase to address:**
Quick capture command phase. Build the confidence communication into the UX contract before implementing routing logic.

---

### Pitfall 5: Cross-Agent Context Format Incompatibility

**What goes wrong:**
CLAUDE.md is written with Claude Code-specific formatting (slash command references, `<context>` XML tags, Anthropic-specific conventions). When the same file is opened by Cursor, Gemini CLI, or another markdown-aware agent, the formatting is confusing or the structure is unreadable. The "any agent gets instant context" value proposition breaks for non-Claude agents.

**Why it happens:**
Development and testing only use Claude Code. The cross-agent requirement is stated but never tested. Claude-specific idioms accumulate over time (XML tags, internal tool references) until the file stops being generic markdown.

**How to avoid:**
- Write CLAUDE.md as plain markdown with no XML tags, no slash command references, and no tool-specific syntax
- Add agent-specific overlay files (GEMINI.md, `.cursor/rules/vault.mdc`) that extend CLAUDE.md with tool-specific instructions rather than replacing it
- Put shared conventions in CLAUDE.md; put tool-specific behavior in the overlay files
- Include "agent compatibility" as a test criterion: open CLAUDE.md in Cursor and Gemini CLI as part of manual testing
- Use AGENTS.md (the emerging cross-tool standard, natively supported by Codex, Cursor, Windsurf, GitHub Copilot) as the primary shared context file; use CLAUDE.md for Claude Code-specific additions

**Warning signs:**
- CLAUDE.md contains XML tags (`<context>`, `<instructions>`) or `!` command prefixes
- No test ever runs the context files in a non-Claude agent
- AGENTS.md does not exist in the vault template
- Overlay file generation is missing from the feature set

**Phase to address:**
Cross-agent context file phase. Define the file taxonomy (AGENTS.md shared base + CLAUDE.md Claude-specific overlay) before implementing generation logic.

---

### Pitfall 6: Vault Index That Cannot Stay Current

**What goes wrong:**
The plugin generates a vault index file (project list, folder map, note count) during setup. The index is never updated unless the user explicitly runs a refresh command. New projects are added to the vault but not indexed. Agents reading the index believe the vault has 12 projects when it has 20. Inbox organization uses a stale project list to propose destinations and never suggests the correct new project.

**Why it happens:**
Index regeneration requires vault traversal. Developers treat it as an expensive operation and make it on-demand only. Users forget to run it. There is no signal that the index is stale.

**How to avoid:**
- Make index regeneration cheap by design: traverse only one metadata file per project (the dashboard) rather than the full folder tree
- Include a `generated:` timestamp in the index file; show it in the SessionStart context injection
- For inbox organization and routing, read the live project list from the filesystem (project folder names) rather than the cached index — this is always current
- Cache only what is genuinely expensive to compute (e.g., summarized descriptions); never cache what can be read live cheaply (e.g., project names from folder list)

**Warning signs:**
- Index file has no timestamp
- Routing suggestions reference projects that no longer exist
- User must manually run a refresh command after creating a new project
- No test validates that a newly created project appears in routing suggestions without manual refresh

**Phase to address:**
Vault indexing and CLAUDE.md generation phase.

---

### Pitfall 7: Claude Code Plugin Directory Structure Misplacement

**What goes wrong:**
The plugin ships with `commands/`, `agents/`, `skills/`, or `hooks/` directories placed inside `.claude-plugin/` rather than at the plugin root. Claude Code's plugin loader ignores them. Commands silently do nothing. The plugin appears installed but none of the slash commands work.

**Why it happens:**
It is intuitive to put everything inside the `.claude-plugin/` folder since that is the named plugin container. The official documentation states that only `plugin.json` goes inside `.claude-plugin/` — all other directories must be at the plugin root — but this is non-obvious and a common misread.

**How to avoid:**
- Use the correct structure from project initialization:
  ```
  vault-plugin/
  ├── .claude-plugin/
  │   └── plugin.json          # ONLY this file goes here
  ├── commands/
  ├── agents/
  ├── skills/
  └── hooks/
  ```
- Use `${CLAUDE_PLUGIN_ROOT}` for all path references in `plugin.json` to ensure portability
- Add a smoke test that verifies each registered command can be invoked after installation

**Warning signs:**
- Any `.md` file or subdirectory besides `plugin.json` inside `.claude-plugin/`
- Slash commands registered in `plugin.json` return "command not found" after install
- No installation smoke test in the development workflow

**Phase to address:**
Plugin scaffolding phase (Phase 1). Correct from the first file created.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Write CLAUDE.md as AI-generated prose | Richer, more readable output | Drifts immediately; cannot be deterministically regenerated; agents read stale state | Never — use deterministic structured extraction |
| Single monolithic CLAUDE.md for all agents | Simpler to generate | Claude-specific formatting breaks non-Claude agents; cross-agent value proposition fails | Never for shared context file; use overlay pattern |
| Scan full note bodies in SessionStart hook | More accurate context | Exceeds 10K-char injection cap on real vaults; slow startup | Never — pre-generate index files, inject summaries |
| Route notes without confidence signal | Cleaner UI | Users accept wrong destinations without realizing it; vault degrades silently | Never for v1; confidence communication is a core safety mechanism |
| Skip brownfield path in setup wizard | Faster to ship | First user with an existing vault loses notes or breaks links | Never — brownfield is the primary use case for engineers with existing vaults |
| On-demand-only index regeneration | Simpler implementation | Stale index causes wrong routing suggestions; users stop trusting the plugin | Acceptable for v1 if staleness is visibly communicated; must be automatic by v2 |
| Hardcode PARA folder names | No configuration complexity | Conflicts with users who use different top-level names (e.g. "Work" not "Projects") | Acceptable for v1 greenfield path only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Claude Code SessionStart hook | Generating context inside the hook at runtime | Pre-generate CLAUDE.md on demand; hook reads and injects the pre-built file (stay under 6K chars) |
| Claude Code plugin.json path references | Using relative paths or hardcoded absolute paths | Always use `${CLAUDE_PLUGIN_ROOT}` variable for cross-machine portability |
| Obsidian wikilinks on file move | Using shell `mv` or raw filesystem rename | Use Obsidian's file manager API if available; otherwise present moves as proposals the user confirms, then execute one at a time |
| Cross-agent context files | Writing Claude-specific XML in the shared context file | Keep CLAUDE.md and AGENTS.md as plain markdown; put Claude-specific syntax only in Claude-targeted overlay sections |
| Gemini CLI context | Assuming CLAUDE.md is read by Gemini | Generate GEMINI.md as a separate overlay; CLAUDE.md is not read by Gemini CLI natively |
| Cursor context | Using only `.cursorrules` (deprecated pattern) | Use `.cursor/rules/vault.mdc` with YAML frontmatter for glob-based scoping (current Cursor standard) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Full vault scan in SessionStart hook | Slow session startup (5-30 seconds); hook times out on large vaults | Pre-generate index file; hook reads only the index | Vaults with 200+ notes |
| AI-based routing with full note context | Routing suggestions take 10+ seconds; high token cost per capture | Use project list from filesystem + note title + first paragraph only | Any vault when latency matters for quick capture |
| Loading all project dashboards for context | CLAUDE.md generation takes minutes on 30+ project vault | Read only frontmatter (`project:`, `status:`, `last_active:`) not full dashboard content | 20+ active projects |
| Monolithic CLAUDE.md with all note summaries | Exceeds 200K context window; autocompact triggers prematurely | Hard cap CLAUDE.md at 4,000 tokens; use pointers to files for detail | Any vault in a long session |
| Context7 / MCP tool definitions bloat | 20K+ tokens consumed before first message; 70K effective context | Keep MCP servers under 10; use Tool Search lazy loading (available since late 2025) | When installing the plugin alongside 10+ other MCP servers |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Routing command presents single confident destination | Users auto-accept wrong folder; vault degrades over weeks | Show top 2-3 candidates with confidence labels; make inbox fallback one keystroke |
| Setup wizard asks too many questions upfront | Users abandon wizard before completing it; partial setup leaves vault in inconsistent state | Collect only vault path and mode (greenfield/brownfield); infer everything else; let user confirm folder structure proposal before touching anything |
| Inbox organization proposes all items at once | Overwhelming for inboxes with 30+ notes; users reject the whole batch | Propose one item at a time; show progress ("3 of 12 inbox items"); allow "skip for now" per item |
| Context file generation is invisible | Users do not know when CLAUDE.md was last updated; continue using stale context | Display `generated: 2026-03-28` prominently at the top of CLAUDE.md; show it in session start output |
| Project dashboard creation creates empty category subfolders | Looks cluttered for simple projects; users delete folders immediately | Create only the folders referenced in the initial template; offer to add more on demand |
| Proactive suggestions run during active work | Interrupts focus; suggestions feel intrusive | Proactive analysis only runs when explicitly invoked via `/vault:analyze`; never auto-runs mid-session |

---

## "Looks Done But Isn't" Checklist

- [ ] **Setup wizard (brownfield):** Appears to complete successfully — verify no files were moved without per-item user confirmation and wikilinks are intact
- [ ] **CLAUDE.md generation:** Appears to contain correct project list — verify the list is derived from live filesystem scan, not a cached index from last month
- [ ] **SessionStart hook:** Appears to inject context — verify the injected content is under 6,000 characters on a vault with 40+ projects and 20+ inbox items
- [ ] **Quick capture routing:** Suggests a plausible destination — verify a low-confidence case routes to inbox, not to a guessed folder
- [ ] **Cross-agent files:** AGENTS.md and CLAUDE.md exist — verify AGENTS.md contains no Claude-specific XML tags and renders cleanly in a plain markdown viewer
- [ ] **Plugin installation:** All commands show in `/` menu — verify each command actually executes (not just appears) by running a smoke test against a test vault
- [ ] **Project dashboard creation:** Dashboard file is created — verify the `architecture/`, `requirements/`, `decisions/`, `notes/` subfolders are created alongside it
- [ ] **Inbox organization:** Agent proposes destinations — verify it uses the current project list (including projects created after the last index rebuild)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Brownfield files moved without approval | HIGH | Git restore if vault is version-controlled; otherwise manual reconstruction from OS file recovery tools; broken wikilinks must be repaired manually |
| CLAUDE.md serving stale context | LOW | Run `/vault:context` to regenerate; staleness is self-correcting once regeneration is cheap |
| SessionStart hook context truncated | LOW | Manually run `/vault:context` at session start; redesign hook to inject summary pointer only |
| Notes routed to wrong folder | MEDIUM | Add a `/vault:move` command that shows recent agent-filed notes and lets user correct destinations |
| Plugin commands not found after install | LOW | Check that `commands/`, `agents/`, `hooks/` are at plugin root not inside `.claude-plugin/`; reinstall |
| CLAUDE.md unreadable by non-Claude agents | MEDIUM | Rewrite shared content as plain markdown; regenerate agent-specific overlays |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Brownfield vault destructive setup | Phase 1 (Setup wizard) | Test against vault with 100 existing notes; verify zero files moved without confirmation |
| CLAUDE.md context drift | Phase 2 (Context generation) | Check `generated:` timestamp logic; verify regeneration reads live data not cache |
| SessionStart hook context overflow | Phase 2 (Hooks) | Run hook against 50-project vault; measure injected character count |
| Note routing overconfidence | Phase 3 (Quick capture) | Test routing against 10 ambiguous inputs; verify inbox fallback triggers for low-confidence cases |
| Cross-agent format incompatibility | Phase 4 (Cross-agent files) | Open generated AGENTS.md in Cursor; verify no Claude-specific syntax present |
| Stale vault index | Phase 2 (Index) | Create new project; verify it appears in routing suggestions without running refresh |
| Plugin directory misplacement | Phase 1 (Scaffolding) | Run installation smoke test; verify all slash commands respond |

---

## Sources

- [Vibehackers: Building a Second Brain with Claude Code — Three Months of Lessons](https://vibehackers.io/blog/claude-code-second-brain) — post-mortem on stale context, curation burden, 80% continuity ceiling
- [DEV Community: Claude Code Hooks for Guaranteed Context Injection](https://dev.to/sasha_podles/claude-code-using-hooks-for-guaranteed-context-injection-2jg) — skills skipped in 56% of eval cases, context window overhead from hooks
- [MindStudio: Claude Code Skills Common Mistakes Guide](https://www.mindstudio.ai/blog/claude-code-skills-common-mistakes-guide) — too many skills, monolithic files, context bloat
- [ClaudeFast: Context Buffer Management](https://claudefa.st/blog/guide/mechanics/context-buffer-management) — 33K autocompact buffer, information loss at compaction threshold
- [ClaudeFast: Session Lifecycle Hooks](https://claudefa.st/blog/tools/hooks/session-lifecycle-hooks) — 10,000-character injection cap, silent truncation behavior
- [DeepWiki: Obsidian Gemini Vault Context Generation](https://deepwiki.com/allenhutchison/obsidian-gemini/7.2-vault-context-generation-(agents.md)) — caching strategy, 3-level depth limit, API response parsing fragility
- [VibeCoding: AGENTS.md Cross-Agent Compatibility Guide](https://vibecoding.app/blog/agents-md-guide) — AGENTS.md vs CLAUDE.md vs GEMINI.md format standards
- [Claude Code Docs: Hooks Reference](https://code.claude.com/docs/en/hooks) — official hook behavior, SessionStart semantics
- [Claude Code Docs: Create Plugins](https://code.claude.com/docs/en/plugins) — official plugin directory structure; `.claude-plugin/` contains only `plugin.json`
- [Medium: 3 Steps for Adapting PARA to an Existing Vault](https://medium.com/the-shortform/3-steps-for-adapting-tiago-fortes-para-method-to-an-existing-system-dc44b5169b1d) — overlay-based PARA adaptation vs destructive folder migration
- MIT Research (January 2025) via WebSearch — LLMs use 34% more confident language when hallucinating than when correct

---
*Pitfalls research for: AI-powered Obsidian vault management Claude Code plugin*
*Researched: 2026-03-28*
