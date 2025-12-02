---
title: "Desktop Notifications for Claude Code: Never Miss a Completed Task"
description: "Configure Claude Code hooks to send desktop notifications via OSC escape sequences - perfect for VSCode Remote SSH setups where notifications from remote EC2 instances reach your local machine"
date: 2025-12-02
lastmod: 2025-12-02
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
codeMaxLines: 100
codeLineNumbers: true
toc: true
categories:
- Development Tools
- AI Coding Assistants
tags:
- Claude Code
- VSCode
- VSCode Remote SSH
- Productivity
- Shell Scripting
- OSC Escape Sequences
keywords:
- claude code notifications
- vscode remote ssh notifications
- osc escape sequences
- claude code hooks
- task completion alerts
- terminal notifications
---

When working with Claude Code on complex tasks, you often switch to other work while waiting for completion. The challenge? Knowing exactly when Claude finishes so you can review the results promptly. This post shows you how to configure desktop notifications that alert you the moment Claude Code completes a task.

<!--more-->

## The Problem

Claude Code can run lengthy operations - refactoring codebases, writing tests, or analyzing large files. During these operations, you might:

- Switch to another VSCode window
- Check emails or documentation
- Work on a different task entirely

Without notifications, you're left constantly checking back, wasting time and breaking focus.

## The Solution: OSC Escape Sequences

Operating System Command (OSC) escape sequences allow terminal applications to communicate with their host environment. Modern terminals like VSCode's integrated terminal, iTerm2, and Windows Terminal support OSC sequences for desktop notifications.

The magic sequence:
```bash
# OSC 777 format (VSCode, rxvt-unicode)
printf '\033]777;notify;Title;Message\007'

# OSC 9 format (iTerm2, Windows Terminal)
printf '\033]9;Message\007'
```

When sent to a terminal that supports it, these sequences trigger native desktop notifications - even when the terminal window isn't focused.

## VSCode Remote SSH: The Key Use Case

This solution shines brightest when you're working on a **remote EC2 instance via VSCode Remote SSH** - a common setup for cloud-based development where your compute resources live in AWS but your IDE runs locally.

### The Challenge with Remote Development

When Claude Code runs on a remote server:
- Notifications generated on the EC2 instance need to reach your local desktop
- Standard notification systems (like `notify-send` on Linux) only work locally
- The remote server has no direct access to your desktop notification system

### How OSC Sequences Bridge the Gap

Here's the magic: VSCode's integrated terminal **forwards OSC escape sequences** from the remote host to your local machine through the SSH connection. The data flow looks like this:

```
Remote EC2                          Local Machine
┌─────────────────┐                ┌─────────────────┐
│ Claude Code     │                │                 │
│      ↓          │    SSH Tunnel  │                 │
│ notify_osc.sh   │ ─────────────→ │ VSCode Terminal │
│      ↓          │                │      ↓          │
│ printf '\033]'  │                │ OSC Parser      │
│                 │                │      ↓          │
└─────────────────┘                │ Desktop Notify  │
                                   └─────────────────┘
```

### Required Extension: Terminal Notification

To convert OSC sequences into native desktop notifications, install the **[Terminal Notification][terminal-notifier-ext]** extension by wenbopan:

**Features:**
- Recognizes OSC 777 (`\033]777;notify;Title;Message\007`) and OSC 9 (`\033]9;Message\007`) sequences
- Generates native notifications on macOS, Windows, and Linux
- **Click-to-focus**: Click a notification to jump directly to the originating terminal tab
- **Remote SSH support**: Works seamlessly with VSCode Remote SSH
- **tmux compatible**: Automatically unwraps sequences forwarded through tmux

**Requirements:**
- VSCode 1.93 or later
- Shell Integration enabled (default for most shells)

### Why This Matters for Cloud Development

If you're running Claude Code on an EC2 instance (common for accessing more compute power or keeping development environments isolated), this setup means:

