#!/bin/bash
CONTEXT_DIR=".claude/context"
mkdir -p "$CONTEXT_DIR"

# 1. Capture the 'before' state
if [ -f "$CONTEXT_DIR/current_state.md" ]; then
    cp "$CONTEXT_DIR/current_state.md" "$CONTEXT_DIR/previous_stage.md"
fi

# 2. Re-inject the persistent summary into the stream
# Anything written to stdout in a SessionStart hook is added to Claude's context
if [ -f "$CONTEXT_DIR/current_state.md" ]; then
    echo "--- RECURSIVE CONTEXT LOADED ---"
    cat "$CONTEXT_DIR/current_state.md"
    echo "--------------------------------"
fi

exit 0
