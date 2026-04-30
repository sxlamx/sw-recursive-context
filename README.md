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
│   └── plugin.json          # Manifest registering hooks and skills
├── hooks/
│   └── stage-compressor.sh  # Script that manages the .md state files
├── skills/
│   └── memory/
│       └── SKILL.md         # Instructions for Claude on how to summarize
└── README.md                # You are here
```

---

## 🛠 Installation

### 1. Global Installation (Recommended)
To use this logic across all your projects:
```bash
claude --plugin-dir ~/.claude/plugins/recursive-context
```

### 2. Project-Level Installation
To use this specifically for one repository:
1. Copy the plugin folder into your repo: `cp -r recursive-context/ <your-repo>/.claude/plugins/`
2. Update your `.claude/settings.json` to include the plugin path.

---

## ⚙️ How it Works

### Staged Memory vs. Flat Summary
| Method | Description | Data Integrity |
| :--- | :--- | :--- |
| **Default** | Truncates history or creates a one-time summary. | High risk of "forgetting" early logic. |
| **Recursive** | Merges current events into a persistent "State Manifest." | Maintains a continuous reasoning chain. |

### The "Janitor" Hook
The plugin utilizes the `SessionStart` hook. Every time you start a new `claude` instance or a compaction event is triggered, the script:
*   Checks for `.claude/context/current_state.md`.
*   If found, it injects the content as a "Prior Knowledge" block before the first user message.
*   This ensures Claude is always "warmed up" with the latest project status.

---

## 📝 Usage

Once installed, Claude will automatically manage the context. However, you can manually trigger a "folding" event or check the status:

*   **Check Context State:** `cat .claude/context/current_state.md`
*   **Force a Sync:** Tell Claude: *"Update the context snapshot and fold the current stage."*

### Optimization Tip
Add the following line to your `CLAUDE.md` to ensure maximum efficiency:
> "Prefer the `recursive-context:memory` skill over default compaction. Prioritize preserving architectural intent and API schemas in the `current_state.md`."

---

## ⚠️ Requirements
*   **Claude Code CLI** (v2.0.0 or higher recommended).
*   **Bash/Zsh** environment (for the hook scripts).
*   Storage access within the `.claude/` directory of your project.

---


*Keep your context tight and your logic sharper.*