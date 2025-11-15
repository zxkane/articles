---
title: "Beyond Prompts: 4 Context Engineering Secrets for Claude Code"
description: "Master context engineering patterns to build reliable AI agents with Claude Code. Learn hierarchical memory, hooks, autonomous skills, and 1M token optimization."
date: 2025-11-14
lastmod: 2025-11-14
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: false
codeMaxLines: 70
codeLineNumbers: true
toc: true
categories:
- AI/ML
- Software Engineering
- Cloud Computing
isCJKLanguage: false
tags:
- Claude Code
- AI Agents
- Context Engineering
- LLM
- Developer Tools
- AWS Bedrock
- Anthropic
keywords:
- context engineering
- Claude Code tips
- AI agent development
- LLM best practices
- Claude Agent SDK
- prompt engineering
- Amazon Bedrock integration
- deterministic AI behavior
---

You can stop hoping your Large Language Model (LLM) follows complex instructions. **Context Engineering** is the strategic practice of curating what enters the model's limited attention budget. To build reliable AI agents, you must master these four deterministic context patterns.

This post explores the key insights from my presentation "[Claude Code Skill(s): Mastering AI-Powered Development][slides]", focusing on practical patterns that transform unpredictable AI interactions into deterministic, production-ready workflows.

## What is Context Engineering?

Context Engineering is the art and science of strategically managing what information an LLM processes within its limited attention window. Unlike traditional prompt engineering, which focuses on crafting individual requests, context engineering treats the entire development environment as a programmable context system.

The challenge: Modern LLMs like Claude offer massive context windows (up to 1 million tokens), but without proper engineering, this capacity becomes a liability rather than an asset. Information overload, context pollution, and inconsistent behavior plague naive implementations.

The solution: Treat context as a managed resource with four key patterns.

## 1. Memory is a Hierarchical Filesystem

Claude Code manages context through structured, version-controllable files rather than ephemeral prompts or database entries. This **Hierarchical Memory** system uses a clear precedence:

```
~/.claude/CLAUDE.md (User)      # Global instructions across all projects
./CLAUDE.md (Project)            # Project-specific guidelines
./CLAUDE.local.md (Local)        # Machine-specific overrides (gitignored)
```

### Why Filesystem-Based Memory Matters

**Version Control Integration**: Your team's AI expertise becomes git-committable knowledge. When a senior engineer discovers an optimal workflow pattern, it's captured in `CLAUDE.md` and distributed to the entire team through version control.

**Consistent Context Delivery**: Every interaction with Claude Code starts with the same foundational knowledge. No more repeating "use conventional commits" or "follow our coding standards" in every session.

**Layered Context Precedence**: The hierarchical structure allows for inheritance and overrides:
- User-level instructions define personal preferences
- Project-level instructions enforce team standards
- Local overrides handle machine-specific configurations

### Practical Example

```markdown
# ./CLAUDE.md (Project)

## AWS CDK Best Practices

- **Resource Naming**: Do NOT explicitly specify resource names
  when optional in CDK constructs. Let CDK generate unique names
  to enable parallel stacks and environments.

- **Lambda Functions**: Use `@aws-cdk/aws-lambda-nodejs` for
  TypeScript/JavaScript. These constructs handle bundling,
  dependencies, and transpilation automatically.
```

This single file eliminates hundreds of repetitive prompts across your team's development lifecycle.

## 2. Hooks Enforce Context Injection

**Hooks** are shell commands triggered at specific lifecycle events in Claude Code, providing **Deterministic Control** over AI behavior. The most powerful pattern is the **Memory Enforcer**, which leverages the `UserPromptSubmit` event.

### The Power of UserPromptSubmit Hooks

This event executes **before** any AI processing begins, allowing you to:
- Inject domain-specific knowledge
- Pre-load necessary context
- Trigger autonomous skills
- Enforce organizational policies

