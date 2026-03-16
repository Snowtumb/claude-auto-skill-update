# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A Claude Code plugin (marketplace: `claude-auto-skill-update`, plugin: `auto-skill-update`) that detects drift between a user's Claude Code skills and their codebase, then rewrites skills to match. Pure markdown — no executable code, no dependencies, no build step.

## Architecture

The plugin uses a 4-component pipeline:

1. **`skills/updateskill/SKILL.md`** — Orchestrator. Parses args, locates user skills, dispatches agents in parallel, merges results, presents drift report, gets confirmation, invokes writer.
2. **`agents/skill-analyzer.md`** — Scans the target codebase (CLAUDE.md, devlogs, source files, dependencies) and compares against skill assertions. Outputs categorized drift report.
3. **`agents/doc-fetcher.md`** — Fetches latest library docs via Context7 MCP tools (`resolve-library-id` → `query-docs`). Outputs documentation summary with breaking changes.
4. **`skills/skill-writer/SKILL.md`** — Rewrites the skill file preserving identity, voice, and structure. Called by the orchestrator after drift report is confirmed.

Agents 2 and 3 run in parallel. The orchestrator merges their outputs before invoking the writer.

## Plugin Distribution

This repo is both a plugin AND a marketplace (single-plugin pattern, like `firebase`):
- `.claude-plugin/plugin.json` — plugin manifest
- `.claude-plugin/marketplace.json` — marketplace wrapper with `"source": "./"` pointing to repo root

Both files must have matching `version` fields.

## Version Management

Version appears in 5 files. Use the bump script instead of editing manually:

```bash
./bump.sh           # patch: 1.0.1 → 1.0.2
./bump.sh minor     # minor: 1.0.1 → 1.1.0
./bump.sh major     # major: 1.0.1 → 2.0.0
```

This updates all 5 files, commits, tags (`vX.Y.Z`), and pushes.

## Validation

```bash
claude plugin validate .
```

## Local Testing

```bash
claude --plugin-dir /Volumes/SSD/Projects/AutoSkillUpdate
```

Then in a project with skills: `/updateskill --dry-run`

## Key Constraints

- Skills only scan user-owned files (`.claude/commands/`), never installed plugin skills
- Never writes to a skill file without explicit user confirmation
- `doc-fetcher` depends on Context7 MCP — the orchestrator gracefully degrades if unavailable
- `repository` in plugin.json must be a string (not an object) — the validator rejects objects
