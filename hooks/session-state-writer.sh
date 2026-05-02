#!/bin/bash
# Stop hook — writes .claude/context/current_state.md from git state.
# Injected into the next session by stage-compressor.sh (SessionStart hook).

# Scope: only act in this project.
if [ ! -f "mip/backend/main.py" ]; then
    exit 0
fi

CONTEXT_DIR=".claude/context"
mkdir -p "$CONTEXT_DIR"
STATE_FILE="$CONTEXT_DIR/current_state.md"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
DATE=$(date '+%Y-%m-%d %H:%M')
RECENT_LOG=$(git log --oneline -15 2>/dev/null || echo "(no commits)")
MODIFIED=$(git status --short 2>/dev/null || echo "(clean)")
DIFF_STAT=$(git diff --stat HEAD~3..HEAD 2>/dev/null | tail -8 || echo "(no diff)")

# Back up previous state
if [ -f "$STATE_FILE" ]; then
    cp "$STATE_FILE" "$CONTEXT_DIR/previous_stage.md"
fi

cat > "$STATE_FILE" <<STATEOF
# Session State — $DATE

## Branch
$BRANCH

## Recent Commits
\`\`\`
$RECENT_LOG
\`\`\`

## Modified Files (unstaged)
\`\`\`
$MODIFIED
\`\`\`

## Recent Changes (last 3 commits)
\`\`\`
$DIFF_STAT
\`\`\`

## Session Notes
<!-- Populated by Claude at session end, or manually -->
STATEOF

echo "[recursive-context] State written → $STATE_FILE" >&2
exit 0