```bash
# ~/.claude/hooks/user-prompt-submit.sh

# Automatically inject AWS best practices for infrastructure queries
if echo "$PROMPT" | grep -qi "aws\|lambda\|cdk"; then
  echo "Loading AWS architecture context..."
  cat ~/.claude/aws-patterns.md
fi

# Trigger security review for authentication-related changes
if echo "$PROMPT" | grep -qi "auth\|login\|credential"; then
  echo "/security-review"
fi
```

### From Hope to Guarantee

> "Deterministic Control: Hooks transform 'hope AI follows instructions' into 'guaranteed execution' through code enforcement."

Traditional prompt engineering: "Please remember to check security implications..."

Hook-based enforcement:
```bash
# Security hook always runs on code changes
if [ -n "$(git diff --name-only | grep -E '\.(ts|js|py)$')" ]; then
  /run-security-scan
fi
```

The hook guarantees execution. The AI doesn't "forget" or "overlook"—the system enforces the behavior.

## 3. Skills Are Autonomous, Context-Driven Extensions

**Agent Skills** are modular knowledge bases that Claude autonomously invokes based on context. Unlike manual tool invocations, Skills are discovered and activated by Claude itself when the context matches their description.

### The Anatomy of an Effective Skill

Skills are defined as `SKILL.md` files with three critical components:

1. **Clear Description**: What the skill does (for autonomous discovery)
2. **Activation Context**: When Claude should use it
3. **Domain Knowledge**: The expertise it provides

```markdown
---
name: aws-cdk-patterns
description: AWS CDK architecture patterns and best practices
trigger: Use when designing or implementing AWS infrastructure with CDK
---

# AWS CDK Architecture Patterns

## Serverless API Pattern
When building REST APIs, prefer this stack composition:
- API Gateway (HTTP API for cost efficiency)
- Lambda (Node.js runtime with arm64 for performance)
- DynamoDB (single-table design when appropriate)

[Implementation details...]
```

### Autonomous Activation

The key difference from traditional tools:

**Manual Tool Invocation** (Traditional):
```
User: "Use the AWS tool to create a Lambda function"
```

**Autonomous Skill Activation** (Context-Driven):
```
User: "Create a serverless API for user management"
Claude: [Sees "serverless API" context]
        [Discovers aws-cdk-patterns skill]
        [Autonomously loads and applies patterns]
        [Implements with best practices baked in]
```

The skill's description enables proper discovery. Claude reasons: "This query involves serverless APIs → aws-cdk-patterns skill matches → load and apply."

### Reducing Repetitive Prompting

Before Skills:
```
User: "Create Lambda with proper IAM roles"
User: "Add DynamoDB with encryption"
User: "Configure API Gateway with CORS"
User: "Set up CloudWatch logging"
```

With Skills:
```
User: "Create a serverless API"
Claude: [aws-cdk-patterns skill automatically applies all patterns]
```

The skill encapsulates the complete pattern, eliminating prompt repetition.

## 4. Configure for 1M Token Scale

Effectively using Claude's 1 million token context window requires explicit configuration and understanding of the infrastructure.

### Amazon Bedrock Integration

When integrating Claude via Amazon Bedrock, enable extended context explicitly:

```bash
# Enable 1M token context window
/model sonnet[1m]

# Verify configuration
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-5-sonnet-20241022-v2:0[1m]
```

The `[1m]` suffix is critical—without it, you're limited to smaller context windows.

### Claude Agent SDK Features

For programmatic agent development, the [Claude Agent SDK][agent-sdk] provides essential context management:

```typescript
import { Agent } from '@anthropic-ai/agent-sdk';

const agent = new Agent({
  model: 'claude-3-5-sonnet-20241022',
  // Automatic context compaction when approaching limits
  autoCompact: true,
  // Control token allocation for reasoning
  thinkingBudget: 16000,
  // Long-running session support
  maxTurns: 100
});
```

### Token Budget Optimization

