# AutoSkillUpdate

**Automatically detect and update outdated Claude Code skills — and adapt third-party skills to your specific project.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.2-green.svg)](.claude-plugin/plugin.json)

---

## The Problem

Claude Code skills are written at a point in time. Codebases evolve — libraries get upgraded, patterns change, conventions shift — but skills don't update themselves.

**Example 1:** You wrote a Cloud Functions skill six months ago that references `firebase-functions` v1 patterns with `functions.https.onCall`. Your codebase has since migrated to v2 with `onCall(options, handler)`. The skill now teaches Claude outdated patterns.

**Example 2:** Your frontend skill says "use `styled-components` for styling" but your team switched to Tailwind CSS three months ago. Every time the skill fires, it pushes Claude toward patterns your codebase no longer uses.

Skills drift silently. You don't notice until Claude generates code based on stale instructions and you spend time debugging the mismatch.

## The Solution

AutoSkillUpdate scans your codebase, compares it against your skills, fetches the latest library documentation, and generates an updated skill — with your approval before any changes are written.

```
/updateskill front-end

Scanning codebase for drift...

# Drift Report: front-end

## Summary
- ✓ 12 items current
- ✗ 3 items outdated
- ✗ 2 items missing from skill
- ⚠ 1 item deprecated

## Outdated
### Styling approach
- Skill says: Use styled-components for all component styling
- Codebase uses: Tailwind CSS utility classes
- Evidence: src/components/*.tsx (47 files use className with Tailwind)

## Missing
### Zustand state management
- What: Zustand stores used across 8 feature modules
- Where: src/stores/*.ts
- Why add: Skill doesn't mention state management approach

Proceed with update? (yes/no)
```

## Features

### Skill Update (`/updateskill`)

- **Targeted mode** — Update a specific skill: `/updateskill <skill-name>`
- **Interactive mode** — List all skills and choose: `/updateskill`
- **Batch mode** — Update all skills at once: `/updateskill --all`
- **Dry-run mode** — See the report without making changes: `/updateskill --dry-run`

### Skill Adaptation (`/fitmyproject`)

- **Adapt any skill** — Works with installed plugin skills, local file paths, or GitHub URLs
- **Deep project scanning** — Extracts conventions, architecture, file paths, naming patterns, dependency versions
- **Fully project-specific output** — No generic advice; every assertion is tailored to your codebase
- **Choose save location** — Save to project skills, user skills, or a custom path

### Shared

- **Context7 integration** — Fetches latest library docs for accurate updates
- **Evidence-based** — Every finding includes file paths and line references
- **Safe by default** — Never writes changes without explicit user confirmation

## Installation

### From GitHub

1. Add the repo as a plugin marketplace:
   ```bash
   claude plugin marketplace add Snowtumb/claude-auto-skill-update
   ```

2. Install the plugin:
   ```bash
   claude plugin install auto-skill-update@claude-auto-skill-update
   ```

3. Restart Claude Code or run `/reload-plugins` in your session.

### From a local directory (for development)

```bash
claude --plugin-dir /path/to/claude-auto-skill-update
```

## Usage

### Update a specific skill

```bash
/updateskill front-end
```

Finds the skill named "front-end", scans the codebase, and generates a drift report. You confirm before any changes are written.

### Interactive mode

```bash
/updateskill
```

Scans all standard skill locations, lists every skill found, and lets you pick which ones to update.

### Update all skills

```bash
/updateskill --all
```

Processes every skill sequentially with a combined summary at the end.

### Dry-run (report only)

```bash
/updateskill --dry-run
/updateskill front-end --dry-run
/updateskill --all --dry-run
```

Generates the drift report but never writes changes. Useful for seeing what's outdated without committing to an update.

### Adapt a third-party skill to your project

```bash
/fitmyproject react
```

Finds the installed "react" skill, deep-scans your project, and rewrites the skill with your conventions, file paths, library versions, and architecture patterns. You choose where to save and confirm before anything is written.

```bash
/fitmyproject ./path/to/SKILL.md
/fitmyproject https://github.com/user/repo/blob/main/skills/some-skill/SKILL.md
```

Also works with local file paths and GitHub URLs.

## How It Works

```
┌─────────────────────────────────────────────────┐
│                  /updateskill                    │
│              (Orchestrator Skill)                │
│                                                  │
│  1. Parse args & locate skill files              │
│  2. Read & analyze target skill                  │
│  3. Confirm scan scope with user                 │
│                                                  │
│  4. Dispatch agents in parallel:                 │
│     ┌─────────────────┐  ┌────────────────────┐  │
│     │ skill-analyzer  │  │   doc-fetcher      │  │
│     │                 │  │                    │  │
│     │ Scans codebase: │  │ Fetches docs via   │  │
│     │ • CLAUDE.md     │  │ Context7:          │  │
│     │ • Devlog.md     │  │ • Best practices   │  │
│     │ • Source files   │  │ • Breaking changes │  │
│     │ • Dependencies  │  │ • New APIs         │  │
│     └────────┬────────┘  └────────┬───────────┘  │
│              │                    │               │
│              └────────┬───────────┘               │
│                       │                           │
│  5. Merge results → Drift report                 │
│  6. Present report → Get confirmation            │
│  7. Invoke skill-writer → Updated SKILL.md       │
│  8. Show diff → Write file                       │
└─────────────────────────────────────────────────┘
```

