---
title: "AWS Batch简介"
description : "AWS中跑批处理任务的神器"
date: 2019-12-25
draft: false
categories:
- blogging
- cloud-computing
thumbnail: "/posts/2019/aws-batch/aws-batch-app-demo.png"
isCJKLanguage: true
tags:
- AWS
- Batch
- Infrastructure as Code
---

[AWS Batch][aws-batch]是一个全托管的批处理调度服务，它可为用户管理所有基础设施，从而避免了预置、管理、监控和扩展批处理计算作业所带来的复杂性。当然[AWS Batch][aws-batch]已与 AWS 平台原生集成，让用户能够利用 AWS 的扩展、联网和访问管理功能。让用户轻松运行能够安全地从 AWS 数据存储（如 Amazon S3 和 Amazon DynamoDB）中检索数据并向其中写入数据的作业。[AWS Batch][aws-batch]可根据所提交的批处理作业的数量和资源要求预置计算资源并优化作业分配。能够将计算资源动态扩展至运行批处理作业所需的任何数量，从而不必受固定容量集群的限制。[AWS Batch][aws-batch]还可以利用 Spot 实例，从而进一步降低运行批处理作业产生的费用。

[AWS Batch][aws-batch]服务本身是**免费**的，仅收取实际使用的 EC2 实例费用。

<!--more-->

我创建了一个[Batch App demo][batch-app-demo]来演示[AWS Batch][aws-batch]相关使用方法。该示例通过一个Restful API接口来提交批处理任务，Restful API通过[ALB][alb] + [Lambda函数][lambda]来暴露服务。Lambda函数被触发后，将新任务请求发送到[SQS]服务。随后另一个Lambda将消费这个SQS，并将调用[AWS Batch][aws-batch] API来提交新的批处理任务，同时将任务信息储存到[DynamoDB][dynamodb]中。同时Demo创建了Batch任务会使用到的Docker Image，并且预先提交到[ECR][ecr]中。同时Batch任务定义了使用的EC2实例类型(c5系列实例，且包括Spot和按需两种计费方式的实例，且优先使用Spot实例)，实例默认伸缩数量为0(没有可执行任务时将中止实例)。并且提交的任务分为计算任务和统计归并任务，统计归并任务会依赖所以计算任务执行完毕才开始执行。最后通过另一Restful接口查询计算任务的最终结果，该接口同样使用[ALB][alb] + [Lambda函数][lambda]来实现。

{{< figure src="/posts/2019/aws-batch/aws-batch-app-demo.png" alt="Batch App架构图" >}}

Enjoy this [Batch App demo][batch-app-demo] orchestrated by [AWS CDK][aws-cdk].

[aws-batch]: https://aws.amazon.com/batch/
[batch-app-demo]: https://github.com/zxkane/cdk-collections/blob/master/batch-demo/README.md
[alb]: https://aws.amazon.com/cn/elasticloadbalancing/
[lambda]: https://aws.amazon.com/cn/lambda/
[dynamodb]: https://aws.amazon.com/cn/dynamodb/
[ecr]: https://aws.amazon.com/cn/ecr/
[aws-cdk]: https://aws.amazon.com/cn/cdk/
[sqs]: https://aws.amazon.com/cn/sqs/