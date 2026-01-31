---
title: "AI Digital Engineer: End-to-End Delivery with Claude Code"
description: "Build an autonomous AI engineer that delivers production-ready software using Claude Code Skills for intelligent orchestration and Hooks for guaranteed execution - a hybrid architecture that combines LLM flexibility with deterministic reliability."
date: 2026-01-31
lastmod: 2026-01-31
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: true
codeMaxLines: 100
codeLineNumbers: true
toc: true
categories:
- AI Development
- DevOps
- Automation
isCJKLanguage: false
tags:
- Claude Code
- AI Digital Engineer
- GitHub Actions
- DevOps Automation
- Software Engineering
- CI/CD
- Test-Driven Development
keywords:
- ai digital engineer
- claude code workflow
- autonomous software development
- ai coding assistant
- github actions automation
- claude code hooks
- claude code skills
- end-to-end software delivery
- ai software engineer
- llm orchestration
---

What if an AI could operate like a senior software engineer - not just writing code, but following the complete engineering process from design through deployment? This post introduces the **AI Digital Engineer** pattern: a system that transforms Claude Code from an interactive assistant into an autonomous engineer capable of delivering production-ready software.

<!--more-->

## The Problem with Traditional AI Coding Assistants

Most AI coding tools operate in a simple request-response pattern: you ask for code, they generate it. This approach has fundamental limitations:

- **No process discipline**: The AI writes code without tests, reviews, or verification
- **Fragile workflows**: Complex multi-step tasks get lost in context windows
- **Unreliable execution**: LLM outputs are probabilistic, not guaranteed
- **Expensive scaling**: Every verification step requires another LLM call
- **No audit trail**: How do you prove the AI followed your engineering standards?

What we need is a system that combines **LLM intelligence for orchestration** with **deterministic guarantees for execution**.

## Introducing the AI Digital Engineer

An AI Digital Engineer is an autonomous system that operates like a human software engineer - following the complete engineering process:

| Human Engineer | AI Digital Engineer |
|----------------|---------------------|
| Reviews design requirements | Reads design canvas via Pencil MCP |
| Writes tests before code (TDD) | Enforced by PreToolUse hooks |
| Implements features | Claude Code implementation |
| Runs code review | Spawns PR Review agents |
| Responds to review feedback | Addresses Amazon Q/Codex findings |
| Verifies CI passes | Stop hook blocks until green |
| Performs E2E testing | Chrome DevTools MCP integration |
| Cannot merge without approvals | Hook system enforces all gates |

The key difference from traditional AI assistants: **the AI Digital Engineer cannot skip steps**. Quality gates are enforced by deterministic systems, not LLM memory.

## The Hybrid Architecture: Intelligence + Reliability

The AI Digital Engineer architecture separates concerns between what needs intelligence (orchestration) and what needs reliability (execution):

```
┌────────────────────────────────────────────────────────────────────┐
│                    AI Digital Engineer Architecture                 │
├────────────────────────────────┬───────────────────────────────────┤
│  Intelligent Orchestration     │     Deterministic Execution       │
│     (Claude Code Skills)       │  (Hooks + GitHub Actions + Agents)│
├────────────────────────────────┼───────────────────────────────────┤
│ ✓ Complex workflow navigation  │ ✓ 100% execution guarantee        │
│ ✓ Exception handling & recovery│ ✓ Zero LLM call cost              │
│ ✓ Start/resume from any step   │ ✓ No context window limits        │
│ ✓ Dynamic branching decisions  │ ✓ Millisecond response time       │
│ ✓ Natural language understanding│ ✓ Auditable execution logs       │
├────────────────────────────────┼───────────────────────────────────┤
│ Best for: Reasoning & judgment │ Best for: Quality gates & triggers│
└────────────────────────────────┴───────────────────────────────────┘
```

### Why This Separation Matters

Traditional agent architectures rely on LLMs for everything - including remembering to run tests, checking CI status, and enforcing review requirements. This approach fails because:

| Traditional AI Agent | AI Digital Engineer |
|---------------------|---------------------|
| Every step calls LLM | LLM only for orchestration decisions |
| Relies on LLM to remember steps | Hooks enforce execution automatically |
| Context overflow causes skipped steps | Persistent state enables resume |
| Expensive and unpredictable | Predictable cost model |
| Difficult to audit | Complete execution logs |

The AI Digital Engineer uses **Skills for the brain** (what to do, how to handle exceptions) and **Hooks for the muscles** (guaranteed execution of quality gates).

## The Three Pillars

### Pillar 1: Claude Code Skills - The Intelligent Orchestrator

Skills are markdown files that guide Claude through complex workflows. The [`github-workflow`][workflow-repo] skill defines a 12-step development process:

