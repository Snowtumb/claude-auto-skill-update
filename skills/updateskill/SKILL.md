---
name: updateskill
description: Automatically detect and update outdated Claude Code skills. Use when the user says "update skill", "updateskill", "refresh skill", "skill is outdated", "sync skills", or "/updateskill". Supports targeted mode (/updateskill front-end), interactive mode (/updateskill), batch mode (/updateskill --all), and dry-run mode (/updateskill --dry-run).
version: 1.0.0
---

# AutoSkillUpdate

Detects drift between Claude Code skills and the current codebase, then rewrites skills to match.

## Step 1: Parse Arguments

Parse the user's input to determine the mode:

| Input | Mode | Behavior |
|-------|------|----------|
| `/updateskill` (no args) | Interactive | Scan all skills, list them, ask which to update |
| `/updateskill <skill-name>` | Targeted | Go directly to that skill |
| `/updateskill --all` | Batch | Process all skills sequentially |
| `/updateskill --dry-run` | Dry-run | Report only, never write changes |
| `/updateskill <name> --dry-run` | Targeted dry-run | Analyze one skill, report only |
| `/updateskill --all --dry-run` | Batch dry-run | Analyze all skills, report only |

If arguments are ambiguous, ask the user to clarify.

## Step 2: Locate Skill Files

Search for the user's own skill files only. Do NOT scan installed plugin skills — those are maintained by plugin authors and can number in the dozens. Note: `~` does not expand in Glob — resolve the home directory first using Bash (`echo $HOME`) and use the absolute path.

1. **Project-level skills:** Use Glob for `.claude/commands/**/*.md` in the current working directory
2. **User-level skills:** Use Glob for `$HOME/.claude/commands/**/*.md` (resolve `$HOME` to absolute path first)

For each found skill file:
- Read its frontmatter to extract `name` and `description`
- Store the file path for later access

**For targeted mode:** Match the user's `<skill-name>` against found skill names (case-insensitive, partial match allowed). If multiple matches, list them and ask the user to pick one. If no matches, tell the user and list available skills.

**For interactive mode:** Present a numbered list of all found skills:
```
Found X skills:
1. [name] — [description] ([file path])
2. [name] — [description] ([file path])
...

Which skill(s) would you like to update? (Enter numbers, "all", or "q" to quit)
```

**For batch mode:** Collect all found skills and process them sequentially.

## Step 3: Read & Analyze the Target Skill

For each skill to be updated:

1. **Read the full SKILL.md file** using the Read tool
2. **Parse frontmatter:** Extract `name`, `description`, `version`
3. **Analyze body content** to extract:
   - **Libraries/frameworks referenced** — look for library names, import statements, package references
   - **File patterns** — look for glob patterns, directory references, file extensions mentioned
   - **Coding patterns** — look for specific APIs, functions, hooks, patterns the skill enforces
   - **Domain classification** — infer the skill's domain: frontend, backend, cloud-functions, testing, devops, etc.

Present the analysis:
```
Skill: [name] (v[version])
Domain: [inferred domain]
Libraries detected: [list]
File patterns: [list of globs]
```

## Step 4: Confirm Scan Scope

Ask the user to confirm the scan parameters:

```
Scan scope:
- Domain: [domain]
- File patterns: [patterns]
- Libraries to check docs for: [list]

Scan mode:
  1. Full scan — reads all matching files (thorough, more tokens)
  2. Smart sampling — checks key files + greps for patterns (faster, fewer tokens)

Choose scan mode (1/2), or adjust the scope:
```

Let the user:
- Change the file patterns
- Add or remove libraries from the doc-fetch list
- Choose the scan mode
- Skip the confirmation entirely with "go" or "looks good"

## Step 5: Dispatch Agents in Parallel

Launch both agents simultaneously using the Agent tool:

