# Phase 2: Daily Workflows - Research

**Researched:** 2026-04-04
**Domain:** Claude Code plugin skills -- note capture, inbox organization, project dashboard management
**Confidence:** HIGH

## Summary

Phase 2 implements the three daily-use slash commands: `/vault:capture`, `/vault:organize-inbox`, and `/vault:project-dashboard`. All three are SKILL.md files that Claude interprets and executes using built-in tools (Read, Write, Bash, Glob, Grep). There is no custom runtime code to write -- each skill is a structured prompt with instructions for Claude to follow, exactly like the `init` skill built in Phase 1.

The key technical challenges are: (1) the capture routing heuristic -- how the skill instructs Claude to analyze content and suggest a destination with a confidence indicator, (2) the inbox organize flow -- iterating inbox items one-by-one with user confirmation before each move, and (3) project dashboard refresh -- scanning existing project folders to derive task counts and status from actual vault content.

**Primary recommendation:** Follow the init skill pattern exactly -- each skill is a SKILL.md with step-by-step instructions, no supporting scripts needed. Claude's built-in reasoning handles content analysis, routing, and frontmatter generation. The vault-schema reference skill already defines all routing rules and frontmatter conventions.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAPT-01 | Capture freeform text into structured note with frontmatter and timestamp | Capture skill creates note using inbox-note template pattern, adds frontmatter per vault-schema spec |
| CAPT-02 | Suggest destination with confidence indicator | Skill instructions define routing heuristic: scan vault for projects/areas, keyword match, output confidence as HIGH/MEDIUM/LOW |
| CAPT-03 | User accepts or overrides destination (inbox as fallback) | Skill presents suggestion, asks user to confirm/override, defaults to 00 Inbox/ |
| CAPT-04 | Apply appropriate template based on content type and destination | Skill reads templates from vault's 20 Templates/, selects based on destination (project -> project-dashboard sections, inbox -> inbox-note) |
| ORG-01 | Process all files in inbox/ | Organize skill globs 00 Inbox/*.md, iterates each |
| ORG-02 | Propose destination with rationale per item | Skill reads each note, analyzes content + frontmatter, proposes destination using vault-schema routing rules |
| ORG-03 | User confirms or overrides each move | Skill presents proposal per item, waits for user response before proceeding |
| ORG-04 | Update MOCs and wikilinks after moves | After confirmed moves, skill scans for broken wikilinks and updates them; optionally adds to relevant MOC |
| PROJ-01 | Create project folder with subfolders and Dashboard.md + Tasks.md | Project skill creates 01 Projects/name/ with architecture/, requirements/, decisions/, notes/ subfolders plus Dashboard.md and Tasks.md from templates |
| PROJ-02 | Refresh existing dashboard from vault content | Skill detects existing project folder, scans for task checkboxes, note counts, last-modified dates |
| PROJ-03 | Dashboard shows phase, status, open tasks, key links, recent activity | Dashboard.md template sections populated from scan results |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Plugin format**: Claude Code plugin (plugin.json, skills, agents, hooks)
- **Local-only**: All data stays on the user's machine as plain .md files
- **Non-destructive**: Never move or rename files without explicit user approval
- **Cross-agent**: Context files must work for Claude Code, Cursor, Gemini CLI
- **Fast context loading**: Use pre-generated index, not full vault scans
- **Dependencies**: gray-matter, fast-glob, js-yaml available via lazy install to CLAUDE_PLUGIN_DATA
- **No Python scripts**: Bash for simple scripts, Node.js for complex parsing
- **No file watchers**: v1 is on-demand only
- **Complement existing plugins**: Do not duplicate note creation/formatting from obsidian@claude-pro-skills

## Standard Stack

### Core

No new dependencies needed. Phase 2 skills are SKILL.md files -- structured prompts that Claude executes using built-in tools.

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md format | Current | Define /vault:capture, /vault:organize, /vault:project commands | Same pattern as init skill from Phase 1 -- proven working |
| Claude built-in tools | Current | Read, Write, Bash, Glob, Grep for file operations | Already declared in skill frontmatter `allowed-tools` |
| vault-schema reference skill | N/A | Provides routing rules, frontmatter spec, naming conventions | Already exists -- Claude auto-loads it when relevant |
| Existing templates | N/A | Project Dashboard, Task List, Inbox Note | Installed to vault's 20 Templates/ by init skill |

### Supporting (available but likely not needed for Phase 2)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| gray-matter | ^4.0.3 | Parse YAML frontmatter from .md files | Only if a bash/node helper script is needed -- but Claude's Read tool can parse frontmatter directly |
| fast-glob | ^3.3.0 | Recursive file pattern matching | Only if Glob tool is insufficient -- unlikely |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Claude reasoning for routing | Node.js keyword-match script | Script would be faster but less accurate; Claude can read vault structure and reason about context. For v1, Claude's reasoning is the right call -- no custom code to maintain. |
| Per-item user confirmation loop | Batch confirmation | Batch would be faster but violates ORG-03 (user confirms each item). Per-item is required. |

## Architecture Patterns

### Skill Directory Structure (Phase 2 additions)

```
skills/
  capture/SKILL.md       # Replace stub with full implementation
  organize/SKILL.md      # Replace stub with full implementation
  project/SKILL.md       # Replace stub with full implementation
  schema/SKILL.md        # Already exists -- no changes needed
  agent-context/SKILL.md # Already exists -- no changes needed
  init/SKILL.md          # Already exists -- no changes needed
```

No new directories. No supporting files needed. Each skill is self-contained in its SKILL.md.

### Pattern 1: Step-by-Step Skill Instructions (from init skill)

**What:** SKILL.md contains numbered steps that Claude follows sequentially. Each step has clear inputs, actions, and outputs.
**When to use:** All three Phase 2 skills.
**Example (from init skill):**
```markdown
## Step 1: Detect Vault State
Scan the current working directory for vault markers...

## Step 2: Build Proposal
Propose the full PARA structure...

## Step 3: Present Proposal
Show the complete proposal to the user...
Ask: "Approve this plan?"
Do not proceed until the user responds.
```

### Pattern 2: User Confirmation Gate

**What:** Skill explicitly instructs Claude to stop and wait for user input before proceeding with destructive actions.
**When to use:** Capture (confirm destination), Organize (confirm each move), Project (confirm creation).
**Key rule:** The SKILL.md must contain explicit "Do not proceed until the user responds" instructions at each gate.

### Pattern 3: Vault-Aware Context Loading

**What:** Skill instructions tell Claude to read vault:config.md and scan the vault structure before making routing decisions.
**When to use:** Capture routing, organize routing.
**Pattern:**
```markdown
## Step 1: Load Vault Context
1. Read `vault:config.md` for folder conventions and routing rules
2. Glob `01 Projects/*/` to list active projects
3. Glob `02 Areas/*/` to list active areas
4. Read frontmatter of each project's Dashboard.md for status and tags
```

### Pattern 4: Confidence-Based Routing (for CAPT-02)

**What:** Capture skill instructs Claude to evaluate content against known projects/areas and assign a confidence level.
**When to use:** Capture command destination suggestion.
**Heuristic (defined in skill instructions):**
- **HIGH confidence**: Content explicitly mentions an existing project name or area name, or contains a wikilink to a known project
- **MEDIUM confidence**: Content contains keywords strongly associated with a known project/area (e.g., technology names, domain terms found in project dashboards)
- **LOW confidence / Inbox**: Content is generic, no clear project/area match -- route to 00 Inbox/

The skill presents the suggestion as: `Suggested destination: 01 Projects/my-project/notes/ (HIGH confidence -- mentions "my-project" directly)`

### Anti-Patterns to Avoid

- **Hardcoded routing logic in scripts**: Do not write a Node.js script for routing. Claude reads the vault and reasons about content. The routing rules live in vault-schema SKILL.md and capture SKILL.md instructions.
- **Batch inbox processing without per-item confirmation**: ORG-03 requires per-item approval. Never process multiple items without individual user confirmation.
- **Overwriting existing project dashboards on create**: PROJ-01 creates new projects. If the project folder already exists, skill must detect this and switch to refresh mode (PROJ-02).
- **Moving files without updating links**: ORG-04 requires wikilink updates after moves. The organize skill must grep for `[[old-filename]]` references and update them.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Frontmatter parsing | Custom regex parser | Claude's Read tool (reads file, Claude parses YAML natively) | Claude understands YAML frontmatter without any library |
| File globbing | Custom directory walker | Glob tool with patterns like `00 Inbox/*.md` | Built-in tool, already declared in allowed-tools |
| Content analysis / routing | Keyword matching script | Claude's reasoning over vault context | Claude can read project dashboards and match content semantically -- far more accurate than keyword scripts |
| Template application | String replacement engine | Claude reads template, fills in values, writes result | Templates use simple {{date}}/{{title}} placeholders -- Claude handles this trivially |
| Wikilink detection | Regex library | Grep tool with pattern `\[\[filename\]\]` | Simple pattern, built-in tool handles it |

**Key insight:** In a Claude Code plugin, Claude IS the runtime. Skills are instructions, not code. The tools (Read, Write, Bash, Glob, Grep) are the API. There is nothing to "implement" in the traditional sense -- the implementation is writing clear, precise SKILL.md instructions.

## Common Pitfalls

### Pitfall 1: Capture Routing Without Vault Context
**What goes wrong:** Skill tries to suggest a destination without first scanning the vault for existing projects/areas.
**Why it happens:** Skill instructions skip the "load vault context" step.
**How to avoid:** Step 1 of capture MUST glob projects and areas before analyzing content.
**Warning signs:** Destination suggestions reference non-existent folders.

### Pitfall 2: Organize Moving Files Before Confirmation
**What goes wrong:** Claude moves a file based on its own analysis before the user confirms.
**Why it happens:** SKILL.md instructions are ambiguous about the confirmation gate.
**How to avoid:** Explicit "Do not proceed" language after each proposal. Process items in a numbered list, one at a time.
**Warning signs:** Multiple files moved in a single action.

### Pitfall 3: Broken Wikilinks After Move
**What goes wrong:** Note is moved from inbox to a project folder, but other notes still reference the old path via `[[Note Name]]`.
**Why it happens:** Obsidian uses filename-only wikilinks (not paths) by default, so moves usually don't break links. BUT if the vault uses relative paths or if two notes have the same name, links can break.
**How to avoid:** After each move, grep for `[[moved-filename]]` across the vault. If references exist, verify they still resolve. If the filename changed, update references.
**Warning signs:** Obsidian shows broken link indicators after organize.

### Pitfall 4: Project Dashboard Overwrite on Refresh
**What goes wrong:** Refresh mode overwrites user-edited content in Dashboard.md.
**Why it happens:** Skill regenerates the entire file instead of updating only derived sections.
**How to avoid:** Refresh must READ the existing Dashboard.md, preserve user content (Overview, Notes, References sections), and only update derived data (task counts, status, last-updated timestamp).
**Warning signs:** User's custom overview text disappears after refresh.

### Pitfall 5: Template Selection Ambiguity
**What goes wrong:** Capture creates a note but doesn't apply the right template (e.g., creates a project note without project dashboard structure).
**Why it happens:** Content type detection is not explicit in skill instructions.
**How to avoid:** Define clear rules: if destination is a project folder, note gets minimal frontmatter (not full dashboard template -- that's for PROJ-01). Captures are always lightweight notes, not dashboards.
**Warning signs:** Captured notes have overly complex structure for simple content.

### Pitfall 6: Numbered Folder Prefix Inconsistency
**What goes wrong:** Skill creates files in `Inbox/` instead of `00 Inbox/`, or `Projects/` instead of `01 Projects/`.
**Why it happens:** SKILL.md uses inconsistent folder references.
**How to avoid:** All folder references in SKILL.md must use the numbered prefix format. Reference vault-schema skill which defines canonical names.
**Warning signs:** Files created in wrong directories.

## Code Examples

### Capture SKILL.md Structure (recommended)

```markdown
---
name: capture
description: Capture a note with smart destination suggestion
disable-model-invocation: true
allowed-tools: Read Write Bash Glob Grep
argument-hint: "<note content>"
---

## Step 1: Load Vault Context
1. Read `vault:config.md` for routing rules
2. Glob `01 Projects/*/Dashboard.md` to list active projects (read frontmatter for status/tags)
3. Glob `02 Areas/*.md` to list active areas

## Step 2: Analyze Content
Analyze `$ARGUMENTS` for:
- Explicit project/area mentions (names, wikilinks)
- Keywords matching known projects (from dashboard overviews, tags)
- Content type: task, reference, meeting note, idea, question

## Step 3: Suggest Destination
Present:
- **Suggested destination**: full path (e.g., `01 Projects/my-app/notes/`)
- **Confidence**: HIGH / MEDIUM / LOW
- **Reason**: why this destination was chosen
- **Fallback**: "Or place in 00 Inbox/ for later sorting"

Ask user to confirm or override. Do not proceed until user responds.

## Step 4: Create Note
[create with frontmatter, timestamp, template structure]
```

### Organize SKILL.md Per-Item Loop Pattern

```markdown
## Step 2: Process Each Item

For each file in the inbox (process ONE at a time):

1. Read the file content and frontmatter
2. Analyze content against known projects and areas
3. Present to user:
   - **File**: filename
   - **Summary**: 1-line content summary
   - **Proposed destination**: path with rationale
   - **Options**: (1) Accept (2) Override destination (3) Skip (4) Delete
4. Wait for user response
5. Execute ONLY the user's chosen action
6. Move to next file

Do NOT batch multiple files. Process one file, get confirmation, then move to the next.
```

### Project Dashboard Refresh Pattern

```markdown
## Step 3: Refresh Existing Dashboard (if project folder exists)

1. Read existing Dashboard.md -- preserve ALL user-written content
2. Scan project folder:
   - Count .md files in each subfolder (architecture/, requirements/, decisions/, notes/)
   - Count open tasks: grep for `- [ ]` across all project .md files
   - Count completed tasks: grep for `- [x]` across all project .md files
   - Find most recently modified file (use `ls -lt`)
3. Update ONLY these derived fields in Dashboard.md:
   - `updated:` frontmatter field -> today's date
   - Status section -> task counts, file counts
   - Last updated line -> today's date
4. Do NOT overwrite Overview, Key Links, Notes, or References sections
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Flat commands/*.md | skills/name/SKILL.md with frontmatter | Claude Code plugin v1 | Skills support supporting files, context forking, invocation control |
| Always dump to inbox | Smart routing with confidence | This project decision | Reduces organize-inbox workload |

## Open Questions

1. **Wikilink update scope for ORG-04**
   - What we know: Obsidian uses filename-only wikilinks by default (no path), so most moves don't break links
   - What's unclear: Should organize update MOCs proactively (add moved note to relevant MOC), or only fix broken links?
   - Recommendation: For v1, only fix broken links (rename-based). MOC updates are manual or deferred to Phase 3 analysis. Keep scope minimal.

2. **Capture note naming**
   - What we know: Schema defines Title Case with spaces for filenames
   - What's unclear: How to derive a filename from freeform capture text
   - Recommendation: Claude derives a short descriptive title from the content (3-5 words, Title Case). If ambiguous, asks the user.

3. **Dashboard refresh granularity**
   - What we know: PROJ-02 requires re-deriving task counts and status
   - What's unclear: How much of the dashboard to regenerate vs preserve
   - Recommendation: Preserve all user-written sections. Only update the Status block (task counts, dates) and the `updated:` frontmatter field. Never touch Overview, Key Links, Notes, or References.

## Sources

### Primary (HIGH confidence)
- Phase 1 implementation: `skills/init/SKILL.md` -- reference pattern for all Phase 2 skills
- `skills/schema/SKILL.md` -- PARA routing rules, frontmatter spec, naming conventions (canonical)
- `skills/agent-context/SKILL.md` -- context file conventions
- Phase 1 templates: `skills/init/templates/*.md` -- template structures to reference/reuse
- `hooks/hooks.json` -- current hook structure
- `.claude-plugin/plugin.json` -- plugin manifest

### Secondary (MEDIUM confidence)
- CLAUDE.md technology stack section -- verified against Phase 1 implementation
- STATE.md blocker note: "Phase 2 capture routing: confidence threshold algorithm not yet defined"

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- no new dependencies, follows Phase 1 pattern exactly
- Architecture: HIGH -- skill pattern proven in Phase 1, vault-schema provides all routing rules
- Pitfalls: HIGH -- derived from requirements analysis (non-destructive constraint, per-item confirmation requirement)

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable -- no external dependencies to go stale)
