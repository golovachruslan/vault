# Phase 1: Foundation + Setup - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the plugin scaffold (plugin.json, skill structure) and the `/vault:init` command that creates or adapts an Obsidian vault with PARA folder structure, core templates, and a machine-readable vault config. After this phase, a user can install the plugin and initialize a working vault.

</domain>

<decisions>
## Implementation Decisions

### Init Wizard Flow
- **D-01:** Auto-detect + confirm flow. Wizard detects if a vault exists, proposes the full structure, user approves in one shot. No multi-step interactive Q&A.
- **D-02:** CWD is the vault. User runs `/vault:init` inside their Obsidian vault directory. No path argument needed.
- **D-03:** Brownfield: propose migration. When existing vault detected, suggest moving existing notes into PARA structure with user confirming each move. Not just additive — actively helps restructure.

### Vault Config Format
- **D-04:** vault:config.md encodes ALL four convention types: folder conventions, frontmatter spec, linking rules, and agent instructions.
- **D-05:** Pointer + file pattern. CLAUDE.md and AGENTS.md say "Read vault:config.md for conventions" — the full spec lives in a separate file, not inlined.

### Plugin Structure
- **D-06:** SKILL.md only — no legacy commands/ directory. All slash commands are user-invocable skills.
- **D-07:** One skill per command. Each command gets its own skill directory: vault-init/, vault-capture/, vault-organize/, vault-project/, vault-suggest/, vault-sync/.
- **D-08:** Auto-invoked reference skills (vault-schema, agent-context, vault-analysis) are separate non-user-invocable skills that provide knowledge to commands and agents.

### Claude's Discretion
- Template content details (specific sections, frontmatter fields for the 3 core templates) — Claude decides based on research and Obsidian conventions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Plugin Format
- `.planning/research/STACK.md` — Plugin format conventions, SKILL.md spec, hook schema, lazy dependency pattern
- `.planning/research/ARCHITECTURE.md` — Component boundaries, data flow, build order, agent tool restrictions

### Features & Pitfalls
- `.planning/research/FEATURES.md` — Table stakes vs differentiators, dependency graph, MVP definition
- `.planning/research/PITFALLS.md` — Brownfield destruction risk, CLAUDE.md drift, plugin directory rules
- `.planning/research/SUMMARY.md` — Synthesized findings and roadmap implications

### Project Context
- `.planning/PROJECT.md` — Core value, requirements, constraints, key decisions
- `.planning/REQUIREMENTS.md` — SETUP-01 through SETUP-04 requirements for this phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, only README.md exists

### Established Patterns
- None yet — this phase establishes the patterns

### Integration Points
- Plugin installs into Claude Code via `claude plugin add <path>`
- Existing obsidian@claude-pro-skills handles note formatting and MOC creation — vault plugin must complement, not conflict
- Existing obsidian@obsidian-skills handles markdown/bases/canvas file editing

</code_context>

<specifics>
## Specific Ideas

- Reference project github.com/earlyaidopters/second-brain for vault structure inspiration (CLAUDE.md, inbox/, projects/, archive/ pattern)
- vault:config.md should be comprehensive enough that any agent (Claude, Cursor, Gemini) can understand vault conventions by reading one file

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-setup*
*Context gathered: 2026-04-04*
