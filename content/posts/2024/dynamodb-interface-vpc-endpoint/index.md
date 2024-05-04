---
title: "Avoiding Pitfalls When Using Amazon DynamoDB Interface VPC Endpoints"
description : "Highlights the lack of Private DNS support with DynamoDB Interface VPC endpoints, requiring use of endpoint-specific DNS names/URLs to avoid connectivity issues."
date: 2024-05-04
lastmod: 2024-05-04
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
isCJKLanguage: false
tags:
- AWS
- Amazon DynamoDB
- Amazon VPC
- Tip
---

[Amazon DynamoDB now supports AWS PrivateLink][ddb-private-link-news] as of March 19, 2024. This feature allows you to securely access DynamoDB from your Amazon Virtual Private Cloud (VPC) without exposing your traffic to the public internet.

However, unlike [VPC endpoints][vpce] for other AWS managed services, the AWS PrivateLink for Amazon DynamoDB does not support the [Private DNS][vpce-private-dns] feature. This means that if your subnets are configured with only a DynamoDB Interface VPC endpoint, the public DNS name of the DynamoDB service (e.g., `dynamodb.us-east-1.amazonaws.com` in the `us-east-1` region) cannot be resolved in those subnets.

As a result, you cannot share the same code to connect to the DynamoDB endpoint via the internet or a Gateway VPC endpoint when using Interface VPC endpoints. Instead, when you create an interface endpoint, DynamoDB generates two types of endpoint-specific DNS names: Regional and zonal. You must specify your own endpoint information when creating the DynamoDB client.

```python
# replace the Region us-east-1 and VPC endpoint ID https://vpce-1a2b3c4d-5e6f.dynamodb.us-east-1.vpce.amazonaws.com with your own information.
ddb_client = session.client(
service_name='dynamodb',
region_name='us-east-1',
endpoint_url='https://vpce-1a2b3c4d-5e6f.dynamodb.us-east-1.vpce.amazonaws.com'
)
```

As an experienced AWS developer, it's easy to assume that the newly launched DynamoDB Interface VPC endpoint behaves like other AWS managed services, allowing you to continue using existing code to initialize the DynamoDB client in isolated subnets. However, this assumption would be incorrect and could lead to issues.😂😂😂

Make sure to update your application code to use the endpoint-specific DNS names or the endpoint URL when working with DynamoDB Interface VPC endpoints. You can find more examples in the [AWS documentation][sdk-examples].

[ddb-private-link-news]: https://aws.amazon.com/about-aws/whats-new/2024/03/amazon-dynamodb-aws-privatelink/
[vpce]: https://docs.aws.amazon.com/whitepapers/latest/aws-privatelink/what-are-vpc-endpoints.html#interface-endpoints
[vpce-private-dns]: https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-share-your-services.html#endpoint-service-private-dns
[sdk-examples]: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/privatelink-interface-endpoints.html#accessing-tables-apis-from-interface-endpoints
