---
title: "Custom compliance implementation in AWS CDK"
description : "Use aspects and escape hatches empower your CDK application"
date: 2024-01-09
lastmod: 2024-01-09
draft: false
thumbnail: "https://miro.medium.com/max/680/1*bnmfpzoIBkPe3PfuunfIZQ.png"
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
categories:
- blogging
isCJKLanguage: false
tags:
- AWS
- AWS CDK
- AWS Lambda
- Tips
---
[AWS CDK][cdk] accelerates cloud development using common programming languages to model your applications. I had a series of posts using CDK to demonstrate [Building serverless web applications with AWS Serverless][serverless-app]. Because CDK uses a programming language to model your application, you can encapsulate your library via [Constructs][contructs], and then reuse it crossing the entire application. 

Meanwhile, you can create your own constructs to encapsulate the compliance requirements to simplify the code. For example, in our solution, I used the construct `SolutionFunction` to force using the same Node.js version(18.x), architecture(ARM64), Lambda logging configuration(JSON log), environment variables for [Powertools Logger][powertools-logger] and so on crossing all `NodejsFunction`. In addition, using [Aspects] and [escape hatches][escape-hatches] to make sure the application meets the compliance requirements.

Let's deep dive into how to make all Nodejs Lambda functions compliant with the above requirements.

Firstly, define the `SolutionFunction` for making a generic configuration of solutions's Nodejs Lambda,

{{< highlight typescript "hl_lines=12-20">}}
export class SolutionNodejsFunction extends NodejsFunction {

  constructor(scope: Construct, id: string, props?: NodejsFunctionProps) {
    super(scope, id, {
      ...props,
      bundling: props?.bundling ? {
        ...props.bundling,
        externalModules: props.bundling.externalModules?.filter(p => p === '@aws-sdk/*') ?? [],
      } : {
        externalModules: [],
      },
      runtime: Runtime.NODEJS_18_X,
      architecture: Architecture.ARM_64,
      environment: {
        ...POWERTOOLS_ENVS,
        ...(props?.environment ?? {}),
      },
      logRetention: props?.logRetention ?? RetentionDays.ONE_MONTH,
      logFormat: 'JSON',
      applicationLogLevel: props?.applicationLogLevel ?? 'INFO',
    });
  }
}
{{< /highlight >}}

Then, add an `Aspect` to the application to make sure the `NodejsFunction` functions are an instance of `SolutionFunction`.

```typescript {hl_lines=["5-7",14]}
class NodejsFunctionSanityAspect implements IAspect {

  public visit(node: IConstruct): void {
    if (node instanceof NodejsFunction) {
      if (!(node instanceof SolutionNodejsFunction)) {
        Annotations.of(node).addError('Directly using NodejsFunction is not allowed in the solution. Use SolutionNodejsFunction instead.');
      }
      if (node.runtime != Runtime.NODEJS_18_X) {
        Annotations.of(node).addError('You must use Nodejs 18.x runtime for Lambda with javascript in this solution.');
      }
    }
  }
}
Aspects.of(app).add(new NodejsFunctionSanityAspect());
```

The above code snippets help us to archive the compliance of Nodejs Lambda functions without modifying tens or hundreds of occurrences one by one.

However, due to service availability, the ARM64 architect and JSON log Lambda function are not available in the AWS China partition. Also, using another `Aspect` with `escape hatches` to override the attributes with conditional values.

```typescript {hl_lines=["8-22"]}
class CNLambdaFunctionAspect implements IAspect {

  private conditionCache: { [key: string]: CfnCondition } = {};

  public visit(node: IConstruct): void {
    if (node instanceof Function) {
      const func = node.node.defaultChild as CfnFunction;
      if (func.loggingConfig) {
        func.addPropertyOverride('LoggingConfig',
          Fn.conditionIf(this.awsChinaCondition(Stack.of(node)).logicalId,
            Fn.ref('AWS::NoValue'), {
              LogFormat: (func.loggingConfig as CfnFunction.LoggingConfigProperty).logFormat,
              ApplicationLogLevel: (func.loggingConfig as CfnFunction.LoggingConfigProperty).applicationLogLevel,
              LogGroup: (func.loggingConfig as CfnFunction.LoggingConfigProperty).logGroup,
              SystemLogLevel: (func.loggingConfig as CfnFunction.LoggingConfigProperty).systemLogLevel,
            }));
      }
      if (func.architectures && func.architectures[0] == Architecture.arm64) {
        func.addPropertyOverride('Architectures',
          Fn.conditionIf(this.awsChinaCondition(Stack.of(node)).logicalId,
            Fn.ref('AWS::NoValue'), func.architectures));
      }
    }
  }

  private awsChinaCondition(stack: Stack): CfnCondition {
    const conditionName = 'AWSCNCondition';
    // Check if the resource already exists
    const existingResource = this.conditionCache[stack.artifactId];

    if (existingResource) {
      return existingResource;
    } else {
      const awsCNCondition = new CfnCondition(stack, conditionName, {
        expression: Fn.conditionEquals('aws-cn', stack.partition),
      });
      this.conditionCache[stack.artifactId] = awsCNCondition;
      return awsCNCondition;
    }
  }
}
Aspects.of(app).add(new CNLambdaFunctionAspect());
```

Alright, using the above two aspects forces the solution to meet the compliance requirements of Lambda functions with the same runtime version, architecture, and logger configuration. :star_struck: :smile: :star_struck:

[cdk]: https://aws.amazon.com/cdk/?nc1=h_ls
[serverless-app]: {{< relref "/posts/2022/build-serverless-app-on-aws/intro/index.md" >}}
[contructs]: https://docs.aws.amazon.com/cdk/v2/guide/constructs.html
[powertools-logger]: https://docs.powertools.aws.dev/lambda/typescript/latest/core/logger/
[aspects]: https://docs.aws.amazon.com/cdk/v2/guide/aspects.html
[escape-hatches]: https://docs.aws.amazon.com/cdk/v2/guide/cfn_layer.html
