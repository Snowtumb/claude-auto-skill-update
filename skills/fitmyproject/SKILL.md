---
name: fitmyproject
description: Adapt any third-party skill to your specific project. Use when the user says "fit my project", "fitmyproject", "customize skill", "adapt skill", "make skill project-specific", or "/fitmyproject". Accepts an installed plugin skill name, file path, or GitHub URL.
version: 1.0.2
---

# FitMyProject

Takes a third-party Claude Code skill and rewrites it to be fully specific to your project — injecting your conventions, architecture, file paths, dependency versions, and latest documentation.

## Step 1: Parse Input

Parse the user's input to determine the source skill:

| Input | Source Type | Behavior |
|-------|------------|----------|
| `/fitmyproject` (no args) | Interactive | Ask the user what skill to adapt |
| `/fitmyproject <name>` | Plugin skill | Search installed plugin skills by name |
| `/fitmyproject <file-path>` | Local file | Read the skill file directly |
| `/fitmyproject <github-url>` | GitHub URL | Fetch the raw markdown from GitHub |

**Detection heuristics for source type:**
- If the argument starts with `/`, `./`, `~`, or contains path separators and ends with `.md` → **file path**
- If the argument starts with `http://` or `https://` and contains `github.com` → **GitHub URL**
- Otherwise → **installed plugin skill name**

If no arguments are provided, ask:
```
What skill would you like to adapt for this project?

You can provide:
- An installed plugin skill name (e.g., "react", "swiftui-modern")
- A file path to a SKILL.md file
- A GitHub URL to a skill file
```

## Step 2: Resolve Source Skill

Depending on the source type:

### Installed plugin skill

1. Resolve the home directory using Bash (`echo $HOME`) — `~` does not expand in Glob
2. Search for plugin skills in standard locations:
   - `$HOME/.claude/plugins/*/skills/**/*.md`
   - `$HOME/.claude/plugins/cache/*/skills/**/*.md`
   - `.claude/plugins/*/skills/**/*.md` (project-level)
3. For each found file, read its frontmatter to extract `name` and `description`
4. Match the user's input against found skill names (case-insensitive, partial match allowed)
5. If multiple matches, list them and ask the user to pick one
6. If no matches, tell the user and list available plugin skills

### Local file

1. Resolve `~` to absolute path if needed
2. Read the file using the Read tool
3. If file not found, report error and stop

### GitHub URL

1. Convert the URL to raw format:
   - `github.com/user/repo/blob/branch/path` → `raw.githubusercontent.com/user/repo/branch/path`
2. Fetch the raw content using the WebFetch tool
3. If fetch fails, suggest the user download it manually and provide a local file path

### After resolution

Parse the source skill's frontmatter (`name`, `description`, `version`) and store the full content. Present what was found:

```
Source skill: [name] (v[version])
Source: [plugin / file path / GitHub URL]
Description: [description]
```

## Step 3: Analyze Source Skill

Analyze the source skill's body content to extract:

1. **Libraries/frameworks referenced** — library names, import statements, package references
2. **File patterns** — glob patterns, directory references, file extensions mentioned
3. **Coding patterns** — specific APIs, functions, hooks, patterns the skill covers
4. **Domain classification** — infer the skill's domain: frontend, backend, cloud-functions, testing, devops, etc.

Present the analysis:
```
Domain: [inferred domain]
Libraries detected: [list]
File patterns: [list of relevant globs]
```

## Step 4: Dispatch Agents in Parallel

Launch both agents simultaneously using the Agent tool. No scope confirmation needed — always deep scan.

**Agent 1 — project-scanner:**
- Use the Agent tool with `subagent_type: "project-scanner"`
- Pass: source skill content, domain classification, file patterns, list of detected libraries
- Task: Deep-scan the project and extract its complete identity

**Agent 2 — doc-fetcher (reused):**
- Use the Agent tool with `subagent_type: "doc-fetcher"`
- Pass: list of libraries detected in the source skill, with versions from the source skill AND from the project's actual dependencies (if known from CLAUDE.md or package.json already read)
- Task: Fetch latest documentation for all detected libraries

Both agents run concurrently. Wait for both to complete before proceeding.

## Step 5: Merge Results & Present

Combine the outputs from both agents:

1. Take the project-scanner's project identity report (conventions, architecture, paths, patterns, dependencies)
2. Enrich with doc-fetcher's documentation findings:
   - For each library the source skill mentions: add current best practices and version-specific changes
   - If project uses a different version than the source skill assumes: note the differences
   - If project uses alternative libraries: note the substitutions with documentation for the alternatives
3. Produce a merged **Project Profile** document

Present a summary to the user:

```
# Adaptation Plan: [source skill name] -> [project name]

## Compatibility
- [X] patterns match this project
- [X] patterns will be rewritten for project conventions
- [X] patterns will be added (project uses but source skill doesn't cover)
- [X] patterns will be removed (source skill covers but project doesn't use)

## Key Adaptations
- [List of major changes the rewrite will make]
  - e.g., "Tailwind CSS instead of styled-components"
  - e.g., "Vitest instead of Jest"
  - e.g., "File paths updated to match app/ directory structure"
  - e.g., "Added Zustand state management patterns"
```

## Step 6: Get Confirmation + Save Location

Ask the user to confirm and choose where to save:

```
Ready to adapt "[source skill name]" for this project.

Where should the adapted skill be saved?
  1. Project skills: .claude/skills/[name].md (recommended — scoped to this project)
  2. User skills: ~/.claude/skills/[name].md (available in all your projects)
  3. Custom path

Choose (1/2/3), or "cancel" to abort:
```

Store the user's save location choice.

If the user cancels:
```
Adaptation cancelled. No files were created.
```

## Step 7: Invoke Project Skill Writer

Invoke the `project-skill-writer` skill using the Skill tool to load its rewriting instructions, then follow them to produce the project-specific SKILL.md.

Pass to the project-skill-writer:
- **Source skill content** (the full SKILL.md as resolved in Step 2)
- **Project profile** (the merged report from Step 5)
- **Documentation summaries** (the doc-fetcher output from Step 4)

The project-skill-writer will return the complete project-specific SKILL.md content.

## Step 8: Preview & Write

1. **Display a preview** of the adapted skill. Highlight the major adaptations — show the key sections that changed, new sections added, and sections removed.

2. **Write the file** to the user's chosen save location using the Write tool.
   - If the target directory does not exist, create it first
   - If a file already exists at the target path, warn the user and ask whether to overwrite

3. **Confirm success:**
```
Created [adapted skill name] (v1.0.0)
  Source: [original skill name] (v[version]) from [source]
  Saved to: [file path]
  Adaptations: [brief summary — e.g., "12 patterns rewritten, 3 added, 2 removed"]

The skill will activate when: [trigger description from the new skill's description field]
```

## Error Handling

- **Source skill not found (plugin):** "Could not find a plugin skill matching '[name]'. Available plugin skills: [list]"
- **Source skill not found (file):** "Could not read [path]. Check the file path and permissions."
- **GitHub fetch failed:** "Could not fetch skill from [URL]. Check that the URL is correct and accessible, or download the file manually and provide a local path."
- **No Context7 available:** "Context7 MCP tools not available — skipping documentation fetch. Adaptation will be based on project scanning only."
- **Agent failure:** If either agent fails, report what succeeded and what failed. The adaptation can still proceed with partial information (e.g., project scan without doc updates, or vice versa).
- **Target directory doesn't exist:** Create it automatically (`.claude/skills/` is a standard location).
- **Target file already exists:** "A file already exists at [path]. Overwrite? (yes/no)"
