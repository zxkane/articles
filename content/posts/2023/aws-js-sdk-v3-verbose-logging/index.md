---
title: "Verbose logging for AWS JS SDK v3"
description : "A tip for debugging your AWS API calls"
date: 2023-09-10
draft: false
thumbnail: ./cover.jpg
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
isCJKLanguage: false
tags:
- AWS JS SDK
- Tip
- AWS
---
When programming with the AWS SDK, developers sometimes want to debug a specific HTTP request when invoking an SDK API. Due to the [poor documentation][sdk-v3-logger-options] of AWS JS SDK v3, it takes a lot of work to find a way to print the verbose logging of AWS SDK by asking it to the LLMs.

Below is a practical tip for enabling verbose logging for AWS JS SDK v3.

### Solution 1 - specify a custom logger for AWS SDK clients

{{< highlight typescript >}}
import { DescribeParametersCommand, SSMClient } from "@aws-sdk/client-ssm";
import * as log4js from "log4js";

log4js.configure({
  appenders: { out: { type: "stdout" } },
  categories: { default: { appenders: ["out"], level: "debug" } },
});

const logger = log4js.getLogger();

const ssmClient = new SSMClient({
  logger: logger,
});
{{< /highlight >}}

### Solution 2 - use middleware to hook the life cyele of request

{{< highlight typescript >}}
import { DescribeParametersCommand, SSMClient } from "@aws-sdk/client-ssm";

const logRequestMiddleware = (next: any, _context: any) => async (args: any) => {
  console.log('Request:', args.request);
  return next(args);
};

const ssmClient = new SSMClient({
});

ssmClient.middlewareStack.add(logRequestMiddleware, { step: 'finalizeRequest' });
{{< /highlight >}}

See complete working example gist below,

{{< gist zxkane dcd36bc9886809ddeb9a427500bb8b7c "aws-sdk-v3-custom-logger.ts" >}}

[sdk-v3-logger-options]: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/Package/-aws-sdk-types/Interface/LoggerOptions/
[middleware-stack]: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/Package/-smithy-middleware-stack/