---
title: "Build no code restful HTTP API with API Gateway and DynamoDB"
description : "Build no code CRUD restful APIs"
date: 2022-08-27
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 30
codeLineNumbers: true
categories:
- blogging
- cloud-computing
series: build-serverless-application
isCJKLanguage: false
tags:
- Serverless
- AWS
- API Gateway
- DynamoDB
- AWS CDK
---

Most web applications are using [Restful APIs][rest] to interactive with the backend services.
In the TODO application, it's the straight forward to get, update and delete the items from backend database.
[Amazon DynamoDB][dynamodb] is a key-value database, it fits for this scenario with scalability and optimized pay-as-you-go cost.
Also [Amazon API Gateway][api-gateway] has built-in integration with AWS serivces, the restful API can be transformed to 
the request to DynamoDB APIs. Using this combination you can provide the restful APIs only provisioning AWS resources
without writing the CRUD code!

<!--more-->

Let's assume the TODO application having below model to represent the TODO items,

```json
{
"subject": "my-memo", // some subject of TODO item
"description": "the great idea", // some description for the TODO item
"dueDate": 1661926828, // the timestamp of sceonds for the due date of TODO item
}
```

Then define below restful APIs for list, fetch, update and delete TODO item/items.

- Create new TODO item
```bash
PUT /todo
```
- Update a TODO item
```bash
POST /todo/<todo id>
```
- Delete a TODO item
```bash
DELETE /todo/<todo id>
```
- List TODO items
```bash
GET /todo
```

All magic with no code restful API of API Gateway is [setting up data transformations for REST API][data-transformation].

Belos is using the [Apache VTL][apache-vtl] to transform the request JSON payload to [DynamoDB UpdateItem][ddb-updateitem] API request.

{{< gist zxkane 2390e1acfb2a9168bb2aa0cd58b5ac45 "put-todo-model.json" >}}

{{< gist zxkane 2390e1acfb2a9168bb2aa0cd58b5ac45 "put-todo.vtl" >}}

Also using API Gateway's transformation feature of the response of integration(DynamoDB API in this case) to shape the response like below,

{{< gist zxkane 2390e1acfb2a9168bb2aa0cd58b5ac45 "todo-response.vtl" >}}

There are few best practise of using API Gateway and AWS services integration to simplify the CRUD operations,

- use request validator to validate the request payload
- use integration response to handle with the error cases of integration services. 
Below is an example checking the error message of DynamoDB API then reshape the error message
```vtl
#if($input.path('$.__type') == "com.amazonaws.dynamodb.v20120810#ConditionalCheckFailedException")
{
  "message": "the todo id already exists."
}
#end
```
- sanity all string inputs from client via API Gateway built-in [$util method][util-template-reference] `$util.escapeJavaScript()`
to avoid NoSQL injection attack
- response valid json if the string contains signle quotes(')
```vtl
"subject": "$util.escapeJavaScript($input.path('$.Attributes.subject.S')).replaceAll(\"\\\\'\",\"'\")"
```

As usual, all AWS resources are orchestrated by [AWS CDK project][example-repo], it's easliy to be deployed to any account and any region of AWS!

Happying 👨‍💻 API :laughing::laughing::laughing:

[rest]: https://en.wikipedia.org/wiki/Representational_state_transfer
[lambda]: https://aws.amazon.com/lambda/
[api-gateway]: https://aws.amazon.com/api-gateway/
[dynamodb]: https://aws.amazon.com/dynamodb/
[data-transformation]: https://docs.aws.amazon.com/apigateway/latest/developerguide/rest-api-data-transformations.html
[apache-vtl]: https://velocity.apache.org/engine/2.0/vtl-reference.html
[ddb-updateitem]: https://docs.aws.amazon.com/amazondynamodb/latest/APIReference/API_UpdateItem.html
[util-template-reference]: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html#util-template-reference
[example-repo]: https://github.com/zxkane/cdk-collections/tree/master/serverlesstodo