```markdown
---
description: GitHub development workflow for end-to-end delivery
---

You are following a structured development workflow. Current phase: $PHASE

## Workflow Steps
1. Design Canvas - Create UI/architecture mockups (Pencil MCP)
2. Branch Creation - Use feat/ or fix/ prefix
3. Test Plan - Document test cases before implementation
4. Implementation - Write code following TDD
5. Unit Tests - Verify all tests pass
6. Code Simplification - Run simplifier agent
7. PR Creation - Commit with standardized template
8. PR Review - Run review toolkit agents
9. CI Verification - Wait for GitHub Actions
10. Bot Review Handling - Address Amazon Q/Codex findings
11. E2E Testing - Verify on preview environment
12. Completion - All gates passed, ready for merge

## Exception Handling
- If CI fails: Analyze logs, fix issues, re-push
- If bot review finds issues: Address each comment thread
- If E2E fails: Debug, fix, mark e2e-tests complete

## Resume Capability
Current state is tracked in .claude/state/
You can resume from any step based on completed states.
```

**Key capability**: Skills enable Claude to handle exceptions intelligently. When CI fails, the skill guides Claude to analyze logs and fix issues - something deterministic scripts cannot do.

### Pillar 2: Claude Code Hooks - The Enforcement Layer

Hooks are shell scripts that execute at specific points in Claude's workflow. They **guarantee** that quality gates are enforced:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": ".claude/hooks/check-design-canvas.sh"
        }]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [{
          "type": "command",
          "command": ".claude/hooks/check-test-plan.sh"
        }]
      }
    ],
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/verify-completion.sh"
      }]
    }]
  }
}
```

**How hooks enforce the workflow:**

| Hook | Trigger | Enforcement |
|------|---------|-------------|
| `check-design-canvas.sh` | Before git commit | Blocks commit without design doc |
| `check-test-plan.sh` | Before file write/edit | Blocks code changes without test plan |
| `check-unit-tests.sh` | Before git commit | Blocks commit with failing tests |
| `check-code-simplifier.sh` | Before git commit | Blocks commit without simplification review |
| `check-pr-review.sh` | Before git push | Blocks push without PR review |
| `verify-completion.sh` | On task stop | Blocks completion without CI + E2E + resolved comments |

**Critical insight**: These hooks execute in **milliseconds** with **zero LLM cost**. They don't ask Claude to remember to check - they physically prevent violations.

### Pillar 3: GitHub Actions - External Verification

GitHub Actions provide verification that happens outside Claude's context:

```yaml
name: CI
on: [push, pull_request]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: npm ci
      - name: Run tests
        run: npm test
      - name: Build
        run: npm run build

  security-review:
    runs-on: ubuntu-latest
    steps:
      - name: Amazon Q Security Review
        uses: aws/amazon-q-developer-action@v1
      - name: CodeQL Analysis
        uses: github/codeql-action/analyze@v3
```

The `verify-completion.sh` hook queries GitHub's API to ensure:
- CI workflow has passed
- All review comments are resolved
- E2E tests are marked complete

```bash
# From verify-completion.sh
CI_STATUS=$(gh run list --branch "$BRANCH" --limit 1 --json conclusion -q '.[0].conclusion')
if [ "$CI_STATUS" != "success" ]; then
    echo "❌ Cannot complete: CI has not passed"
    exit 1
fi

# Check unresolved review threads
UNRESOLVED=$(gh api graphql -f query='...' --jq '.data.repository.pullRequest.reviewThreads.nodes | map(select(.isResolved == false)) | length')
if [ "$UNRESOLVED" -gt 0 ]; then
    echo "❌ Cannot complete: $UNRESOLVED unresolved review comments"
    exit 1
