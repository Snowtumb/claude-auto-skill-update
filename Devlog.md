# Development Log

## 2026-03-20 — /fitmyproject Feature (Skill Adaptation)

### What
Added `/fitmyproject` command — takes any third-party skill (marketplace plugin, file path, or GitHub URL) and rewrites it to be fully specific to your project. Complements `/updateskill` (which keeps existing skills current) by making someone else's skill yours from the start.

### New Components
- `skills/fitmyproject/SKILL.md` — Orchestrator with 8-step flow: parse input, resolve source, analyze, dispatch parallel agents, merge, confirm + save location, invoke writer, preview + write
- `agents/project-scanner.md` — Deep-scans the project to extract identity (conventions, architecture, file paths, naming patterns, dependency versions). Different from skill-analyzer: extracts a positive project profile, not a drift comparison.
- `skills/project-skill-writer/SKILL.md` — Full rewrite engine. Unlike skill-writer (which preserves identity), this creates a new skill identity: renames for the project, sets v1.0.0, replaces all generic content with project-specific assertions.

### Design Decisions
- Mirror the existing 4-component pipeline pattern (orchestrator + 2 parallel agents + writer)
- Reuse doc-fetcher agent as-is — both pipelines benefit from latest library docs
- Separate project-scanner from skill-analyzer because the jobs are fundamentally different (extract identity vs detect drift)
- Separate project-skill-writer from skill-writer because the philosophies are opposite (create new identity vs preserve identity)
- Always deep scan — no scope confirmation. The whole point is maximum project specificity.
- Adapted skills start at v1.0.0 regardless of source version
- Ask for save location each time (no default) since the adapted skill is new
- Three source types: installed plugin name, file path, GitHub URL (with blob-to-raw conversion)

### Files Modified
- `bump.sh` — Now updates 7 version files (was 5)
- `plugin.json` / `marketplace.json` — Updated descriptions and keywords
- `CLAUDE.md` — Architecture section expanded for both pipelines
- `README.md` — Added /fitmyproject features, pipeline diagram, command reference, updated components table and project structure

---

## 2026-03-16 — Project Inception & v1.0.0 Design

### What
Created the AutoSkillUpdate plugin — an open-source Claude Code plugin that automatically detects and updates outdated skills.

### Design Decisions
- Multi-skill + multi-agent architecture (updateskill orchestrator, skill-analyzer agent, doc-fetcher agent, skill-writer skill)
- Always confirm before writing changes (safety first)
- Context7 integration for fetching latest library documentation
- Support for targeted, interactive, batch, and dry-run modes
- Full scan as default with smart sampling option for large codebases

### Architecture
- `updateskill` skill: User-facing entry point, orchestrates the workflow
- `skill-analyzer` agent: Scans codebase for drift (CLAUDE.md, devlogs, source files)
- `doc-fetcher` agent: Fetches latest docs via Context7 (runs parallel with analyzer)
- `skill-writer` skill: Rewrites skill files preserving identity and style
