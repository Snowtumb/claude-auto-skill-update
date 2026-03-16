#!/bin/bash
# Usage: ./bump.sh [patch|minor|major]
# Bumps version in all project files, commits, tags, and pushes.

set -e

TYPE="${1:-patch}"

# Get current version from plugin.json
CURRENT=$(grep '"version"' .claude-plugin/plugin.json | head -1 | sed 's/[^0-9.]//g')
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT"

case "$TYPE" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  *) echo "Usage: ./bump.sh [patch|minor|major]"; exit 1 ;;
esac

NEW="$MAJOR.$MINOR.$PATCH"
echo "Bumping $CURRENT → $NEW"

# Update all version references
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" .claude-plugin/plugin.json
sed -i '' "s/\"version\": \"$CURRENT\"/\"version\": \"$NEW\"/" .claude-plugin/marketplace.json
sed -i '' "s/version: $CURRENT/version: $NEW/" skills/updateskill/SKILL.md
sed -i '' "s/version: $CURRENT/version: $NEW/" skills/skill-writer/SKILL.md
sed -i '' "s/version-$CURRENT/version-$NEW/" README.md

git add -A
git commit -m "Bump version to $NEW"
git tag "v$NEW"
git push && git push --tags

echo "✔ Released v$NEW"
