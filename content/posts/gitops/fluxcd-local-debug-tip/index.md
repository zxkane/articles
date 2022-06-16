---
title: "FluxCD GitOps debugging tip"
description : "Debugging FluxCD GitOps locally"
date: 2022-06-16
draft: false
thumbnail: ./flux-eyecatch.png
usePageBundles: true
codeMaxLines: 20
categories:
- blogging
- kubernetes
series:
- gitops
isCJKLanguage: false
tags:
- Flux
- GitOps
- Kubernetes
- Git
- CD
- Continuous Delivery
- Debugging
---

After enabling E2E testing of FluxCD powered GitOps continuous deployment, the feedback of new commits are quite slow.
Because you have to wait for the E2E testing result, lots of time cost on setuping the environment and provisioning 
your development from scrath.

Inspired by [E2E testing in Github actions][gitops-e2e], the DevOps engineers can build local debugging environment in
[Kind][kind] or [minikube][minikube].

<!--more-->

Below is a script how using Kind to provision FluxCD then reconciling the latest commits by FluxCD.

{{< gist zxkane 7e13b79b8b95b1e43b690b7fb5416ecd >}}

[gitops-e2e]: https://github.com/zxkane/eks-gitops/actions/workflows/e2e.yaml
[kind]: https://kind.sigs.k8s.io/
[minikube]: https://minikube.sigs.k8s.io/docs/start/