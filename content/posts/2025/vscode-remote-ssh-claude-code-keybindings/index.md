---
title: "How to Fix Shift+Enter in VS Code Remote SSH for Claude Code"
description: "Resolve the issue where Shift+Enter prematurely submits prompts in Claude Code during a VS Code Remote SSH session. This guide provides a simple fix for keybindings."
date: 2025-11-06
lastmod: 2025-11-06
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: false
codeMaxLines: 20
codeLineNumbers: true
toc: true
categories:
- Tips & Tricks
- Development Tools
isCJKLanguage: false
tags:
- VS Code
- Claude Code
- Remote SSH
- Keyboard Shortcuts
- Troubleshooting
keywords:
- vscode remote ssh
- claude code shortcuts
- shift enter not working
- vscode keybindings
- remote development
- developer productivity
---

## The Problem: Premature Input Submission

When working with Claude Code in a VS Code Remote SSH session (e.g., connecting from a macOS or Windows client to a remote Linux host), a common frustration arises: pressing `Shift+Enter` in the terminal is supposed to create a new line for multi-line input. Instead, it often submits the current line prematurely.

This behavior disrupts the workflow for crafting complex, multi-line prompts, leading to fragmented interactions and inefficient token usage.

## Understanding the Root Cause

The issue stems from how VS Code handles keyboard shortcuts in a remote context. By default, the local VS Code client's keybindings take precedence. It captures the `Shift+Enter` event and processes it according to its local configuration before the remote session has a chance to interpret it, resulting in an unintended submission.

## The Solution: Synchronize Keybindings

To resolve this, you must ensure that the keybinding for `Shift+Enter` is correctly configured on **both your local machine and the remote host**.

### Step 1: Configure Your Local Machine

First, define the correct behavior on your local client. You need to add a custom keybinding that sends a specific escape sequence for a new line.

Open your `keybindings.json` file. The location varies by operating system:
- **macOS**: `~/Library/Application Support/Code/User/keybindings.json`
- **Windows**: `%APPDATA%\Code\User\keybindings.json`
- **Linux**: `~/.config/Code/User/keybindings.json`

You can also open this file from within VS Code by opening the Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`), typing `Preferences: Open Keyboard Shortcuts (JSON)`, and pressing Enter.

Add the following JSON object to the file:

```json
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "args": {
            "text": "\u001b\r"
        },
        "when": "terminalFocus"
    }
]
```

If the file already contains other keybindings, add this object inside the existing array, separated by a comma.

### Step 2: Verify the Remote Configuration

Claude Code typically attempts to configure this automatically on the remote machine. However, it's essential to verify that the configuration exists and is correct.

Connect to your remote host via VS Code SSH and check the contents of its `keybindings.json` file, located at `~/.config/Code/User/keybindings.json`. Ensure it contains the same JSON block from Step 1. If the file is missing or the entry is not present, create or update it accordingly.

### Step 3: Restart VS Code

For the changes to take full effect, completely quit and restart your local VS Code application. After restarting, reconnect to your remote SSH host.

## How the Keybinding Works

This configuration instructs VS Code to perform a specific action only when the integrated terminal is in focus (`"when": "terminalFocus"`).

- **`command`**: `workbench.action.terminal.sendSequence` tells VS Code to send a sequence of characters to the terminal.
- **`args.text`**: `"\u001b\r"` is the key part of the solution. It sends an `ESC` character (`\u001b`) followed by a `Carriage Return` (`\r`). This sequence is interpreted by the terminal as a command to insert a newline character rather than executing the current command.

This approach correctly enables multi-line input in the Claude Code prompt without affecting the `Enter` key's behavior in the chat panel or other editor inputs.

## Verification

To confirm the fix is working:
1. Open the Claude Code terminal prompt in your remote session.
2. Type a line of text.
3. Press `Shift+Enter`.

The cursor should move to a new line, allowing you to continue typing a multi-line prompt. The input should only be sent to Claude when you press `Enter` by itself.

## Resources

- [VS Code Remote Development Documentation][vscode-remote]
- [Claude Code Official Documentation][claude-code]

[vscode-remote]: https://code.visualstudio.com/docs/remote/remote-overview
[claude-code]: https://code.claude.com/docs/en/overview
