---
title: "Build on AWS Faster with Claude Code and AWS Skills"
description: "See how AWS Skills for Claude Code turns your AI assistant into an AWS expert. Build serverless apps with CDK best practices, cost estimates, and architectural patterns, all within your IDE."
date: 2025-10-26
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: true
codeMaxLines: 70
codeLineNumbers: true
toc: true
categories:
- Cloud Computing
- AI Development
- Developer Tools
isCJKLanguage: false
tags:
- Claude Code
- AWS Skills
- AWS CDK
- Serverless
- Lambda
- DynamoDB
- API Gateway
- Agent Skills
- MCP Protocol
- Infrastructure as Code
keywords:
- aws skills claude code
- claude code aws plugin
- aws cdk ai assistant
- serverless development ai
- aws infrastructure as code
- claude agent skills aws
- ai-powered aws development
- cost optimization aws
- aws best practices automation
- mcp protocol aws
---

## Introduction

Building on AWS is powerful but complex. What if your AI assistant had deep AWS expertise built-in? That's what **AWS Skills** brings to Claude Code.

[AWS Skills][aws-skills-repo] is a plugin that transforms Claude Code into an intelligent AWS development partner. It understands CDK best practices, estimates costs before you deploy, and guides you through serverless patterns. This post shows you how to build a serverless REST API using Claude Code supercharged with AWS Skills.

## How It Works: Agent Skills

AWS Skills uses **Claude Agent Skills**, which are modular extensions that give Claude new capabilities. Claude autonomously decides when to use a skill based on your request, allowing it to interact with external tools like the AWS CDK, pricing calculators, and documentation.

## The AWS Skills Capabilities

AWS Skills bundles this power into three plugins:

1.  **AWS CDK Plugin**: Brings CDK expertise, best practices, and `cdk-nag` security checks into your workflow.
2.  **Cost & Operations Plugin**: Provides pre-deployment cost estimates, billing analysis, and CloudWatch monitoring.
3.  **Serverless & EDA Plugin**: Offers patterns for event-driven architectures using EventBridge, Step Functions, and SAM.

## Building a Serverless REST API

Let's build a simple task management REST API to see how AWS Skills improves the development workflow.

### Architecture

We'll build an API with three main components:

- **API Gateway**: Provides the RESTful HTTP endpoint.
- **Lambda Function**: Contains the business logic.
- **DynamoDB**: Stores the task data.

### Step 1: Ask Claude to Create the CDK Infrastructure

With AWS Skills, you can ask for the infrastructure in plain English.

**You:**
```
/aws-cdk-development Create a CDK stack for a task management API with an API Gateway, a Lambda function(without detailed implementation), and a DynamoDB table. Follow AWS best practices and write in Python.
```

**Claude (with AWS Skills):**

The **AWS CDK Plugin** helps Claude generate a complete, best-practice CDK stack in TypeScript based on the prompt. It defines the DynamoDB table, the Lambda function, and the API Gateway, including setting up the necessary IAM permissions.

### Step 2: Implement the Lambda Handler

You can then ask Claude to generate the Lambda function code with best practices.

**You:**
```
/aws-serverless-eda Now, create the Python Lambda handler for the task API. It should handle POST requests to create a task and GET requests to retrieve one.
```

**Claude (with AWS Skills):**

Claude generates the Lambda handler code, including the logic for creating and retrieving tasks from the DynamoDB table using the AWS SDK.

### Step 3: Estimate Costs Before Deployment

This is where AWS Skills really shines. Ask for a cost estimate before deploying anything.

**You:**
```
Estimate the monthly cost for this API assuming 1 million requests per month, 100ms average Lambda duration, and 10GB of data in DynamoDB.
```

**Claude (with Cost & Operations Plugin):**

Claude uses its cost estimation skill to give you a clear breakdown of the estimated monthly costs for API Gateway, Lambda, and DynamoDB based on your usage estimates. This helps you make informed decisions before deployment.

### Step 4: Deploy with Confidence

When you're ready, Claude guides you through deployment.

**You:**
```
Deploy this stack to us-east-1.
```

**Claude:**

Claude provides the exact `cdk` commands to bootstrap your environment (if needed) and deploy the stack. It will also show you the API endpoint URL from the stack outputs once the deployment is complete.


## Development Workflow: Before vs. After

AWS Skills streamlines your workflow by keeping you in your IDE, saving time and reducing context switching.

**Before: The Old Way**
1.  Write code in your IDE.
2.  Switch to a browser to search documentation.
3.  Open another tab for the AWS Pricing Calculator.
4.  Manually check for best practices.
5.  Deploy from the CLI.
6.  Debug issues in the AWS Console.

**After: With AWS Skills**
1.  Describe your goal in plain language.
2.  Claude generates the code and a cost estimate.
3.  Review and refine in your IDE.
4.  Deploy automatically from Claude.

You ship better code faster, all from one place.

## Conclusion

AWS Skills turns Claude Code into a specialized AWS development partner. It brings real-time AWS knowledge directly into your editor, helping you build faster, more cost-effective, and more reliable applications.

By automating best practices, providing pre-deployment cost insights, and guiding you through complex patterns, AWS Skills lets you focus on what matters most: your application's business logic.

## Resources

- [AWS Skills GitHub Repository][aws-skills-repo]
- [Claude Code Agent Skills][claude-skills-docs]
- [Model Context Protocol][mcp-protocol]

---

*Ready to build on AWS faster? Install AWS Skills and let me know what you think in the comments!*

[aws-skills-repo]: https://github.com/zxkane/aws-skills
[claude-skills-docs]: https://docs.claude.com/en/docs/claude-code/skills
[mcp-protocol]: https://modelcontextprotocol.io/