1. **No local Claude Code installation required** - Everything runs on the remote server
2. **Native notifications on your laptop** - Even though the work happens in AWS
3. **Works across network boundaries** - SSH handles the transport layer
4. **No additional infrastructure** - No webhook servers, no polling, just escape sequences

This is particularly valuable when:
- Running Claude Code on a powerful EC2 instance for faster processing
- Working with large codebases that benefit from cloud compute
- Maintaining development environments on remote servers
- Using multiple remote instances for different projects

## Implementation

### Step 1: Create the Notification Script

Create `~/.claude/hooks/notify_osc.sh`:

```bash
#!/bin/bash
# Send notifications via OSC escape sequences to active terminals

TITLE="${1:-Claude Code}"
MESSAGE="${2:-Task completed}"

LOG_DIR="$HOME/.claude/hooks"
LOG_FILE="$LOG_DIR/notification.log"
mkdir -p "$LOG_DIR"

# Read hook input JSON from stdin
if [ -t 0 ]; then
    HOOK_INPUT=""
else
    HOOK_INPUT=$(cat)
fi

# Extract project and task information
PROJECT_NAME=""
TASK_SUMMARY=""

if [ -n "$HOOK_INPUT" ] && command -v jq >/dev/null 2>&1; then
    # Extract project name from cwd
    CWD=$(echo "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null)
    if [ -n "$CWD" ]; then
        PROJECT_NAME=$(basename "$CWD")
    fi

    # Extract transcript path
    TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

    # Try to get task description from session file
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        # Method 1: Find first queue-operation enqueue
        TASK_SUMMARY=$(cat "$TRANSCRIPT_PATH" 2>/dev/null | \
            jq -r 'select(.type == "queue-operation" and .operation == "enqueue") |
                   .content[].text // empty' 2>/dev/null | \
            while IFS= read -r line; do
                # Skip system messages
                if [[ ! "$line" =~ ^\<(ide_opened_file|system-reminder|command-) ]]; then
                    echo "$line"
                    break
                fi
            done | head -c 100)

        # Method 2: Fallback to first user message
        if [ -z "$TASK_SUMMARY" ]; then
            TASK_SUMMARY=$(cat "$TRANSCRIPT_PATH" 2>/dev/null | \
                jq -r 'select(.type == "user") |
                       select(.isMeta == null or .isMeta == false) |
                       if .message.content | type == "array"
                       then .message.content[].text // empty
                       else .message.content end' 2>/dev/null | \
                while IFS= read -r line; do
                    if [ -n "$line" ] && [ "$line" != "null" ] && \
                       [[ ! "$line" =~ ^\<(ide_opened_file|system-reminder|command-) ]]; then
                        echo "$line"
                        break
                    fi
                done | head -c 100)
        fi
    fi
fi

# Build enhanced message
ENHANCED_MESSAGE="$MESSAGE"
if [ -n "$PROJECT_NAME" ]; then
    ENHANCED_MESSAGE="[$PROJECT_NAME] $ENHANCED_MESSAGE"
fi
if [ -n "$TASK_SUMMARY" ]; then
    ENHANCED_MESSAGE="$ENHANCED_MESSAGE - Task: $TASK_SUMMARY"
fi

# Log notification
{
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Notification sent:"
    echo "  Project: ${PROJECT_NAME:-N/A}"
    echo "  Message: $MESSAGE"
    echo "  Task: ${TASK_SUMMARY:-N/A}"
} >> "$LOG_FILE"

# Send to all writable pts devices
for pts in /dev/pts/*; do
    if [ "$pts" = "/dev/pts/ptmx" ]; then
        continue
    fi

    if [ -w "$pts" ] 2>/dev/null; then
        {
            printf '\033]777;notify;%s;%s\007' "$TITLE" "$ENHANCED_MESSAGE"
            printf '\033]9;%s: %s\007' "$TITLE" "$ENHANCED_MESSAGE"
            printf '\a'
        } > "$pts" 2>/dev/null
    fi
done

exit 0
```

Make it executable:
```bash
chmod +x ~/.claude/hooks/notify_osc.sh
```

