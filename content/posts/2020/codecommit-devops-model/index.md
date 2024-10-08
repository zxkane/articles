---
title: "基于CodeCommit代码管理的无服务器架构Devops"
description : "轻松管理海量仓库的Devops协作流程"
date: 2020-03-26
draft: false
thumbnail: /posts/2020/codecommit-devops-model/images/cover.png
categories:
- blogging
- cloud-computing
isCJKLanguage: true
tags:
- 云计算
- AWS
- Devops
- CodeCommit
- Git
---
[Github][github]/[Gitlab][gitlab]已经成为众多开发者非常熟悉的代码协作平台，通过他们参与开源项目或实施企业内部项目协作。

AWS也提供了托管的、基于Git、安全且高可用的代码服务[CodeCommit][codecommit]。[CodeCommit][codecommit]主要针对企业用户场景，所以他并没有社交功能以及代码仓库fork功能，是否[CodeCommit][codecommit]就无法实现[Github基于Pull Request][github-pr]的协同工作模式呢？

<!--more-->

答案是，[CodeCommit][codecommit]完全可以实现**基于Pull Request的代码协作**。由于[Git][git]的分布式代码管理特性，首先fork上游项目仓库，将修改后的代码提交到fork仓库，通过Pull Request申请修改请求合并。Github将这套协作流程推广开来并被开源项目广泛采用。其实还有另外的Git仓库协同方式来完成多人的协作开发，例如[Gerrit Code Review][gerrit]。目前Android、Eclipse Foundation下面的各种项目都在使用Gerrit作为协同开发工具。[Gerrit][gerrit]通过控制同一个代码仓库中不同角色的用户可提交代码分支的权限来实现代码贡献、Review、持续集成以及协同开发的。

[CodeCommit][codecommit]作为AWS托管的服务，同IAM认证和授权管理做了很好的集成。完全可以通过IAM Policy的设置，为同一个代码仓库中不同用户角色设置不同的权限。使用类似[Gerrit][gerrit]的权限控制思路，

- 任意代码仓库*协作者*可以提交代码到特定含义的分支，例如，`features/*`, `bugs/*`。可以允许多人协同工作在某一特定分支上。协作者同时可以创建新的Pull Request请求合并代码到主分支，例如`master`或者`mainline`。
- 代码仓库Master/Owner有权限合并Pull Request。
- 拒绝任何人直接推送代码到仓库主分支，包括仓库Owner/Admin。
- 监听仓库Pull Request创建和PR源分支更新事件，自动触发该PR对应分支的automation build，编译、测试等通过后，自动为PR的`通过`投票+1。反之若失败，则取消投票。
- 为代码仓库设置PR Review规则，至少需要收到PR automation build和仓库Master/Owner合计两票`通过`才允许合并代码。
- 监听代码仓库主分支，任意新提交将触发自动化发布Build。将最新变更在整个系统上做集成。

是不是很棒！完全做到了Github、Github Pull Request、Github Action/Travis CI整套devops协同开发的流程。

协作流程如下图，
{{< figure src="images/codecommit-devops-model.png" alt="基于CodeCommit代码管理的协同流程" >}}

同时，以上整套基于CodeCommit代码管理的devops工作流程可以利用CloudFormation实现AWS资源编排，将Devops依赖的Infra使用代码来做管理！这样的好处是，企业内部即使有数百数千甚至更多代码仓库都可以统一管理，新仓库的申请也可以通过Infra代码的PR，在通过审批合并后自动从AWS provisioning创建出符合企业管理要求的安全代码仓库。很酷吧:laughing:

[这里][codecommit-devops-model]有一套完整的创建以上工作流的演示，有兴趣的读者可以在自己的账户内体验。整套方案完全使用的是AWS托管服务，仅按实际使用量(如使用CodeBuild编译了代码)计费。

[github]: https://github.com/
[gitlab]: https://about.gitlab.com/
[codecommit]: https://aws.amazon.com/codecommit/
[github-pr]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests
[git]: https://git-scm.com/
[gerrit]: https://www.gerritcodereview.com/
[codecommit-devops-model]: https://github.com/zxkane/cdk-collections/tree/master/codecommit-collaboration-model
