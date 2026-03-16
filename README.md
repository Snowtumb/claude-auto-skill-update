# AutoSkillUpdate

**Automatically detect and update outdated Claude Code skills.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-green.svg)](.claude-plugin/plugin.json)

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

- **Targeted mode** — Update a specific skill: `/updateskill <skill-name>`
- **Interactive mode** — List all skills and choose: `/updateskill`
- **Batch mode** — Update all skills at once: `/updateskill --all`
- **Dry-run mode** — See the report without making changes: `/updateskill --dry-run`
- **Context7 integration** — Fetches latest library docs for accurate updates
- **Evidence-based** — Every finding includes file paths and line references
- **Safe by default** — Never writes changes without explicit user confirmation

## Installation

```bash
claude plugins add auto-skill-update
```

Or install from a local directory:

```bash
claude plugins add /path/to/auto-skill-update
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

### Components

| Component | Type | Role |
|-----------|------|------|
| `updateskill` | Skill | User-facing entry point. Orchestrates the full workflow. |
| `skill-analyzer` | Agent | Scans the codebase for drift. Reads CLAUDE.md, devlogs, source files, and dependencies. Produces a categorized drift report. |
| `doc-fetcher` | Agent | Fetches latest library documentation via Context7 MCP tools. Finds breaking changes, new patterns, and deprecated APIs. |
| `skill-writer` | Skill | Rewrites the skill file. Preserves identity and style while updating content. |

### Drift Categories

| Category | Meaning |
|----------|---------|
| **Current** | Skill matches the codebase. No change needed. |
| **Outdated** | Skill describes old patterns the codebase has moved past. |
| **Missing** | Codebase uses something the skill doesn't cover. |
| **Deprecated** | Skill references something removed from the codebase. |

## Command Reference

| Command | Description |
|---------|-------------|
| `/updateskill` | Interactive mode — list all skills, choose which to update |
| `/updateskill <name>` | Targeted mode — update a specific skill by name |
| `/updateskill --all` | Batch mode — update all skills sequentially |
| `/updateskill --dry-run` | Dry-run — show drift report without writing changes |
| `/updateskill <name> --dry-run` | Targeted dry-run |
| `/updateskill --all --dry-run` | Batch dry-run |

Flags can combine: `/updateskill --all --dry-run`

## Skill Locations Searched

AutoSkillUpdate searches these locations for skills:

| Location | Description |
|----------|-------------|
| `.claude/commands/**/*.md` | Project-level skills |
| `~/.claude/commands/**/*.md` | User-level skills |
| `~/.claude/plugins/**/skills/**/*.md` | Installed plugin skills |
| `.claude/plugins/**/skills/**/*.md` | Project plugin skills |

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
│   └── plugin.json              # Plugin manifest
├── skills/
│   ├── updateskill/
│   │   └── SKILL.md             # Main orchestrator skill
│   └── skill-writer/
│       └── SKILL.md             # Skill rewriting logic
├── agents/
│   ├── skill-analyzer.md        # Codebase drift detection agent
│   └── doc-fetcher.md           # Documentation fetching agent
├── README.md
├── Devlog.md
└── LICENSE
```

### How to Contribute

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Test the plugin locally
5. Submit a pull request

## License

[MIT](LICENSE) — Ilia Lopata
