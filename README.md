# 🌀 Recursive Context Compressor (Claude Plugin)

A high-density token management system for **Claude Code**. This plugin replaces standard linear context pruning with **Recursive Staged Compression**, ensuring that architectural decisions and project milestones are never lost to "context drift."

## 🚀 Overview

Standard Claude compaction often results in the loss of nuanced project history once the conversation grows too long. This plugin implements a **Stage-Based Folding** logic:

1.  **Monitor:** Detects when the token window reaches a critical mass (e.g., 80% capacity).
2.  **Compress:** Instead of deleting old messages, it "folds" the previous conversation stage into a high-density Markdown summary.
3.  **Persist:** Saves the compressed state locally in `.claude/context/` to maintain project memory across terminal sessions.
4.  **Inject:** Automatically feeds the "Current State" back into the system prompt via a `SessionStart` hook.

---

## 📂 File Structure

```text
.
├── .claude-plugin/
│   └── plugin.json               # Manifest registering hooks and skills
├── hooks/
│   ├── stage-compressor.sh       # SessionStart hook — injects saved state into new sessions
│   └── session-state-writer.sh   # Stop hook — writes git state to disk at session end
├── skills/
│   └── memory/
│       └── SKILL.md              # Instructions for Claude on how to summarize
└── README.md                     # You are here
```

---

## 🛠 Installation

### Prerequisites
- Claude Code CLI installed (`claude --version` to verify)
- Bash (macOS/Linux) or Git Bash / WSL (Windows)

---

### Option 1: Global Install (Recommended)
Applies to **all your Claude Code projects**.

```bash
# 1. Clone the plugin
git clone https://github.com/sxlamx/sw-recursive-context.git ~/.claude/plugins/recursive-context

# 2. Make the hooks executable
chmod +x ~/.claude/plugins/recursive-context/hooks/stage-compressor.sh
chmod +x ~/.claude/plugins/recursive-context/hooks/session-state-writer.sh

# 3. Install the skill
mkdir -p ~/.claude/skills/recursive-context
cp ~/.claude/plugins/recursive-context/skills/memory/SKILL.md \
   ~/.claude/skills/recursive-context/memory.md
```

**4. Register the hooks** — edit `~/.claude/settings.json`:

> If the file doesn't exist yet, create it with the full content below.

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/recursive-context/hooks/stage-compressor.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/plugins/recursive-context/hooks/session-state-writer.sh"
          }
        ]
      }
    ]
  }
}
```

> If `settings.json` already has a `hooks` key, merge both the `SessionStart` and `Stop` arrays — don't overwrite.

> **Project scoping:** `session-state-writer.sh` includes a guard at the top that exits early unless a specific file exists (by default `mip/backend/main.py`). Edit this guard to match a file in your own project so the hook only runs where you intend it.

---

### Option 1b: Global Install (Windows — Git Bash or WSL)

```bash
# 1. Clone the plugin
git clone https://github.com/sxlamx/sw-recursive-context.git "$APPDATA/Claude/plugins/recursive-context"
# Or for WSL: same as macOS/Linux instructions above (use ~/.claude/plugins/...)

# 2. Make the hook executable
chmod +x "$APPDATA/Claude/plugins/recursive-context/hooks/stage-compressor.sh"

# 3. Install the skill
mkdir -p "$APPDATA/Claude/skills/recursive-context"
cp "$APPDATA/Claude/plugins/recursive-context/skills/memory/SKILL.md" \
   "$APPDATA/Claude/skills/recursive-context/memory.md"
```

**4. Register the hook** — edit `%APPDATA%\Claude\settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"%APPDATA%/Claude/plugins/recursive-context/hooks/stage-compressor.sh\""
          }
        ]
      }
    ]
  }
}
```

> **Note:** Shell scripts are committed with LF line endings (enforced via `.gitattributes`) so they run correctly in Git Bash and WSL without conversion.

---

### Option 2: Project-Level Install
Applies to **one repo only**. Run from inside your project root:

```bash
# 1. Clone the plugin
git clone https://github.com/sxlamx/sw-recursive-context.git /tmp/recursive-context

# 2. Copy files into project
mkdir -p .claude/plugins/recursive-context/hooks
mkdir -p .claude/skills/recursive-context
cp /tmp/recursive-context/hooks/stage-compressor.sh .claude/plugins/recursive-context/hooks/
cp /tmp/recursive-context/hooks/session-state-writer.sh .claude/plugins/recursive-context/hooks/
cp /tmp/recursive-context/skills/memory/SKILL.md .claude/skills/recursive-context/memory.md
chmod +x .claude/plugins/recursive-context/hooks/stage-compressor.sh
chmod +x .claude/plugins/recursive-context/hooks/session-state-writer.sh

