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

### Compression Rules

When summarizing conversation turns for stage folding, apply these heuristics to prevent context drift:

**Discard** (remove entirely):
- Politeness filler: "Thank you", "I will try that", "Looking good", "Makes sense"
- Intermediate syntax errors and the tool-output stutters around fixing them
- Repeated tool outputs showing the same file content multiple times
- False starts and dead-end approaches that were fully reverted

**Transform** (condense aggressively):
- Long file-read outputs → `File [X] read: contains logic for [Y]`
- Large search results → `[N] matches found in [files]`
- Multi-turn debugging loops → `Debugged [issue]: root cause was [X], fixed by [Y]`
- Test run output → keep only the final pass/fail counts and failure details

**Preserve** (keep verbatim):
- Code snippets explicitly marked as "final solution" or "working version"
- Architectural "Why" statements explaining rationale behind a decision
- Specific error messages and their exact resolutions (error text → fix)
- API schemas, type definitions, and function signatures that represent contracts
- File paths with corresponding change descriptions: `src/auth/login.ts — added JWT refresh logic`

**Format fidelity:** When updating the recursive-context stage files, suspend Caveman formatting. The summary must remain in high-fidelity technical Markdown to ensure the next recursion stage has enough detail to remain accurate.

### Anchor Pinning

Users can protect critical information from compression loss using `<anchor>` tags.

**Rule:** Anything wrapped in `<anchor>...</anchor>` tags in the conversation must be copied **verbatim** into the next stage summary. Do not summarize, paraphrase, or transform these blocks.

**Example usage:**
```
<anchor>
DATABASE_URL=postgresql://host:5432/dbname
JWT_SECRET=algorithm-key-here
</anchor>
```

This is essential for preserving:
- Connection strings and environment configurations
- Regex patterns and complex query syntax
- Schema definitions (GraphQL, SQL DDL, JSON schemas)
- Exact command-line invocations or script templates
- User-provided constraints or requirements that must not drift

When you encounter `<anchor>` blocks during compression, include them in a dedicated `### Anchored Data` subsection within the stage summary.

### Micro-Snapshotting (2-Action Rule)

To prevent losing recent reasoning on unexpected crashes or rate limits:

**Rule:** After every **2 successful tool actions** (file writes, test passes, git commits, or other state-changing operations), pause and ask yourself: *"Has meaningful state changed?"*

If yes, trigger an immediate stage fold update to `.claude/context/current_state.md`. This ensures no more than 2 actions' worth of progress can be lost.

This applies especially during:
- Multi-file refactoring sessions
- Test-driven development cycles (red-green-refactor loops)
- Configuration or infrastructure changes

### CLAUDE.md Handshake (Self-Correction Rule)

The plugin stores the **pre-compression high-fidelity version** of each stage in `.claude/context/previous_stage.md` before overwriting.

**Rule:** If you realize you have lost track of a specific file's state, an earlier architectural decision, or the exact wording of a constraint, **actively read** `.claude/context/previous_stage.md` to recover the uncompressed version.

This turns the plugin from passive storage into active retrieval. If you find yourself thinking "What was that exact error message?" or "Which file had that workaround?", consult `previous_stage.md` before guessing or re-investigating.
