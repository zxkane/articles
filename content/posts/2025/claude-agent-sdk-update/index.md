---
title: "Upgrade to Claude Agent SDK: A Quick Migration Guide from Claude Code"
description: "Migrate from the legacy Claude Code SDK to the new Claude Agent SDK in minutes. This guide covers dependency changes, import updates, and breaking changes."
date: 2025-09-30
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: false
codeMaxLines: 70
codeLineNumbers: true
toc: true
categories:
- AI Development
- Automation
isCJKLanguage: false
tags:
- Claude Agent SDK
- Claude Code
- Agent Framework
- AI Automation
- TypeScript
- SDK Migration
keywords:
- claude agent sdk
- claude code sdk
- claude agent sdk migration
- upgrade claude code sdk
- anthropic sdk update
- ai automation development
- agentic application development
- ai-powered automation
- intelligent agents
- typescript ai
---

Heads up, builders! You may have noticed that Anthropic has rebranded the **Claude Code SDK** to the new **Claude Agent SDK**.

This is more than just a new name. As the [official announcement](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk) explains, this change reflects a strategic focus on making it easier than ever to build, debug, and deploy powerful AI agents.

If you've been following our [deep dive into building agentic applications][claude-code-post], you'll be happy to know that the migration is incredibly straightforward. All the core concepts and powerful features like conversation management, MCP integration, and response streaming are still there.

Here’s the TL;DR on how to upgrade your project.

### 1. Update Your Dependencies

First, uninstall the old package and install the new one.

```bash
npm uninstall @anthropic-ai/claude-code
npm install @anthropic-ai/agent-sdk
```

### 2. Update Your Imports

Next, just find and replace the import statements in your TypeScript files.

**Before:**
```typescript
import { query, type SDKMessage } from '@anthropic-ai/claude-code';
```

**After:**
```typescript
import { query, type SDKMessage } from '@anthropic-ai/agent-sdk';
```

### 3. Handle the Breaking Change in `query` Options

This is the most important part of the migration. The new SDK introduces a breaking change in how you provide a system prompt. The `appendSystemPrompt` option has been replaced with a more structured `systemPrompt` object.

Here’s how to adapt your `query` calls:

**Before (`claude-code-sdk`):**
```typescript
const response = query({
  prompt: prompt,
  options: {
    appendSystemPrompt: systemPrompt, // This is now deprecated
    mcpServers: mcpServers,
    // ...other options
  }
});
```

**After (`claude-agent-sdk`):**
```typescript
const response = query({
  prompt: prompt,
  options: {
    systemPrompt: systemPrompt, // Use the new systemPrompt option
    mcpServers: mcpServers,
    // ...other options
  }
});
```

In some cases, you might also want to specify the `systemPrompt` as a preset, like so:

```typescript
const response = query({
  prompt: slashCommand,
  options: {
    systemPrompt: { type: 'preset', preset: 'claude_code' },
    // ...other options
  }
});
```

And that's it! With these changes, your existing code, including all your slash commands and MCP configurations, will work exactly as before.

The move to the Claude Agent SDK is a clear signal of the agent-first future of AI. By making this small update, you're keeping your projects aligned with the latest and greatest from Anthropic.

For a complete guide to the architecture and patterns for building with the SDK, be sure to check out our [original, in-depth tutorial][claude-code-post].

Happy building!

---

[claude-code-post]: {{< relref "../claude-code-agent-framework/index.md" >}}
