---
name: init
description: Initialize or adapt an Obsidian vault with PARA structure, templates, and agent context files
disable-model-invocation: true
allowed-tools: Read Write Bash Glob Grep
argument-hint: "[--dry-run]"
---

# /vault:init

Initialize or adapt an Obsidian vault with PARA folder structure, core templates, and machine-readable agent context files.

## How This Works

You are running inside the user's Obsidian vault directory (CWD). Your job is to detect the current vault state, build a complete setup proposal, present it to the user for approval, and execute only after they confirm. Never make changes without explicit approval.

## Step 1: Detect Vault State

Scan the current working directory for vault markers:

1. Check for `.obsidian/` directory (Obsidian vault marker)
2. Check for existing PARA folders -- both numbered (`00 Inbox/`, `01 Projects/`, etc.) and unnumbered (`inbox/`, `projects/`, etc.)
3. Check for `organization.md` or `vault:config.md` (existing conventions file)
4. Check for any `.md` files beyond just `README.md`

Classify the vault:

- **Greenfield**: No `.obsidian/` directory AND no `.md` files (or only `README.md`). This is a brand new vault.
- **Brownfield**: Has `.obsidian/` directory OR has existing `.md` content. This is an existing vault that needs adaptation.

Report your findings to the user before proceeding.

## Step 2: Build Proposal

### Greenfield Vault

Propose the full PARA structure:

| Folder | Purpose |
|--------|---------|
| `00 Inbox/` | Unsorted captures, quick notes, items awaiting processing |
| `01 Projects/` | Active projects with category subfolders (architecture/, requirements/, decisions/, notes/) |
| `02 Areas/` | Ongoing areas of responsibility (health, finance, career, etc.) |
| `03 Resources/` | Reference material, bookmarks, learning notes |
| `04 Archive/` | Completed projects and inactive areas |
| `10 MOCs/` | Maps of Content -- index notes that link related topics |
| `20 Templates/` | Note templates (Project Dashboard, Task List, Inbox Note) |
| `30 Attachments/` | Images, PDFs, and other non-markdown files |
| `40 Daily Notes/` | Daily journal entries |

Also propose:
- Install 3 core templates in `20 Templates/`: `Project Dashboard.md`, `Task List.md`, `Inbox Note.md`
- Generate `vault:config.md` at vault root with all four convention sections
- Generate `CLAUDE.md` at vault root with pointer to `vault:config.md`
- Generate `AGENTS.md` at vault root with pointer to `vault:config.md`
- Generate `Home.md` at vault root as the vault landing page

### Brownfield Vault

For an existing vault:

1. **Identify existing vs missing PARA folders** -- check for both numbered and unnumbered variants
2. **Check existing templates** in `20 Templates/` or `templates/` -- never overwrite existing templates
3. **Check for `organization.md`** -- if found, propose merging its content into `vault:config.md` and keeping `organization.md` as a read-only pointer
4. **Check for existing `CLAUDE.md`** -- if found, update (do not replace) with vault context section
5. **Suggest per-file migrations** -- for each file that could benefit from being in a PARA folder, suggest the move with explicit approval required

Build a summary with these categories:
- **Folders to CREATE**: Missing PARA folders
- **Folders that EXIST**: Already present (no action needed)
- **Templates to INSTALL**: New templates only (never overwrite existing)
- **Config to GENERATE**: vault:config.md (new or merge with organization.md)
- **Migration suggestions**: Optional file moves (each requires separate approval)

## Step 3: Present Proposal

Show the complete proposal to the user. Clearly separate:
- Actions that WILL be taken (folder creation, new template installation, config generation)
- Actions that are SUGGESTED (file migrations, template upgrades)

Ask: **"Approve this plan? (yes / yes with changes / no)"**

Do not proceed until the user responds.

## Step 4: Execute

Only after the user approves:

1. **Create missing PARA folders** using `mkdir -p` for each folder
2. **Install templates** from `${CLAUDE_SKILL_DIR}/templates/` -- read each bundled template and write to the vault's `20 Templates/` folder. Never overwrite an existing template file.
3. **Generate vault:config.md** at vault root with these four sections:
   - **Folder Conventions**: PARA structure with numbered prefixes, folder purposes, routing rules
   - **Frontmatter Spec**: Required fields per note type (project, task-list, inbox, resource, area, daily)
   - **Linking Rules**: How notes link to each other (projects link to areas, areas list projects, resources stay passive)
   - **Agent Instructions**: Rules for any AI agent working in this vault (read this file first, use correct folders, include frontmatter, use templates)
   - Include `generated: YYYY-MM-DD` in the frontmatter (use today's date)
4. **Generate/update CLAUDE.md** with a vault context section that points to `vault:config.md`
5. **Generate AGENTS.md** with a vault context section that points to `vault:config.md`
6. **Execute only user-approved brownfield migrations** -- skip any the user declined

## Step 5: Verify

After execution, report:
- Folders created (list each)
- Templates installed (list each)
- Config files generated (list each)

Verify:
- `vault:config.md` contains all four sections (Folder Conventions, Frontmatter Spec, Linking Rules, Agent Instructions)
- `CLAUDE.md` references `vault:config.md`
- `AGENTS.md` references `vault:config.md`

## --dry-run Flag

If `$ARGUMENTS` contains `--dry-run`, execute only Steps 1-3 (detect, build proposal, present). Do NOT execute Step 4. This lets the user preview the plan without making changes.

## Important Rules

- NEVER move or rename a file without explicit user approval for THAT specific file
- NEVER overwrite an existing template -- install new templates alongside existing ones
- ALWAYS use numbered PARA prefixes (00, 01, 02, 03, 04, 10, 20, 30, 40)
- ALWAYS include `generated: YYYY-MM-DD` in `vault:config.md` frontmatter (use today's date)
- `vault:config.md` is the CANONICAL conventions source -- all other context files point to it
- When in doubt about a file's destination, default to `00 Inbox/`
