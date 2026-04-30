---
name: recursive-context:memory
description: Use when you finish a major task, when the context window feels full, or when instructed to compress context. Manages staged recursive context compression by reading, summarizing, merging, and writing compressed context state.
---

# Context Management Skill

Use this skill when you finish a major task or when the context window feels full.

## How to use

### Phase 1: Read current state
Read `.claude/context/current_state.md` to understand what was preserved from previous stages.

### Phase 2: Summarize recent turns
Extract from the current conversation:
- **Architectural decisions** — what was chosen and why
- **Code paths modified** — exact file paths and what changed
- **Bugs discovered and fixes** — root cause and resolution
- **Open questions** — anything not yet resolved

Drop: debugging noise, redundant tool outputs, false starts, dead ends.

### Phase 3: Merge using Stage Folding
Combine the new summary with the existing `current_state.md`:
- If `current_state.md` is empty (first stage): write the new summary directly
- If `current_state.md` exists: prepend a new `## Stage N` section with the new summary above existing stages
- Increment the stage number. The first stage is `## Stage 1`
- Retain architectural decisions and code paths from all prior stages
- Remove contradictory information that has been superseded

### Phase 4: Write back
Write the merged result to `.claude/context/current_state.md`.

**Critical note:** Always preserve the `## Stage N` headers to track recursion levels. This allows Claude to understand how many compression cycles have occurred.
