---
title: "Analyzing Clickstream Events Using Amazon Athena UDFs"
description : "how to use Amazon Athena User-Defined Functions (UDFs) to query raw clickstream data stored in Amazon S3"
date: 2024-08-17
lastmod: 2024-08-17
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
- effective-cloud-computing
- clickstream-analytics-on-aws
isCJKLanguage: false
tags:
- Amazon Athena
- Analytics
- Athena UDF
- Clickstream Analytics
- AWS
- AWS Lambda
---

In today's digital age, businesses are constantly seeking ways to understand and analyze user behavior on their websites. Clickstream events provide valuable insights into how users interact with a website, and analyzing this data can help businesses make informed decisions to improve user experience and drive conversions.

[Clickstream Analytics on AWS][clickstream] collects, ingests, analyzes, and visualizes clickstream events from your websites and mobile applications. The solution manages an [ingestion endpoint][ingestion-endpoint] to receive clickstream events, which are multiple events in a batch sent by the solution‘s SDKs. 

Once the ingestion endpoint receives the events, they are stored in an Amazon S3 bucket without additional processing. The bucket path is configured as a Glue table in the solution's AWS Glue Data Catalog. So the data is available for analysis using [Amazon Athena][athena].

One use case is to query and analyze the raw clickstream data to gain immediate insights after the data is stored in the S3 bucket. For example, the operators can debug the clickstream events without waiting for the data to be processed. However, the challenges of querying the raw data are:
  - the clickstream events are compressed by SDKs, so the data is not easily query-able
  - reach the Lambda payload limitation `Response payload size exceeded maximum allowed payload size (6291556 bytes)` when using Athena UDF to extract the events

In this post, I will show you how to use [Amazon Athena UDFs][athena-udf] to query the raw clickstream data to overcome the challenges.

The steps are:

1. clone repo: `https://github.com/zxkane/aws-athena-query-federation`
2. Follow [the steps][build-udf] to build and deploy the UDFs as Lambda function. After completing the deployment, find the ARN of Lambda function. Let’s say it as `clickstream-udfs`.
3. Go to the console of Glue. Run the below query to load the latest partitions of raw data.
```sql
msck repair table <your project id>.ingestion_events;
```
4. Run below sample query to view compressed data.
```sql
-- view compressed data
USING EXTERNAL FUNCTION decompress_clickstream_common_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>',
      EXTERNAL FUNCTION decompress_clickstream_attribute_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>',
      EXTERNAL FUNCTION decompress_clickstream_user_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>' 
SELECT 
    json_parse(decompress_clickstream_user_fields(data)),
    json_parse(decompress_clickstream_common_fields(data)),
    json_parse(decompress_clickstream_attribute_fields(data))
FROM "<your project id>"."ingestion_events" 
WHERE year='2024' and month='06' and day='20' and hour='02'
limit 10;

-- count the received raw events
USING EXTERNAL FUNCTION decompress_clickstream_common_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>',
      EXTERNAL FUNCTION decompress_clickstream_attribute_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>',
      EXTERNAL FUNCTION decompress_clickstream_user_fields(col1 VARCHAR) RETURNS VARCHAR LAMBDA '<your lambda arn>' 
SELECT 
    sum(json_array_length(json_parse(decompress_clickstream_common_fields(data))))
FROM "<your project id>"."ingestion_events" 
WHERE year='2024' and month='06' and day='20' and hour='02';
```

This conclusion summarizes the key benefits of using Amazon Athena UDFs for querying raw clickstream data, provides some final thoughts and considerations.

1. Immediate access to data: You can analyze clickstream events as soon as they're stored in the S3 bucket, without waiting for additional processing.
2. Debugging capabilities: Operators can quickly debug clickstream events by directly querying the raw data.
3. Overcoming compression challenges: The UDFs allow you to decompress and parse the data on-the-fly, making it easily queryable.
4. Avoiding Lambda payload limitations: By using separate UDFs for different parts of the data, you can circumvent the Lambda payload size restrictions.

[clickstream]: https://aws.amazon.com/solutions/implementations/clickstream-analytics-on-aws/
[ingestion-endpoint]: https://docs.aws.amazon.com/solutions/latest/clickstream-analytics-on-aws/ingestion-endpoint.html
[athena]: https://aws.amazon.com/athena/
[athena-udf]: https://docs.aws.amazon.com/athena/latest/ug/querying-udf.html
[build-udf]: https://github.com/zxkane/aws-athena-query-federation/tree/master/athena-udfs#deploying-the-connector