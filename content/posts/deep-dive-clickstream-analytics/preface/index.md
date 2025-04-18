---
title: "How to build a clickstream analytic system for small businesses to large-scale events"
description : "the solution overview and introduction"
date: 2024-09-03
lastmod: 2024-10-21
draft: false
categories:
- blogging
- cloud-computing
series: clickstream-analytics
usePageBundles: true
thumbnail: images/cover.png
isCJKLanguage: false
showRelatedInArticle: false
codeMaxLines: 50
codeLineNumbers: true
featured: true
tags:
- Clickstream Analytics
- AWS
- Serverless computing
---

In the last couple of months, I led a team to build a comprehensive and open-sourced [solution][clickstream-landing-page] that helps customers analyze clickstream events on the cloud. The solution provides data autonomy, allowing users full access to raw data, near real-time ingestion, flexible configurations, and cost-effectiveness. It is a system that utilizes serverless services to cater to various customers, whether small businesses or large-scale events with massive data volumes, offering fully managed services with minimal operational efforts or the flexibility to use preferred open-source technical stacks.

The clickstream analytics system typically consists of several modules: SDKs, Data Ingest, Data Processing, Data Modeling and Visualization.

![Overview architecture](./images/overview.jpg "General clickstream analytics system architecture")

Building a well-architected and secure cloud-native system with modular, resilient, and cost-effective components is always challenging. The solution provides a production-ready and decoupled implementation, with most modules being optional. 

I will thoroughly explore all modules to deeply dive how to build a cloud-native system and implement a system that supports multiple technical variations and components.

- [Serverless Web Console][web-console]
- [Data Ingestion][data-ingestion]
- [Data Processing][data-processing]
- [Data Modeling][data-moduling]
- [Reporting][reporting]
- [Data Pipeline Observability][reporting]

[clickstream-landing-page]: https://aws.amazon.com/solutions/implementations/clickstream-analytics-on-aws/
[web-console]: {{< relref "/posts/deep-dive-clickstream-analytics/web-console/index.md" >}}
[data-ingestion]: {{< relref "/posts/deep-dive-clickstream-analytics/data-ingestion/index.md" >}}
[data-processing]: {{< relref "/posts/deep-dive-clickstream-analytics/data-processing/index.md" >}}
[data-moduling]: {{< relref "/posts/deep-dive-clickstream-analytics/data-modeling/index.md" >}}
[reporting]: {{< relref "/posts/deep-dive-clickstream-analytics/report/index.md" >}}
[pipeline-observability]: {{< relref "/posts/deep-dive-clickstream-analytics/pipeline-observability/index.md" >}}