**Agent 1 — skill-analyzer:**
- Pass: skill content, domain, file patterns, scan mode
- Use the Agent tool with `subagent_type: "skill-analyzer"`
- Task: Analyze the codebase and produce a drift report

**Agent 2 — doc-fetcher:**
- Pass: list of libraries with their detected versions
- Use the Agent tool with `subagent_type: "doc-fetcher"`
- Task: Fetch latest documentation for all detected libraries

Both agents run concurrently. Wait for both to complete before proceeding.

## Step 6: Merge Results & Generate Drift Report

Combine the outputs from both agents:

1. Take the skill-analyzer's categorized findings (Current, Outdated, Missing, Deprecated)
2. Enrich with doc-fetcher's documentation findings:
   - For outdated items: add documentation context about what changed and why
   - For missing items: add documentation about best practices for newly detected libraries
   - For deprecated items: confirm deprecation status from official docs
3. If the doc-fetcher found breaking changes between the skill's version references and current versions, add these as additional outdated items

Produce the merged drift report.

## Step 7: Present Report to User

Display the drift report clearly:

```
# Drift Report: [skill name]

## Summary
- ✓ [X] items current (no changes needed)
- ✗ [X] items outdated
- ✗ [X] items missing from skill
- ⚠ [X] items deprecated

## Outdated
### [Item]
- Skill says: [old pattern]
- Codebase uses: [new pattern]
- Evidence: [file:line]
- Docs confirm: [documentation context]

## Missing
### [Item]
- What: [pattern not covered]
- Where: [file:line]
- Why add: [reason]

## Deprecated
### [Item]
- Skill references: [old thing]
- Status: [removed/replaced]
- Evidence: [proof]
```

If there are no outdated, missing, or deprecated items:
```
✓ Skill "[name]" is up to date! No changes needed.
```
Stop here.

**If `--dry-run` mode:** Display the report and stop. Do not proceed to writing changes.

## Step 8: Get Confirmation

Ask the user to confirm before making changes:

```
Ready to update [skill name] (v[old] → v[new]).

Changes:
- [X] patterns updated
- [X] sections added
- [X] references removed

Proceed with update? (yes/no)
```

If the user declines, exit gracefully:
```
Update cancelled. No changes were made.
```

## Step 9: Invoke Skill Writer

Invoke the `skill-writer` skill using the Skill tool to load its rewriting instructions, then follow them to produce the updated SKILL.md.

Pass to the skill-writer:
- **Original skill content** (the full SKILL.md as read in Step 3)
- **Drift report** (the merged report from Step 6)
- **Documentation summaries** (the doc-fetcher output from Step 5)

The skill-writer will return the complete updated SKILL.md content.

## Step 10: Show Diff & Write

1. **Display a clear diff** showing what changed between the original and updated skill. Use a format that highlights additions, removals, and modifications.

2. **Write the updated file** to the same path as the original SKILL.md using the Edit or Write tool.

3. **Confirm success:**
```
✓ Updated [skill name] (v[old] → v[new])
  File: [file path]
  Changes: [brief summary]
```

## Batch Mode

When processing multiple skills (`--all`):

1. Run Steps 3-10 for each skill sequentially
2. After all skills are processed, show a combined summary:

```
# Batch Update Summary

| Skill | Status | Changes |
|-------|--------|---------|
| [name] | Updated (v1.0.0 → v1.1.0) | 3 patterns updated, 1 section added |
| [name] | Up to date | No changes needed |
| [name] | Skipped (user declined) | — |
```

## Error Handling

- **No skills found:** "No Claude Code skills found in any standard location. Skills are typically stored in `.claude/commands/` or in installed plugins."
- **Skill file unreadable:** "Could not read [path]. Check file permissions."
- **No Context7 available:** "Context7 MCP tools not available — skipping documentation fetch. Analysis will be based on codebase scanning only."
- **Agent failure:** If either agent fails, report what succeeded and what failed. The update can still proceed with partial information (e.g., codebase analysis without doc updates, or vice versa).