# 3. Cleanup temp clone
rm -rf /tmp/recursive-context
```

**4. Register the hooks** — edit `.claude/settings.json` in your project root:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/plugins/recursive-context/hooks/stage-compressor.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/plugins/recursive-context/hooks/session-state-writer.sh"
          }
        ]
      }
    ]
  }
}
```

> **Project scoping:** `session-state-writer.sh` includes a guard that exits early unless a specific sentinel file exists. Edit line 6 of the script to point to a file unique to your project, so the Stop hook only fires in the right repo.

---

### Verify Install

Start a new Claude Code session and check for the context header:

```
--- RECURSIVE CONTEXT LOADED ---
(empty on first run — populates after first compression)
--------------------------------
```

Or confirm both hook files exist:

```bash
# Global
ls ~/.claude/plugins/recursive-context/hooks/

# Project
ls .claude/plugins/recursive-context/hooks/
```

Both `stage-compressor.sh` and `session-state-writer.sh` should be listed.

---

## ⚙️ How it Works

### Staged Memory vs. Flat Summary
| Method | Description | Data Integrity |
| :--- | :--- | :--- |
| **Default** | Truncates history or creates a one-time summary. | High risk of "forgetting" early logic. |
| **Recursive** | Merges current events into a persistent "State Manifest." | Maintains a continuous reasoning chain. |

### Two-Hook Pipeline

The plugin uses a **Stop → SessionStart** hook pair to persist and restore session state automatically.

**`session-state-writer.sh` (Stop hook)** — runs when Claude ends a session:
- Captures current branch, last 15 commits, unstaged file list, and diff stat for the last 3 commits
- Writes the snapshot to `.claude/context/current_state.md`
- Backs up the previous snapshot to `.claude/context/previous_stage.md` before overwriting
- Includes a project scope guard (line 6) — exits early if the sentinel file is absent, so it only fires in the intended repo

**`stage-compressor.sh` (SessionStart hook)** — runs when Claude starts a new session:
- Checks for `.claude/context/current_state.md`
- If found, injects the content as a "Prior Knowledge" block before the first user message
- Ensures Claude is always warmed up with the latest branch and change history

---

## 📝 Usage

Once installed, Claude will automatically manage the context. However, you can manually trigger a "folding" event or check the status:

*   **Check Context State:** `cat .claude/context/current_state.md`
*   **Force a Sync:** Tell Claude: *"Update the context snapshot and fold the current stage."*

### Optimization Tip
Add the following line to your `CLAUDE.md` to ensure maximum efficiency:
> "Prefer the `recursive-context:memory` skill over default compaction. Prioritize preserving architectural intent and API schemas in the `current_state.md`."

---

## Advanced Features (v1.1.0)

### Compression Rules
The skill uses a **Discard/Transform/Preserve** framework when compressing conversation stages:
- **Discard:** Politeness filler, syntax error noise, repeated tool outputs, dead-end approaches
- **Transform:** Long file reads condensed to descriptions, large search results summarized, multi-turn debugging loops collapsed
- **Preserve:** Verbatim final solutions, architectural "Why" statements, exact error messages and fixes, API schemas, file-change summaries

This prevents the "context drift" where summaries become increasingly vague across stages.

### Anchor Pinning
Wrap critical information in `<anchor>...</anchor>` tags to protect it from compression:

```
<anchor>
DATABASE_URL=postgresql://host:5432/dbname
JWT_SECRET=algorithm-key-here
</anchor>
```

Anything inside `<anchor>` tags is copied verbatim into the next stage summary. Ideal for connection strings, regex patterns, schema definitions, and exact commands.

### Micro-Snapshotting
After every **2 successful tool actions** (writes, passing tests, commits), the skill triggers an automatic stage fold if meaningful state has changed. This limits data loss to at most 2 actions in the event of a crash or rate limit.

### CLAUDE.md Handshake
The plugin saves a pre-compression snapshot to `.claude/context/previous_stage.md` before each compression cycle. When Claude realizes it has lost context on a specific file or decision, it actively reads this file to recover the high-fidelity version — turning passive storage into active retrieval.

---

## ⚠️ Requirements
*   **Claude Code CLI** (v2.0.0 or higher recommended).
*   **Bash/Zsh** environment (for the hook scripts).
*   Storage access within the `.claude/` directory of your project.

---


*Keep your context tight and your logic sharper.*