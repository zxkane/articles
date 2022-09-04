---
title: "Build serverless web application with AWS Serverless"
description : "A complete guide builds well-architect web applications with AWS serverless"
date: 2022-08-26
draft: false
thumbnail: /posts/2022/build-serverless-app-on-aws/images/cover.png
categories:
- blogging
series:
- effective-cloud-computing
- serverless-computing
isCJKLanguage: false
tags:
- Serverless
- AWS
---

Building web application is a common use case, leveraging cloud services could accelerate
the builders to develop and deploy the services. With AWS serverless services, 
the application can easily get the capabilities like security, highly availability, 
scalability, resiliency and cost optimized.

<!--more-->

This is a series posts to demonstrate how building a serverless TODO web application on AWS with 
AWS serverless services and AWS CDK, it consists of,

- [Restful HTTP APIs][restful-api], use [Amazon API Gateway][api-gateway] and [Amazon DynamoDB][dynamodb]
- Securely and accelerately [distribute the static website][static-website] via [Amazon CloudFront][cloudfront] and [Amazon S3][s3]
- [Authentication and Authorization][web-authn] via [Amazon Cognito][cognito] and [AWS Amplify][amplify]
- OIDC federation authentication with [Amazon Cognito][cognito]
- CI/CD DevOps pipeline
- [source code][repo] written by [AWS CDK][cdk] to archive above features

[restful-api]: {{< relref "/posts/2022/build-serverless-app-on-aws/restful-api/index.md" >}}
[static-website]: {{< relref "/posts/2022/build-serverless-app-on-aws/static-website/index.md" >}}
[web-authn]: {{< relref "/posts/2022/build-serverless-app-on-aws/protect-website-with-cognito/index.md" >}}
[api-gateway]: https://aws.amazon.com/api-gateway/
[dynamodb]: https://aws.amazon.com/dynamodb/
[cognito]: https://aws.amazon.com/cognito/
[cloudfront]: https://aws.amazon.com/cloudfront/
[s3]: https://aws.amazon.com/s3/
[amplify]: https://aws.amazon.com/amplify/
[cdk]: https://aws.amazon.com/cdk/
[repo]: https://github.com/zxkane/cdk-collections/tree/master/serverlesstodo