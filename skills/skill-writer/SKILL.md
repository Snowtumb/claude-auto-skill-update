---
name: skill-writer
description: Rewrites a Claude Code skill file based on a drift analysis report and latest documentation. Used internally by the updateskill plugin. Do not invoke directly.
version: 1.0.1
---

# Skill Writer

You are rewriting a Claude Code skill file. You have been given the original skill, a drift analysis report, and documentation summaries. Your job is to produce an updated version of the skill that accurately reflects the current state of the codebase.

## Input

You will receive:
- **Original skill**: The full SKILL.md content
- **Drift report**: Output from the skill-analyzer agent (categorized findings with evidence)
- **Documentation summary**: Output from the doc-fetcher agent (current library patterns and breaking changes)

## Rewriting Rules

### 1. Preserve identity

- **Keep the skill's `name`** unchanged
- **Keep the skill's core purpose** — if it was a frontend skill, it stays a frontend skill
- **Keep the fundamental approach** — don't change the skill's philosophy or methodology
- **Keep trigger phrases** in the description that are still valid

### 2. Update frontmatter

```yaml
---
name: [UNCHANGED]
description: [Update ONLY if the skill's scope has expanded to cover new areas]
version: [Bump appropriately — see versioning rules below]
---
```

**Versioning rules:**
- **Patch bump** (1.0.0 → 1.0.1): Small updates — fixing a library version number, correcting a pattern name, minor wording changes
- **Minor bump** (1.0.0 → 1.1.0): Significant updates — adding new sections for newly detected patterns, updating multiple library references, adding coverage for new tools/frameworks
- **Major bump** (1.0.0 → 2.0.0): Fundamental changes — major library migration (e.g., React class → hooks), architecture overhaul, complete rewrite of core sections

### 3. Update body content

For each finding in the drift report:

**Outdated items:**
- Replace the old pattern/library reference with the current one
- Update code examples to match current codebase conventions
- If a library API changed, update the usage examples
- Use documentation summary to ensure accuracy

**Missing items:**
- Add new sections or bullet points for patterns the codebase uses but the skill doesn't cover
- Place them logically within the skill's existing structure — don't just append to the end
- Write them in the same style and voice as the rest of the skill

**Deprecated items:**
- Remove references to patterns/libraries that are no longer used
- Don't leave empty sections — if removing content leaves a section empty, remove the section header too
- If a deprecated pattern was replaced by something else, add the replacement

**Current items:**
- Leave these unchanged. Do not rewrite sections that are already accurate.

### 4. Maintain style

- **Match the original writing voice.** If the original is terse and technical, stay terse. If it's explanatory and verbose, stay verbose.
- **Match the formatting.** If the original uses numbered lists, keep numbering. If it uses bullet points, keep bullets. If it uses code blocks, keep code blocks.
- **Match the structure.** Keep the same section hierarchy and organization. Insert new content where it logically fits within the existing structure.
- **Match the level of detail.** If the original gives brief one-liners, don't write paragraphs. If the original has detailed explanations, match that depth.

### 5. Add update metadata

At the very bottom of the skill, add or update an HTML comment:

```markdown
<!-- Last updated: [YYYY-MM-DD] by AutoSkillUpdate — [1-line summary of changes] -->
```

If there's already an update comment, replace it (don't stack them).

### 6. Quality checks

Before outputting the final skill, verify:

- [ ] All frontmatter fields are valid YAML
- [ ] The `name` field is unchanged
- [ ] The `version` field was bumped appropriately
- [ ] The skill reads coherently from start to finish (no orphaned references, no contradictions)
- [ ] All library versions mentioned match the codebase's actual versions
- [ ] No references to removed/deprecated patterns remain
- [ ] New sections are placed logically within the existing structure
- [ ] Code examples (if any) are syntactically correct and use current APIs
- [ ] Trigger phrases in the description are still accurate
- [ ] The update comment at the bottom accurately summarizes what changed

## Output

Return the complete updated SKILL.md content — frontmatter and body — ready to be written to disk. Do not include any explanation or commentary outside the skill content itself. The output should be exactly what gets written to the file.