### Step 2: Configure Claude Code Hooks

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify_osc.sh 'Claude Code' 'Task completed, please review results'",
            "timeout": 10
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify_osc.sh 'Claude Waiting' 'Claude has been idle for over 60 seconds'",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### Step 3: Test It

```bash
# Manual test
~/.claude/hooks/notify_osc.sh "Test" "Hello from Claude Code"

# Check logs
tail -f ~/.claude/hooks/notification.log
```

## The Multi-Window Challenge

If you're like me, you probably have multiple VSCode Remote SSH windows open to the same server, working on different projects. The basic implementation above sends notifications to **all** terminal devices, which means:

- Project A completes → notification appears in Project B's window
- Confusing and potentially distracting

### Understanding the Problem

Claude Code hooks run as **detached processes** without a controlling terminal. When we examine the process tree:

```
PID 794379 (bash): TTY_NR: 0
PID 794302 (zsh): TTY_NR: 0
PID 779087 (claude): TTY_NR: 0
```

All processes show `TTY_NR: 0` - no controlling terminal. This makes it impossible to determine which VSCode window spawned the hook through standard process inspection.

### The Solution: UUID-Based Terminal Mapping

Each VSCode instance has a unique identifier in the `VSCODE_IPC_HOOK_CLI` environment variable:

```
VSCODE_IPC_HOOK_CLI=/run/user/1000/vscode-ipc-785147ca-2a10-4fce-becc-b5f600ca1dec.sock
```

We can extract this UUID and maintain a mapping to terminal devices.

#### Manual Registration Script

Create `~/.claude/hooks/register_current_terminal.sh`:

```bash
#!/bin/bash
# Register current terminal for VSCode instance
# Run this directly in your VSCode terminal

LOG_DIR="$HOME/.claude/hooks"
MAPPING_FILE="$LOG_DIR/terminal_mapping.txt"
mkdir -p "$LOG_DIR"

# Get current TTY
CURRENT_TTY=$(tty)
if [ "$CURRENT_TTY" = "not a tty" ]; then
    echo "Error: Not running in a terminal"
    exit 1
fi

# Extract VSCode UUID
VSCODE_UUID=""
if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
    VSCODE_UUID=$(echo "$VSCODE_IPC_HOOK_CLI" | \
        grep -oP 'vscode-ipc-\K[0-9a-f-]+(?=\.sock)')
fi

if [ -z "$VSCODE_UUID" ]; then
    echo "Error: Could not extract VSCode UUID"
    exit 1
fi

# Update mapping file
if [ -f "$MAPPING_FILE" ]; then
    grep -v "^$VSCODE_UUID:" "$MAPPING_FILE" > "$MAPPING_FILE.tmp" || true
    mv "$MAPPING_FILE.tmp" "$MAPPING_FILE"
fi

echo "$VSCODE_UUID:$CURRENT_TTY" >> "$MAPPING_FILE"

echo "✓ Registered VSCode UUID: $VSCODE_UUID"
echo "✓ Terminal device: $CURRENT_TTY"
```

#### Enhanced Notification Script

Update `notify_osc.sh` to use the mapping:

```bash
# Near the beginning, after extracting HOOK_INPUT
MAPPING_FILE="$LOG_DIR/terminal_mapping.txt"
TARGET_TTY=""

# Extract VSCode UUID from environment
VSCODE_UUID=""
if [ -n "$VSCODE_IPC_HOOK_CLI" ]; then
    VSCODE_UUID=$(echo "$VSCODE_IPC_HOOK_CLI" | \
        grep -oP 'vscode-ipc-\K[0-9a-f-]+(?=\.sock)')

    if [ -n "$VSCODE_UUID" ] && [ -f "$MAPPING_FILE" ]; then
        TARGET_TTY=$(grep "^$VSCODE_UUID:" "$MAPPING_FILE" | cut -d: -f2)
    fi
fi

# Send notification
if [ -n "$TARGET_TTY" ] && [ -w "$TARGET_TTY" ]; then
    # Send to specific terminal only
    {
        printf '\033]777;notify;%s;%s\007' "$TITLE" "$ENHANCED_MESSAGE"
        printf '\033]9;%s: %s\007' "$TITLE" "$ENHANCED_MESSAGE"
        printf '\a'
    } > "$TARGET_TTY" 2>/dev/null
else
    # Fallback: broadcast to all terminals
    for pts in /dev/pts/*; do
        # ... existing broadcast logic
    done
fi
```

