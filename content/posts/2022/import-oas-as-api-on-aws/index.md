---
title: "Define your API via OpenAPI definition on AWS"
description : "Manage your APIs via OpenAPI specification(OAS)"
date: 2022-10-27
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
- cloud-computing
- serverless-computing
series: build-serverless-application
isCJKLanguage: false
tags:
- Serverless
- Amazon API Gateway
- OpenAPI
- OAS
- Amazon SQS
- AWS
- AWS CDK
---

Application Programming Interfaces(APIs) is a critical part of the web service, Werner Vogel, the CTO of AWS had a great
[6 Rules for Good API Design][werner-vogels-6-rules] presentation in 2021 re:Invent keynote.

In AWS the developers could manage and proxy the APIs via [Amazon API Gateway][apigateway]. The developers can use
console, CLI, API or IaC code(for example, Terraform/CloudFormation/CDK) to provisioning the API resources on AWS.
However some developers might flavor with using [OpenAPI specification][oas] to define the APIs. It enables multiple services/tools
to understand the APIs' specification, such as Postman. Amazon API Gateway supports this use case, you can import the 
existing OpenAPI definition as API.

<!--more-->

Amazon API Gateway offers two RESTful API products, [REST API][rest-api] and [HTTP API][http-api]. Both of those two APIs
support importing OpenAPI definition, but they might use different [OpenAPI extensions][openapi-extensions] to support different features.

And below example will use infrastructure as code(AWS CDK) to import the OpenAPI definition to the API Gateway APIs.
While importing OpenAPI definition, the most challenge is updating the OpenAPI definition with 
dynamic resources information(for example, IAM role for calling downstream resources of integration) before importing the OpenAPI definition.
For AWS CDK(on top of AWS CloudFormation) uses the [intrinsic functions of CloudFormation][cfn-intrinsic](`Fn::Join`) to archive it.

- REST API
```ts {hl_lines=["8-10","12"]}
    const deployOptions = {
      stageName: '',
      loggingLevel: MethodLoggingLevel.ERROR,
      dataTraceEnabled: false,
      metricsEnabled: true,
      tracingEnabled: false,
    };
    const restOpenAPISpec = this.resolve(Mustache.render(
      fs.readFileSync(path.join(__dirname, './rest-sqs.yaml'), 'utf-8'),
      variables));
    new SpecRestApi(this, 'rest-to-sqs', {
      apiDefinition: ApiDefinition.fromInline(restOpenAPISpec),
      endpointExportName: 'APIEndpoint',
      deployOptions,
    });
```

- HTTP API

~~But above solution does not work with `HTTP API`, because the CloudFormation of `HTTP API` does not support intrinsic functions of CFN. :disappointed_relieved:
The workaround is putting the OpenAPI definition to Amazon S3 firstly, then import it from S3 bucket via CloudFormation.
It involves putting the OpenAPI definition with dynamic resource information to S3 bucket before importing the OpenAPI definition from S3.
Here I leveage the CDK built-in custom resource to call S3 API to put the OpenAPI definition file to S3.~~

**22/11/09 UPDATE**: The [Body of AWS::ApiGatewayV2::Api][cfn-apiv2-body] only supports the json object. 
It works after converting the Yaml OpenAPI definition to JSON!

```ts {hl_lines=["11-12", "15"]}
const yaml = require('js-yaml');

...

    // import openapi as http api
    const variables = {
      integrationRoleArn: apiRole.roleArn,
      queueName: bufferQueue.queueName,
      queueUrl: bufferQueue.queueUrl,
    };
    const openAPISpec = this.resolve(yaml.load(Mustache.render(
      fs.readFileSync(path.join(__dirname, './http-sqs.yaml'), 'utf-8'), variables)));

    const httpApi = new CfnApi(this, 'http-api-to-sqs', {
      body: openAPISpec,
      failOnWarnings: false,
    });
```

The example code creates both `REST API` and `HTTP API`, 
both of them forwards the events to Amazon SQS queue that are sent by **HTTP POST** requests.
See [OpenAPI definition of HTTP to SQS][http-oas], [OpenAPI definition of REST to SQS][rest-oas]
or complete [source][source] for further reference.

[werner-vogels-6-rules]: https://thenewstack.io/werner-vogels-6-rules-for-good-api-design/
[oas]: https://oai.github.io/Documentation/
[apigateway]: https://aws.amazon.com/api-gateway/
[http-api]: https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api.html
[rest-api]: https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-rest-api.html
[openapi-extensions]: https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html
[cfn-intrinsic]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html
[http-oas]: https://github.com/zxkane/cdk-collections/blob/master/create-apis-from-openapi-spec/src/http-sqs.yaml
[rest-oas]: https://github.com/zxkane/cdk-collections/blob/master/create-apis-from-openapi-spec/src/rest-sqs.yaml
[source]: https://github.com/zxkane/cdk-collections/tree/master/create-apis-from-openapi-spec
[cfn-apiv2-body]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-apigatewayv2-api.html#cfn-apigatewayv2-api-body