fi
```

## Real-World Example: Multi-tenant User Configuration System

To demonstrate the AI Digital Engineer in action, let's walk through a real complex feature implementation: a **multi-tenant user configuration system** for an OpenHands deployment platform.

### The Feature Requirements

The task was to build a complete user configuration management system allowing each tenant to:
- Configure custom MCP servers (stdio and HTTP types)
- Manage third-party integrations (GitHub, Slack) with auto-MCP injection
- Store encrypted secrets using KMS envelope encryption
- Merge user configs with global platform configuration

**Technical scope:**
- 6,300+ lines of code across 36 files
- AWS Lambda + API Gateway + KMS + S3 architecture
- TypeScript CDK infrastructure + Python Lambda handlers
- Comprehensive unit tests and E2E test cases

### How the AI Digital Engineer Delivered It

**Phase 1: Design & Test Plan**

The workflow began with design documentation and test case definition. The `check-design-canvas.sh` hook blocked any implementation until architecture was documented. The `check-test-plan.sh` hook ensured test cases were written before code.

**Phase 2: Initial Implementation**

Claude implemented the full feature with:
- `UserConfigStack`: Lambda + HTTP API Gateway for `/api/v1/user-config/*` endpoints
- `UserConfigLoader`: S3-based config loader integrated with Cognito authentication
- KMS envelope encryption for user secrets
- Python Lambda with `uv` lock file for reproducible dependencies

**Phase 3: CI Failures & Recovery**

This is where the **intelligent orchestration** proved essential. The CI pipeline failed with CDK token parsing errors:

```
Error: The URL constructor cannot parse CDK tokens at synthesis time
```

The Skill guided Claude to analyze the error and apply the fix - using `Fn.split` and `Fn.select` intrinsic functions instead of JavaScript URL parsing. A deterministic script couldn't diagnose this; it required LLM reasoning.

**Phase 4: Bot Review Integration**

Amazon Q Security Review flagged several issues:
- Plaintext KMS keys not cleared from memory after decryption
- Missing explicit deny policy on KMS key for sensitive operations
- Potential path traversal vulnerabilities in user ID handling

The workflow's `verify-completion.sh` hook blocked task completion until all review threads were resolved. Claude addressed each finding with targeted commits:

```bash
# Commit: fix(security): address reviewer bot findings
- Clear plaintext KMS keys from memory after use
- Add explicit deny policy to KMS key for PutKeyPolicy, CreateGrant, ScheduleKeyDeletion
- Add input validation to prevent path traversal attacks (CWE-22)
```

**Phase 5: E2E Testing Discovery**

During manual E2E testing on the staging environment, a **critical multi-tenancy bug** was discovered: User A's secrets were visible to User B. The root cause? OpenHands stored secrets at the S3 bucket root, not in user-scoped paths.

This is exactly the scenario where **Skills excel** - handling unexpected exceptions. Claude:
1. Documented the bug in test cases (TC-019, TC-020)
2. Designed user-scoped storage paths (`users/{user_id}/secrets.json`)
3. Implemented `S3SecretsStore` and `S3SettingsStore` with proper isolation
4. Added startup verification to ensure patches were applied correctly

**Phase 6: Architecture Refinement**

A reviewer suggested replacing API Gateway with ALB Lambda target groups for:
- Architecture consistency (single entry point)
- Cost optimization (no API Gateway fees)
- Lower latency (one less hop)

Claude refactored the entire routing layer, updating Lambda handlers to support ALB event format and modifying CloudFront distribution configuration.

### The Delivery Timeline

| Phase | Commits | What Happened |
|-------|---------|---------------|
| Initial Implementation | 1 | Full feature with tests |
| CI Fixes | 2 | CDK token parsing, test requirements |
| Security Review | 3 | Memory clearing, KMS policy, input validation |
| E2E Bug Discovery | 2 | Multi-tenancy isolation bug found and fixed |
| Architecture Refactor | 3 | API Gateway → ALB migration |
| Final Polish | 13 | Bedrock compatibility, MCP deduplication, snapshot updates |

**Total: 24 commits over 2 days, resulting in production-ready code.**

### Key Insights

1. **Skills handled the unexpected**: CI failures, security vulnerabilities, and multi-tenancy bugs all required reasoning and judgment - not scripted responses.

2. **Hooks guaranteed quality gates**: Every commit passed through code simplification. Every push triggered PR review. Task completion was blocked until CI passed and review comments were resolved.

3. **The hybrid architecture worked**: LLM costs were controlled (orchestration only), while execution was 100% reliable (hooks enforced every gate).

4. **Iterative refinement was automatic**: The workflow naturally drove 24 iterations of improvement, each triggered by external feedback (CI, bot reviews, E2E testing).

## Implementing the AI Digital Engineer

### Step 1: Clone the Workflow Template

```bash
git clone https://github.com/zxkane/claude-code-workflow.git
cp -r claude-code-workflow/.claude your-project/.claude
```

### Step 2: Configure Hooks

The template includes pre-configured hooks in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": ["Bash(.claude/hooks/*)", "mcp__*"]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": ".claude/hooks/check-design-canvas.sh"},
          {"type": "command", "command": ".claude/hooks/check-code-simplifier.sh"},
          {"type": "command", "command": ".claude/hooks/check-pr-review.sh"},
          {"type": "command", "command": ".claude/hooks/check-unit-tests.sh"}
        ]
      },
      {
        "matcher": "Write|Edit",
        "hooks": [
          {"type": "command", "command": ".claude/hooks/check-test-plan.sh"}
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {"type": "command", "command": ".claude/hooks/verify-completion.sh", "timeout": 10}
        ]
      }
    ]
  }
}
```

### Step 3: Set Up State Management

The state manager tracks workflow progress persistently:

```bash
# Mark a step complete
.claude/hooks/state-manager.sh mark design-canvas

# Check if a step was completed (within 30-minute window)
.claude/hooks/state-manager.sh check test-plan

# List all completed states
.claude/hooks/state-manager.sh list

# Clear state for re-run
.claude/hooks/state-manager.sh clear-all
```

State is stored in `.claude/state/` as JSON files with metadata:

```json
{
  "action": "design-canvas",
  "timestamp": "2026-01-31T10:30:00Z",
  "commit": "abc123",
  "branch": "feat/user-config",
  "files": ["docs/design/user-config.pen"]
}
```

### Step 4: Configure GitHub Actions

Add CI workflow that the completion hook will verify:

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
      - run: npm run build

  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - name: Amazon Q Code Review
        uses: aws/amazon-q-developer-action@v1
        with:
          command: review
```

### Step 5: Start Development

Simply tell Claude what you want to build:

```
Design and implement a user authentication system with JWT tokens
```

The `github-workflow` skill activates automatically and guides Claude through:
1. Creating a design canvas
2. Writing test cases
3. Implementing the feature
4. Running reviews and CI
5. Completing E2E verification

If you need to resume after a break:

```
Continue working on the authentication feature
```

Claude reads the state files and resumes from the appropriate step.

## Advanced Patterns

### Pattern 1: Spawning Sub-Agents for Parallel Work

Hooks can spawn specialized agents for specific tasks:

```json
{
  "PostToolUse": [
    {
      "matcher": "Bash(git push)",
      "hooks": [{
        "type": "command",
        "command": "claude -p 'Run PR review toolkit on current branch' --background"
      }]
    }
  ]
}
```

This allows:
- PR review agents to run asynchronously
- Security scan agents to analyze code in parallel
- Test coverage agents to report independently

### Pattern 2: Conditional Workflow Branches

Skills can define conditional paths based on context:

```markdown
## Workflow Branches

If this is a bug fix (branch starts with fix/):
- Skip design canvas requirement
- Focus on regression test
- Expedited review process

If this is a security fix:
- Require security team review
- Run additional security scans
- Notify security channel
```

### Pattern 3: External Tool Integration via MCP

The workflow integrates with external tools through MCP:

- **Pencil MCP**: Design canvas creation and validation
- **GitHub MCP**: PR management and review queries
- **Chrome DevTools MCP**: E2E testing automation
- **AWS MCP**: Infrastructure documentation queries

## Cost and Performance Analysis

Comparing traditional agent approaches with the AI Digital Engineer:

| Metric | Traditional Agent | AI Digital Engineer |
|--------|------------------|---------------------|
| LLM calls per PR | 50-100+ (every check) | 10-20 (decisions only) |
| Cost per feature | $5-15 | $1-3 |
| Verification reliability | ~80% (LLM may forget) | 100% (hooks enforce) |
| Context overflow risk | High (long workflows) | None (state persisted) |
| Audit trail | Conversation only | Hooks + Git + CI logs |

The hybrid architecture reduces costs by **70-80%** while improving reliability from probabilistic to deterministic.

## Conclusion

The AI Digital Engineer pattern transforms Claude Code from a coding assistant into an autonomous software engineer. The key insight is **separation of concerns**:

- **Skills** provide intelligent orchestration - handling complex workflows, exceptions, and decisions that require reasoning
- **Hooks** provide guaranteed execution - enforcing quality gates without relying on LLM memory or expensive API calls
- **GitHub Actions** provide external verification - ensuring standards are met outside the AI's context

This hybrid architecture delivers:
- **Production-ready code** that passes bot reviews and security scans
- **Predictable costs** by minimizing LLM calls for deterministic operations
- **Complete auditability** through persistent state and execution logs
- **Resilient workflows** that can resume from any point after interruption

The [claude-code-workflow][workflow-repo] template provides everything you need to implement this pattern. Clone it, configure it for your project, and start delivering software with an AI Digital Engineer.

## Resources

- [Claude Code Workflow Template][workflow-repo] - Complete implementation with skills, hooks, and state management
- [Claude Code Hooks Documentation][claude-hooks-docs] - Official hooks reference
- [Claude Code Skills Guide][claude-skills-docs] - How to create custom skills
- [Model Context Protocol][mcp-docs] - MCP integration for external tools

---

*Have you implemented AI-assisted development workflows? Share your experiences and patterns in the comments below!*

<!-- GitHub Repository -->
[workflow-repo]: https://github.com/zxkane/claude-code-workflow

<!-- Official Documentation -->
[claude-hooks-docs]: https://docs.anthropic.com/en/docs/claude-code/hooks
[claude-skills-docs]: https://docs.anthropic.com/en/docs/claude-code/skills
[mcp-docs]: https://modelcontextprotocol.io/
