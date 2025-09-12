---
title: "AI 真能编程了吗？"
description: "从一个 Next.js 项目实践分享 AI 辅助编程的优势与局限性，以及对 AI 编程工具的深度体验"
date: 2024-11-13
lastmod: 2024-11-15
draft: false
thumbnail: ./images/cover.png
exclude_from_recent: true
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
isCJKLanguage: true
tags:
- Programming
- IDE
- GenAI
- Cline
- Aider
- Continue
- Cursor
- Amazon Q Developer
- GitHub Copilot
- Visual Studio Code
- LLM
- OpenAI
- Amazon Bedrock
- Anthropic Claude
- Productivity
- Next.js
- Material UI
- Vercel
- AWS Amplify
---

如果你平时关注科技圈的动态，那么你一定在朋友圈或直播中看到过这样的[吸睛话题][ai-programming-social-content]：

> - 编程小白用 AI 编程，人人都能成为编程高手
> - 零基础也能跨界开发
> - 编程小白的逆袭：借助 AI 打造 xxx

在自媒体的推波助澜下，AI 编程已成为一种潮流，甚至被包装成人人都可掌握的技能。当然，这背后也少不了培训公司借机贩卖焦虑的推动。

<!-- more -->

随着大模型能力的持续增强，特别是 Claude Sonnet 3.5 v2 的发布，[AI 编程的能力再次得到显著提升][swe-bench-sonnet]。各种 AI 编程工具和 AI IDE 层出不穷，比如 [Cline][cline]（VS Code 插件）、[Aider][aider]（主要支持 terminal）、[Continue][continue]（VS Code 和 JetBrains 插件）、[Cursor][cursor]（基于 VS Code 的自定义 IDE）、[Amazon Q Developer][q-developer]（VS Code 和 JetBrains 插件）以及 [GitHub Copilot][github-copilot]（VS Code 插件）等。这些工具如雨后春笋般涌现，确实说明 LLM 在编程领域的能力已经得到了显著提升，具备了实际应用的场景和能力。

最近，我在一个个人项目中完整体验了 Cursor 的 AI **辅助编程**能力，下面我就以这个项目为例，分享我的使用体验。

这是一个基于 [Next.js][nextjs] 和 [Material UI][mui] 实现的 [Web 应用][word-dication-source]，用于英语单词听写练习，同时可以帮助电脑初学者统计键盘输入效率。虽然我有多年的 JavaScript/TypeScript 开发经验，但这是我首次使用 React、Next.js、Material UI 等框架开发 Web 应用。整个应用从零开始，通过 Chat 模式与 LLM（主要是 Claude Sonnet 3.5 v2）协作创建项目骨架，并逐步完善功能及页面展示。最终通过 [Vercel][vercel] 和 [AWS Amplify][amplify-hosting] 完成部署上线（[Vercel 版本][word-dication-on-vercel]、[AWS 版本][word-dication-on-aws]）。

在开发过程中，我主要通过 Cursor 的 Chat 功能来描述需求，让 Cursor 据此生成代码。我的工作主要是审查生成的代码，决定接受或拒绝，并根据新的反馈让 Cursor 继续优化。与传统开发模式不同，我不再需要在编辑器中大量输入代码，而是通过对话模式与 Cursor 交流，描述需求并获取相应的代码实现。值得一提的是，Cursor 能够阅读整个项目的代码库，基于现有代码生成新的代码片段，并且支持同时为多个文件生成代码。它还支持引用外部文档和链接，通过 RAG 能力有效弥补了 LLM 知识库可能不够完整的短板。

根据我的实践经验，AI/LLM 在编程中的优势主要体现在以下几个方面：

1. 快速生成项目骨架
2. 帮助开发者迅速上手不熟悉的技术栈
3. 快速查询并解决常见错误
4. 高效总结和解释代码
5. 快速生成测试代码
6. 快速生成文档
7. 为代码实现提供多样化的思路

然而，AI 编程目前仍**无法完全替代**人类编程，主要局限在于：

1. 高效的代码辅助生成需要扎实的领域知识。所谓的"小白用户"往往难以将用户需求准确转化为编程领域的专业概念，因此无法提供有效的 Prompt 来生成满足业务需求的代码。以我的实践为例，最初我对 MUI 的组件完全陌生，不了解组件名称及其可能呈现的视觉效果。这导致我无法仅通过描述页面样式需求来实现预期的页面效果和布局。通过深入学习 MUI 文档，逐步熟悉其组件体系后，我开始在 Prompt 中精确指定组件名称、样式特性，甚至附上 MUI 组件文档链接，这才实现了理想的页面效果。

另一个典型案例是在实现听写功能时，我需要实现一个复杂的播放控制逻辑：单词可以被设置为间隔一段时间后重复播放，但当用户完成当前单词输入转入下一词时，需要中断之前未完成的播放调度。仅通过文字描述这样复杂的逻辑，AI 难以生成满意的代码。而对于具备相关编程知识和数据结构基础的开发者来说，很容易想到使用队列来管理待播放的单词，通过清理队列来实现播放中断的控制。

2. LLM 模型擅长检索和匹配已有信息，而不是通过推理探索问题的根本原因。这意味着当用户和 LLM 都缺乏相关知识时，可能会在错误的解决思路上反复尝试。例如，在我遇到的 Next.js 15.0.x、React 18.x 和 MUI 6.1.x 版本不兼容导致的间歇性 Bug 和运行时警告时，即便 LLM 参考了最新文档，也只能不断提供无效的解决方案，而没有意识到问题的本质在于软件版本的兼容性。

3. LLM 的知识库可能存在滞后性，即使通过 RAG 获取了最新资料，受限于模型训练数据的时效性，仍可能得出错误的结论。不过，随着模型的持续进步和 RAG 能力的增强，这个问题有望得到逐步改善。

我的观点是，**AI 编程目前还不能完全取代人类编程，但已经可以作为强有力的辅助工具**。对于新手来说，AI 辅助编程能帮助他们更快地上手陌生的技术栈，但要解决复杂或非标准的问题，仍需要开发者具备扎实的专业知识；而对于经验丰富的开发者而言，则能显著提升开发效率，快速生成可用的代码框架，并提供多样化的实现思路。有经验的开发者可以结合自身的专业知识和思维能力，配合 AI 的辅助功能，更快速、更高质量地完成复杂的编程任务。

[ai-programming-social-content]: https://weixin.sogou.com/weixin?type=2&s_from=input&query=%E7%BC%96%E7%A8%8B%E5%B0%8F%E7%99%BD+AI&ie=utf8&_sug_=y&_sug_type_=&w=01019900&sut=6626&sst0=1731470669943&lkt=3%2C1731470667727%2C1731470669841
[swe-bench-sonnet]: https://www.anthropic.com/research/swe-bench-sonnet
[cline]: https://github.com/cline/cline
[aider]: https://aider.chat/
[continue]: https://www.continue.dev/
[cursor]: https://www.cursor.com/
[q-developer]: https://aws.amazon.com/q/developer/
[github-copilot]: https://github.com/features/copilot
[nextjs]: https://nextjs.org/
[mui]: https://mui.com/
[vercel]: https://vercel.com/
[amplify-hosting]: https://aws.amazon.com/amplify/hosting/
[word-dication-on-aws]: https://dictation.aws.kane.mx/
[word-dication-on-vercel]: https://dictation.vercel.kane.mx/
[word-dication-source]: https://github.com/zxkane/word-dictation-practice