**Thinking Budget**: Control how many tokens Claude allocates to internal reasoning:
```typescript
// Development/debugging: verbose reasoning
thinkingBudget: 32000

// Production: efficient processing
thinkingBudget: 8000
```

**Context Compaction**: The SDK automatically summarizes older context when approaching limits, maintaining relevance while preserving essential information.

### Long Session Strategies

For extended development sessions:

1. **Periodic Checkpointing**: Save key decisions and context
2. **Strategic Summarization**: Compress completed work
3. **Context Pruning**: Remove no-longer-relevant information
4. **Hierarchical Memory**: Offload persistent knowledge to CLAUDE.md files

```bash
# Hook for automatic session checkpointing
# ~/.claude/hooks/every-10-turns.sh
echo "Creating context checkpoint..."
claude-snapshot save "checkpoint-$(date +%s)"
```

## The Paradigm Shift: Programming Claude's Perception

Context engineering represents a fundamental shift from **request-response prompting** to **environment programming**. You're not asking Claude to do things differently—you're changing what Claude perceives as reality.

### Traditional Approach: Persuasion
```
"Please follow our coding standards..."
"Remember to add tests..."
"Don't forget error handling..."
```

### Context Engineering: Perception Programming
```
CLAUDE.md defines coding standards as reality
Hooks guarantee test execution
Skills embed error handling patterns
```

Claude doesn't need to "remember" or "try hard"—the engineered context makes correct behavior the natural, obvious choice.

## Implementation Checklist

Ready to implement these patterns? Here's your action plan:

### Immediate Actions
- [ ] Create project `CLAUDE.md` with team standards
- [ ] Set up user-level `~/.claude/CLAUDE.md` for personal workflows
- [ ] Configure `.gitignore` to exclude `CLAUDE.local.md`

### Hooks Setup
- [ ] Create `~/.claude/hooks/user-prompt-submit.sh`
- [ ] Implement context injection for common domains
- [ ] Add security enforcement hooks

### Skills Development
- [ ] Identify repetitive instruction patterns
- [ ] Convert top 3 patterns to Agent Skills
- [ ] Write clear skill descriptions for autonomous activation

### Scale Configuration
- [ ] Enable `[1m]` context for larger context window
- [ ] Configure thinking budget for your use case
- [ ] Implement session management strategy

## Conclusion

Context engineering transforms AI development from an art of persuasion into a science of deterministic systems design. By treating context as managed infrastructure—through hierarchical memory, enforced hooks, autonomous skills, and optimized configuration—you build reliable AI agents that perform consistently.

The four patterns work synergistically:
- **Memory** provides foundational knowledge
- **Hooks** enforce critical behaviors
- **Skills** deliver domain expertise autonomously
- **Configuration** enables scale and efficiency

Stop hoping your LLM follows instructions. Start engineering the context that makes correct behavior inevitable.

---

## Watch the Full Presentation

For a deeper dive into these concepts with live demonstrations, watch my presentation:

{{< gdocs src="https://docs.google.com/presentation/d/e/2PACX-1vQNcxAZ2ZtvbxquJlO9m9_bJTGPaMlRS27NQ7SKpyXmpaV221LnFSQLkqvyeTP6DEzbVsennPYYB6ae/pubembed?start=false&loop=false&delayms=5000" >}}

## Resources

- [Claude Code Documentation][claude-code-docs]
- [Claude Agent SDK on GitHub][agent-sdk]
- [Amazon Bedrock Claude Models][bedrock-claude]
- [Context Engineering Best Practices][context-practices]
- [Presentation Slides: Claude Code Skill(s)][slides]

[slides]: https://docs.google.com/presentation/d/1fifANGCI85B4Pxz6XhLN0CeI3fTVS-ktsWfFBrhx2Do/edit?usp=sharing
[claude-code-docs]: https://docs.claude.com/en/docs/claude-code
[agent-sdk]: https://github.com/anthropics/claude-agent-sdk-typescript
[bedrock-claude]: https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-anthropic-claude.html
[context-practices]: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents