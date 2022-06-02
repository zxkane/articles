---
title: "基于 Flux 的 GitOps 管理 Crossplane 部署及资源"
description : "用 Kubernetes 原生方式管理云中资源"
date: 2022-06-01
draft: false
toc: true
thumbnail: ./crossplane-horizontal-color.png
usePageBundles: true
codeMaxLines: 20
categories:
- blogging
- kubernetes
series:
- effective-cloud-computing
- gitops
isCJKLanguage: true
tags:
- Crossplane
- Flux
- GitOps
- Kubernetes
- Git
- EKS
- CD
- Continuous Delivery
---

## 背景

在[Flux 部署实战的总结展望][flux-in-action-2]中有一个方向是如何将云上基础设施资源同Kubernetes内资源统一管理，
而[Crossplane][crossplane]提供了一个高度可扩展的后端，使用声明式程序同时编排应用程序和基础设施，不用关心它们在哪里运行。

近期 AWS 官方博客宣布了 [AWS Blueprints for Crossplane][aws-crossplane-blueprints]，为客户提供了在 [Amazon EKS][eks]
上应用 Crossplane 的参考实现。

<!--more-->

## AWS Blueprints for Crossplane

AWS Blueprints for Crossplane 是一个 [Github 上开源项目][crossplane-aws-blueprints]，它提供了如下参考架构及功能，

- ✅   使用[Terraform][terraform] 创建 [Amazon EKS][eks]  集群并部署Crossplane
- ✅   使用[eksctl][eksctl] 创建 [Amazon EKS][eks]  集群并部署Crossplane
- ✅   [AWS Provider][crossplane-aws-provider]- Crossplane Compositions for AWS Services
- ✅   [Terrajet AWS Provider][crossplane-jet-aws-provider] - Another Crossplane Compositions for AWS Services
- ✅   [AWS IRSA on EKS][crossplane-aws-irsa] - AWS Provider Config with IRSA enabled 
- ✅   使用 AWS Provider 和 Terrajet AWS Provider 的 [Composite Resources (XRs)][composite-resources]示例部署模式
- ✅   使用[Crossplane Managed Resources (MRs)][managed-resources] 的示例部署

## 部署 Crossplane

EKS Crossplane 参考蓝图示例了如何使用 Terraform(通过[Amazon EKS Blueprints for Terraform][terraform-aws-eks-blueprints]) 和 eksctl 部署 EKS 集群及部署 Crossplane，
本文将演示如何使用 Flux 按照 GitOps 方式部署管理 Crossplane，演示将沿用 [Flux 实战][flux-in-action-1] 所使用的[示例repo][repo]。

### 手动部署 Crossplane

按照 [Crossplane 部署文档][crossplane-install-guide]，Crossplane 在 EKS 上的部署分为下面三步，

1. 通过 Helm 部署 Crossplane chart
2. 由于 Crossplane 大量通过 CRD 使用扩展性，需要在 Crossplane 组件部署成功后，
通过 Crossplane pkg CRD 部署及配置对应的 Provider，如在 AWS 上管理 AWS Provider 或 Terrajet AWS Provider
3. AWS Provider 或 Terrajet AWS Provider 是通过 `pkg` CRD 异步部署的，需要等 Provider CRD 可用后，才可部署对应的 Provider Config

### 通过 Flux 实现 GitOps 部署 Crossplane

鉴于 Crossplane 部署三个步骤的强依赖性，所以使用 Flux 部署通过 [Kustomization dependencies][flux-kustomization-dependencies]
功能实现三部分资源创建的先后依赖。

#### 1. 部署 Crossplane Helm chart

如下 manifest 创建 Crossplane helm release kustomization，
通过**healthChecks**检查确保 Crossplane 组件部署成功后才将 kustomization 设置为 reconcilation 成功。

```yaml {hl_lines=["2","4","16-20"]}
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: crossplane
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./infrastructure/base/crossplane/release
  targetNamespace: crossplane-system
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  timeout: 5m
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: crossplane
      namespace: crossplane-system
```

通过 [Flux Helm 支持][flux-helm]部署 Crossplane helm release

```yaml {hl_lines=["10-16"]}
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: crossplane
  namespace: crossplane-system
spec:
  releaseName: crossplane
  targetNamespace: crossplane-system
  chart:
    spec:
      chart: crossplane
      version: "1.8.0"
      sourceRef:
        kind: HelmRepository
        name: crossplane-stable
        namespace: crossplane-system
  serviceAccountName: helm-controller
  timeout: 5m
  test:
    enable: true
    ignoreFailures: true        
  interval: 1h0m0s
  install:
    crds: CreateReplace
    remediation:
      retries: 3
  upgrade:
    crds: CreateReplace
    remediation:
      remediateLastFailure: false    
```

#### 2. 创建 Crossplane AWS Provider

Kustomization `crossplane-provider` 将依赖 kustomization `crossplane`，
并检查 Crossplane AWS provider 自定义资源 `providerconfigs.aws.crossplane.io` 创建成功与否。
```yaml {hl_lines=["1-2", "14-15", "17-20"]}
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: crossplane-provider
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./infrastructure/base/crossplane/provider
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  dependsOn:
    - name: crossplane
  targetNamespace: crossplane-system
  healthChecks:
    - apiVersion: apiextensions.k8s.io/v1
      kind: CustomResourceDefinition
      name: providerconfigs.aws.crossplane.io
  timeout: 5m
  patches:
    - patch: |
        - op: replace
          path: /metadata/annotations/eks.amazonaws.com~1role-arn
          value: arn:aws:iam::845861764576:role/crossplane-provider-aws
      target:
        group: pkg.crossplane.io
        version: v1alpha1
        kind: ControllerConfig
```

#### 3. 创建 Provider Config

同样方式创建部署 `ProviderConfig` 资源的 kustomization 对象，依赖 `crossplane-provider` kustomization 部署。

```yaml {hl_lines=["13-14"]}
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: crossplane-provider-config
  namespace: flux-system
spec:
  interval: 10m0s
  path: ./infrastructure/base/crossplane/provider-config
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  dependsOn:
    - name: crossplane-provider
  timeout: 5m
```

## 使用 Crossplane 创建 AWS 基础设施

Crossplane 提供了两种方式表示外部系统资源，

1. [托管资源 (MR)][managed-resources] 是 Crossplane 对外部系统中资源的表示，例如，最常见的是云提供商。如下资源申明由
AWS Provider 支持，创建 AWS 上的 RDS 数据库实例。

```yaml
apiVersion: database.aws.crossplane.io/v1beta1
kind: RDSInstance
```

2. Crossplane [复合资源 (XR)][composite-resources]是由托管资源组成的封装的 Kubernetes 自定义资源。
复合资源旨在让用户使用自己的观点和 API 构建自己的平台，而无需从头开始编写 Kubernetes 控制器。 
相反，用户定义的 XR 架构教会 Crossplane 当有使用用户定义的 XR 时它应该组成（即创建）哪些托管资源。

AWS Blueprints for Crossplane 提供了 [Compositions][crossplane-blueprints-compositions] 示例，涵盖了 VPC，S3，IAM，RDS，DynamoDB，EKS 等服务。
如前面介绍 Crossplane Compositions(XRs) 是对基础设施的模式封装和组合，并不会直接创建云原生资源。

AWS Blueprints for Crossplane 同时提供了 [Examples 示例][crossplane-blueprints-examples] 直接使用 AWS Provider
提供的托管资源 (MR) 和示例的复合资源 (XR)，如上[Compositions][crossplane-blueprints-compositions]中示例VPC，S3, DynamoDB等AWS资源。

## 小结及展望

Crossplane 目前是 CNCF 基金会下孵化中项目，一定程度可以实现云上基础设施资源和 Kubernetes 内资源统一使用声明式方式管理。
复合资源 (Composite Resources) 支持了对业务需求的高层次抽象，理念同 [Construct Hub][construct-hub] 类似。
基础实施团队可以通过复合资源提供高阶抽象，复用经过验证且符合管理需求的抽象组合，简化下游团队管理资源的复杂度。

Crossplane 自身利用 [K8S CRD][k8s-crd] 创建管理 Composite Resources，首先需要用户熟悉 CRD 的实现。
XRs 本质是通过声明式方式管理云原生基础设施，同样 AWS CloudFormation 是由 AWS 原生提供的通过声明式方式管理 AWS 上资源。
由于云原生资源的功能复杂性，CloudFormation 面临的编写复杂声明式代码，不易于测试和复用的问题同样在 Crossplane XRs 上存在。
同时面对数量庞大的 AWS 或其他云厂商原生服务资源，需要大量的社区资源来创建管理 AWS 可复用的复合资源模式，
可以预见在相当一段时间内云厂商托管资源覆盖率及高阶的复合资源数量都是该技术被广泛采纳的一个障碍。

对比 [AWS CDK][cdk]/Pulumi 编程方式管理创建的复用资源和更高阶的抽象， Crossplane 在开发和复用效率上并没有优势。
Crossplane 最大的优势是可通过统一 Kubernetes 声明式方式来管理云上资源和 Kubernetes 集群内资源。
但对用户而言采用 Crossplane 的学习成本和开发复杂度较高，Crossplane 及类似技术可列为持续评估调用中，小量谨慎用于生产环境。

[flux-in-action-2]: {{< relref "/posts/gitops/flux-in-action-2.md#六小结及展望" >}}
[crossplane]: https://crossplane.io/
[aws-crossplane-blueprints]: https://aws.amazon.com/blogs/opensource/introducing-aws-blueprints-for-crossplane/
[eks]: https://aws.amazon.com/eks/
[crossplane-aws-blueprints]: https://github.com/aws-samples/crossplane-aws-blueprints
[terraform]: https://www.terraform.io/
[eksctl]: https://eksctl.io/
[crossplane-aws-provider]: https://github.com/crossplane/provider-aws
[crossplane-jet-aws-provider]: https://github.com/crossplane-contrib/provider-jet-aws
[crossplane-aws-irsa]: https://github.com/crossplane/provider-aws/blob/master/AUTHENTICATION.md#using-iam-roles-for-serviceaccounts
[composite-resources]: https://crossplane.io/docs/v1.6/concepts/composition.html
[managed-resources]: https://crossplane.io/docs/v1.6/concepts/managed-resources.html
[terraform-aws-eks-blueprints]: https://github.com/aws-ia/terraform-aws-eks-blueprints
[flux-in-action-1]: {{< relref "/posts/gitops/flux-in-action-1.md" >}}
[repo]: https://github.com/zxkane/eks-gitops
[crossplane-install-guide]: https://crossplane.io/docs/v1.8/getting-started/install-configure.html
[flux-kustomization-dependencies]: https://fluxcd.io/docs/components/kustomize/kustomization/#kustomization-dependencies
[flux-helm]: {{< relref "/posts/gitops/flux-in-action-1.md#2-管理集群共享的组件" >}}
[crossplane-blueprints-compositions]: https://github.com/aws-samples/crossplane-aws-blueprints/tree/main/compositions
[crossplane-blueprints-examples]: https://github.com/aws-samples/crossplane-aws-blueprints/tree/main/examples
[construct-hub]: https://constructs.dev/
[k8s-crd]: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
[cdk]: https://github.com/aws/aws-cdk