### Usage

In each VSCode terminal window, run once:

```bash
~/.claude/hooks/register_current_terminal.sh
```

Verify the mapping:

```bash
cat ~/.claude/hooks/terminal_mapping.txt
# Output:
# 785147ca-2a10-4fce-becc-b5f600ca1dec:/dev/pts/2
# 167d6e75-c42e-487d-9e9f-946e8396dd4f:/dev/pts/6
```

Now notifications will only appear in the correct VSCode window.

## Extracting Task Descriptions

The notification is more useful when it includes what task was being performed. Claude Code stores session data in JSONL files at `~/.claude/projects/`.

### Session File Structure

```json
{"type":"queue-operation","operation":"enqueue","content":[
  {"type":"text","text":"<ide_opened_file>...</ide_opened_file>"},
  {"type":"text","text":"Actual user task here"}
]}
```

### Key Insights

1. **Content is an array**: The first element is often a system message (`<ide_opened_file>`), the actual task is in subsequent elements

2. **Multiple message types**: Some sessions use `queue-operation`, others use direct `user` messages

3. **Filtering required**: Skip system tags like `<ide_opened_file>`, `<system-reminder>`, and `<command-`

The jq query that handles all cases:

```bash
jq -r 'select(.type == "user") |
       select(.isMeta == null or .isMeta == false) |
       if .message.content | type == "array"
       then .message.content[].text // empty
       else .message.content end'
```

## Troubleshooting

### No Notifications Appearing

1. **Check terminal support**:
   ```bash
   printf '\033]777;notify;Test;Message\007'
   ```

2. **Verify hook execution**:
   ```bash
   tail -f ~/.claude/hooks/notification.log
   ```

3. **Check pts devices**:
   ```bash
   ls -la /dev/pts/
   ```

### Notifications in Wrong Window

Run the registration script in your current terminal:
```bash
~/.claude/hooks/register_current_terminal.sh
```

### Task Description Shows "null"

This usually means:
- Session file doesn't exist yet (new session)
- `jq` is not installed
- Session file format changed

Install jq:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq
```

## Trade-offs

The `Stop` hook fires every time Claude pauses, not just on task completion. This means you might get notifications during:

- Multi-step tasks (between steps)
- When Claude asks clarifying questions
- Tool execution pauses

For most users, occasional extra notifications are preferable to the alternative - adding LLM-based completion detection that adds 30+ seconds of latency to every notification.

## Conclusion

With this setup, you can confidently switch away from Claude Code knowing you'll be alerted the moment it needs your attention. The combination of OSC escape sequences and Claude Code hooks creates a seamless notification experience that works across VSCode Remote SSH sessions.

The multi-window solution using UUID-based terminal mapping ensures notifications reach the right window, and task description extraction provides context about what just completed.

All scripts are available in my dotfiles repository, and I hope this saves you as much context-switching overhead as it has for me.

---

## Resources

- [Claude Code Hooks Documentation][claude-hooks-docs]
- [Terminal Notification Extension][terminal-notifier-ext] - VSCode extension for OSC-based notifications
- [OSC Escape Sequences Reference][osc-reference]
- [VSCode Terminal Documentation][vscode-terminal]

<!-- External Links -->
[claude-hooks-docs]: https://docs.anthropic.com/en/docs/claude-code/hooks
[terminal-notifier-ext]: https://marketplace.visualstudio.com/items?itemName=wenbopan.vscode-terminal-osc-notifier
[osc-reference]: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
[vscode-terminal]: https://code.visualstudio.com/docs/terminal/basics
