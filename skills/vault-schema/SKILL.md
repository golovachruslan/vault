---
name: vault-schema
description: "Vault folder structure, PARA routing rules, frontmatter conventions, and naming standards. Use when creating, moving, or organizing notes in this vault."
user-invocable: false
---

# Vault Schema

Reference knowledge for vault structure, naming, frontmatter, and routing rules.

## PARA Folder Structure

| Folder | Purpose | Contents |
|--------|---------|----------|
| `00 Inbox/` | Unsorted captures | Quick notes, items awaiting processing and routing |
| `01 Projects/` | Active projects | Each project is a subfolder with category subfolders: `architecture/`, `requirements/`, `decisions/`, `notes/` |
| `02 Areas/` | Ongoing responsibilities | Areas of life or work that are maintained indefinitely (health, finance, career) |
| `03 Resources/` | Reference material | Bookmarks, learning notes, how-to guides, external references |
| `04 Archive/` | Completed/inactive items | Finished projects and paused areas -- moved here to keep active folders clean |
| `10 MOCs/` | Maps of Content | Index notes that curate links to related notes across folders |
| `20 Templates/` | Note templates | Reusable templates for creating new notes of each type |
| `30 Attachments/` | Non-markdown files | Images, PDFs, diagrams, and other binary assets |
| `40 Daily Notes/` | Daily journal | One note per day for journal entries, daily logs, standup notes |

## Naming Conventions

- **Filenames**: Use Title Case with spaces for note files (e.g., `Project Dashboard.md`, `Meeting Notes.md`)
- **Folder names**: Use numbered prefixes for PARA folders (e.g., `00 Inbox/`, `01 Projects/`)
- **Project subfolders**: Use lowercase kebab-case (e.g., `architecture/`, `requirements/`, `decisions/`, `notes/`)
- **Template files**: Use Title Case matching the note type (e.g., `Project Dashboard.md`, `Task List.md`)
- **Daily notes**: Use `YYYY-MM-DD.md` format (e.g., `2026-04-05.md`)

## Frontmatter Fields by Note Type

### Project Dashboard
```yaml
type: project
status: active | paused | completed | archived
area: "[[Area Name]]"
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
```

### Task List
```yaml
type: task-list
project: "[[Project Name]]"
tags: []
created: YYYY-MM-DD
updated: YYYY-MM-DD
```

### Inbox Note
```yaml
type: inbox
tags: []
created: YYYY-MM-DD
```

### Resource
```yaml
type: resource
tags: []
created: YYYY-MM-DD
source: ""
```

### Area
```yaml
type: area
tags: []
created: YYYY-MM-DD
```

### Daily Note
```yaml
type: daily
tags: []
created: YYYY-MM-DD
```

## Routing Rules

- **New captures** default to `00 Inbox/` unless confidently routable to a specific project or area
- **Project-related notes** go under `01 Projects/<project-name>/` in the appropriate category subfolder
- **Area notes** go under `02 Areas/`
- **Reference material** goes under `03 Resources/`
- **Completed projects** move to `04 Archive/` (entire project folder moves)
- **Index notes** that curate links across topics go in `10 MOCs/`
- **Binary attachments** go in `30 Attachments/` and are linked from their parent note
- When in doubt about destination, place in `00 Inbox/` -- the user will route it during organize