### `/fitmyproject` Pipeline

```
┌─────────────────────────────────────────────────┐
│                 /fitmyproject                     │
│              (Orchestrator Skill)                │
│                                                  │
│  1. Parse input (plugin name / file / URL)       │
│  2. Resolve & read source skill                  │
│  3. Analyze skill (domain, libraries, patterns)  │
│                                                  │
│  4. Dispatch agents in parallel:                 │
│     ┌─────────────────┐  ┌────────────────────┐  │
│     │ project-scanner │  │   doc-fetcher      │  │
│     │                 │  │   (reused)         │  │
│     │ Deep-scans      │  │                    │  │
│     │ project:        │  │ Fetches docs via   │  │
│     │ • Conventions   │  │ Context7:          │  │
│     │ • Architecture  │  │ • Best practices   │  │
│     │ • File paths    │  │ • Breaking changes │  │
│     │ • Dependencies  │  │ • New APIs         │  │
│     └────────┬────────┘  └────────┬───────────┘  │
│              │                    │               │
│              └────────┬───────────┘               │
│                       │                           │
│  5. Merge → Adaptation plan                      │
│  6. Confirm + choose save location               │
│  7. Invoke project-skill-writer → New SKILL.md   │
│  8. Preview → Write to chosen location           │
└─────────────────────────────────────────────────┘
```

### Components

| Component | Type | Role |
|-----------|------|------|
| `updateskill` | Skill | Orchestrates the drift-detection workflow for `/updateskill`. |
| `skill-analyzer` | Agent | Scans the codebase for drift. Produces a categorized drift report. |
| `doc-fetcher` | Agent | Fetches latest library documentation via Context7 MCP tools. Shared by both pipelines. |
| `skill-writer` | Skill | Rewrites the skill file. Preserves identity and style while updating content. |
| `fitmyproject` | Skill | Orchestrates the skill-adaptation workflow for `/fitmyproject`. |
| `project-scanner` | Agent | Deep-scans the project to extract its identity — conventions, architecture, file paths, patterns. |
| `project-skill-writer` | Skill | Rewrites a third-party skill to be fully project-specific. Creates new identity. |

### Drift Categories

| Category | Meaning |
|----------|---------|
| **Current** | Skill matches the codebase. No change needed. |
| **Outdated** | Skill describes old patterns the codebase has moved past. |
| **Missing** | Codebase uses something the skill doesn't cover. |
| **Deprecated** | Skill references something removed from the codebase. |

## Command Reference

### `/updateskill`

| Command | Description |
|---------|-------------|
| `/updateskill` | Interactive mode — list all skills, choose which to update |
| `/updateskill <name>` | Targeted mode — update a specific skill by name |
| `/updateskill --all` | Batch mode — update all skills sequentially |
| `/updateskill --dry-run` | Dry-run — show drift report without writing changes |
| `/updateskill <name> --dry-run` | Targeted dry-run |
| `/updateskill --all --dry-run` | Batch dry-run |

Flags can combine: `/updateskill --all --dry-run`

### `/fitmyproject`

| Command | Description |
|---------|-------------|
| `/fitmyproject` | Interactive — ask what skill to adapt |
| `/fitmyproject <name>` | Adapt an installed plugin skill by name |
| `/fitmyproject <file-path>` | Adapt a skill from a local `.md` file |
| `/fitmyproject <github-url>` | Adapt a skill from a GitHub URL |

## Skill Locations Searched

AutoSkillUpdate searches your own skill files only — installed plugin skills are maintained by their authors and are not scanned.

| Location | Description |
|----------|-------------|
| `.claude/skills/**/*.md` | Project-level skills |
| `~/.claude/skills/**/*.md` | User-level skills |

## Contributing

Contributions are welcome! This is an open-source project under the MIT license.

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Snowtumb/claude-auto-skill-update.git
   cd claude-auto-skill-update
   ```

2. Install locally as a Claude Code plugin:
   ```bash
   claude plugins add /path/to/auto-skill-update
   ```

3. Test with a project that has skills:
   ```bash
   /updateskill --dry-run
   ```

### Project Structure

```
auto-skill-update/
├── .claude-plugin/
│   ├── plugin.json              # Plugin manifest
│   └── marketplace.json         # Marketplace wrapper
├── skills/
│   ├── updateskill/
│   │   └── SKILL.md             # /updateskill orchestrator
│   ├── skill-writer/
│   │   └── SKILL.md             # Drift-based skill rewriter
│   ├── fitmyproject/
│   │   └── SKILL.md             # /fitmyproject orchestrator
│   └── project-skill-writer/
│       └── SKILL.md             # Project-specific skill rewriter
├── agents/
│   ├── skill-analyzer.md        # Codebase drift detection agent
│   ├── doc-fetcher.md           # Documentation fetching agent (shared)
│   └── project-scanner.md       # Project identity extraction agent
├── README.md
├── Devlog.md
├── bump.sh                      # Version management script
└── LICENSE
```

### How to Contribute

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test the plugin locally
5. Submit a pull request

## License

[MIT](LICENSE) — Snowtumb
