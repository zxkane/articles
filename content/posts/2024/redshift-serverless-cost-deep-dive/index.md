---
title: "Redshift Serverless: Cost Deep Dive and Use Cases"
description : "Understand its magic before diving in!"
date: 2024-02-24
lastmod: 2024-02-24
draft: false
thumbnail: ./cover.jpg
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
- cloud-computing
- serverless-computing
series: effective-cloud-computing
isCJKLanguage: false
tags:
- AWS
- Amazon Redshift
- Serverless Computing
---

Serverless computing is all the rage, promising pay-as-you-go magic and freedom from infrastructure woes. But what about serverless for data warehouses? Let's delve into the fascinating (and sometimes confusing) world of **[Redshift Serverless][redshift-serverless]**: its cost structure, ideal use cases, and situations where it might not be the best fit.

## Cost Breakdown: Beyond the Illusion of Free

Redshift Serverless offers a compelling promise: only pay for what you use. But like any good magic trick, there's more to the story. Here's the primary cost breakdown:

- **Compute Units (RPUs)**: You're charged per second for used compute capacity. This is fantastic for burst workloads, but **beware of idle charges**. Even when your warehouse is inactive, the base capacity incurs costs. It's [with a 60-second minimum charge][redshift-pricing], even just one query is executed in a second in the charge period.
- **Storage**: Redshift Managed Storage (RMS) charges apply to the data you store, regardless of serverless or provisioned clusters.
- **Data Transfer**: Cross-region data sharing or accessing data from other AWS services like S3, Glue, etc outside the region attract data transfer charges.

By breaking down the cost of Redshift serverless, the RPUs usage majorly impacts the cost. Let's see a few examples of how to analyze the cost of your Redshift serverless.

Redshift serverless uses [SYS_SERVERLESS_USAGE][sys_serverless_usage] to view details of Amazon Redshift serverless usage of resources. After selecting some rows from the tables, it looks like below,

| start_time | end_time | compute_seconds | compute_capacity | data_storage | cross_region_transferred_data | charged_seconds |
|---|---|---|---|---|---|---|
| 2024-02-24 16:34:00 | 2024-02-24 16:35:00 | 62 | 8 | 31224 | 0 | 480 |
| 2024-02-24 16:33:00 | 2024-02-24 16:34:00 | 48 | 8 | 31218 | 0 | 0 |
| 2024-02-24 16:30:00 | 2024-02-24 16:31:00 | 0 | 0 | 31218 | 0 | 480 |
| 2024-02-24 16:29:00 | 2024-02-24 16:30:00 | 13 | 8 | 31217 | 0 | 0 |
| 2024-02-24 16:28:00 | 2024-02-24 16:29:00 | 0 | 0 | 31217 | 0 | 480 |
| 2024-02-24 16:27:00 | 2024-02-24 16:28:00 | 29 | 8 | 31210 | 0 | 480 |

From the above records, we know the Redshift serverless is configured with 8 RPUs (minimum RPUs). Every minute for the active Redshift serverless, 480 seconds (60 * 8 RPUs) are charged for the compute units of the Redshift serverless, though the actual usage of compute-seconds is small!

You can use the below query to view the percentage of actual computed seconds for your queries in the charged seconds.

```sql
-- query actual compute usage vs charged usage per day for Redshift Serverless running in us-west-2
select 
  DATE_TRUNC('day', start_time) AS query_day, 
  sum(compute_seconds) as used_compute_seconds, sum(charged_seconds) as charged_seconds, 2/3 as utility_percentage,
  sum(charged_seconds)*0.360/3600 as cost 
from sys_serverless_usage where CAST(start_time AS TIMESTAMP) >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY 1;
```

If you want to which queries are charged in a specific period, leverage [SYS_QUERY_HISTORY][sys_query_history] to view details of user queries. You could join those two tables to see the relationship like below example,

```sql
with query_info as (
 select
 start_time,
 end_time,
 ('[ user_id: ' || user_id || ' query_id: ' || query_id || ' transaction_id: ' || transaction_id || ' session_id: ' || session_id ||' - queries: ' || SUBSTRING(btrim(query_text), 1, 100) || ' ]') as per_query_info
 from sys_query_history where start_time ilike '%2024-02-24%'
 order by start_time
)
select
 syu.start_time,
 syu.end_time,
 compute_capacity,
 charged_seconds,
 listagg(per_query_info, ',') as queries_within
from sys_serverless_usage syu
inner join query_info sqh
on sqh.end_time <= syu.end_time
and sqh.end_time >= syu.start_time
group by 1,2,3,4;
```

By analyzing the queries, you can evaluate the performance of Redshift serverless and identify the most expensive queries for optimization.

## Use Cases: Where Serverless Shines

Redshift Serverless shines in specific scenarios:

- The intensive queries in a short period (like massive BI queries in few hours).
- Ad-hoc analytics: Need to run quick queries on your data without spinning up a cluster? Serverless is perfect.
- Dev/test environments: Test your data pipeline and queries without managing infrastructure.
- Unpredictable workloads: For workloads with variable demand, serverless scales automatically, saving you from overprovisioning costs.

## When to Say No: Serverless Isn't for Everyone

While tempting, serverless isn't always the answer. Consider these situations:

- **Long-running queries**: Serverless charges per second, making it less cost-effective for long-running queries compared to provisioned clusters. For example, streaming ingestion from Kinesis data stream or Kafka.
- **Cost-sensitive workloads**: If strict budget control is crucial, the base capacity charge and potential idle costs might outweigh the benefits.

## Conclusion: Choose Wisely

Redshift Serverless offers a powerful, flexible option for specific data warehouse needs. However, understanding its cost structure and ideal use cases is crucial to avoid surprises. Carefully evaluate your workload characteristics and budget constraints before diving in. Remember, the magic of serverless lies in using it wisely!

**Bonus Tip**: Explore hybrid approaches, combining serverless for ad-hoc queries with provisioned clusters for predictable workloads via [data sharing][data-sharing] feature.

I hope this blog post helps you navigate the world of Redshift Serverless! Do you have any questions or experiences to share? Let's discuss in the comments!

[redshift-serverless]: https://aws.amazon.com/redshift/redshift-serverless/
[redshift-pricing]: https://aws.amazon.com/redshift/pricing/
[sys_serverless_usage]: https://docs.aws.amazon.com/redshift/latest/dg/SYS_SERVERLESS_USAGE.html
[sys_query_history]: https://docs.aws.amazon.com/redshift/latest/dg/SYS_QUERY_HISTORY.html
[data-sharing]: https://aws.amazon.com/redshift/features/data-sharing/?nc=sn&loc=2&dn=4
