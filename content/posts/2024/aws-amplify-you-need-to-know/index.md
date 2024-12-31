---
title: "Nine Essential Tips of AWS Amplify for Boosting Development Productivity"
description: "Master AWS Amplify with these essential tips covering authentication, infrastructure management, GenAI integration, and CI/CD deployment - everything you need to build modern serverless applications."
date: 2024-12-24
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 70
codeLineNumbers: true
toc: true
categories:
- blogging
- serverless-computing
isCJKLanguage: false
featured: true
tags:
- AWS
- AWS Amplify
- Amazon Bedrock
- AWS AppSync
- AWS Cognito
- LLM
- Claude
- Serverless
- Fullstack
- GenAI
---

AWS Amplify is a powerful set of tools and services for developing, hosting, and managing serverless applications. With the recent launch of Amplify Gen 2[^1][^2], the platform has evolved significantly to enhance the developer experience. In this guide, we'll explore nine essential tips that will help you maximize your productivity with AWS Amplify, covering everything from authentication and infrastructure management to AI integration and deployment.

## Understanding Amplify Gen 2

Before diving into the tips, let's understand what makes Amplify Gen 2 special. It introduces a code-first developer experience that enables building fullstack applications using TypeScript. Key benefits include:

- TypeScript-first backend development
- Faster local development with cloud sandbox environments
- Improved team workflows with fullstack Git branches
- Unified management console
- Enhanced integration with AWS CDK

## Tip 1: Implementing Third-Party Authentication

AWS Amplify provides seamless integration with popular authentication providers like Google, Facebook, and Amazon. You can also leverage any service supporting industry-standard protocols like OpenID Connect (OIDC) or SAML. While the built-in [Authenticator component][authenticator] doesn't directly support third-party provider customization, you can achieve this through [Header and Footer customization][headers-and-footers].

{{< highlight tsx "hl_lines=12-15" >}}
<Authenticator
  components={{
    Header: SignInHeader,
    SignIn: {
      Header() {
        return (
          <div className="px-8 py-2">
            <Flex direction="column"
                  className="federated-sign-in-container">
                  <Button
                    onClick={async () => {
                      await signInWithRedirect({
                        provider: {
                          custom: 'OIDC-Provider' // OIDC Provider name created in Cognito User Pool
                        }
                      });
                    }}
                    className="federated-sign-in-button"
                    gap="1rem"
                  >
                    <svg
                      xmlns="http://www.w3.org/2000/svg"
                      fill="#000"
                      version="1.1"
                      viewBox="0 0 32 32"
                      xmlSpace="preserve"
                      className="amplify-icon federated-sign-in-icon"
                    >
                      <path
                        d="M31 31.36H1v-.72h30v.72zm0-7H1A.36.36 0 01.64 24V1A.36.36 0 011 .64h30a.36.36 0 01.36.36v23a.36.36 0 01-.36.36zm-29.64-.72h29.28V1.36H1.36v22.28zm7.304-7.476c-.672 0-1.234-.128-1.687-.385s-.842-.6-1.169-1.029l.798-.644c.28.355.593.628.938.819.345.191.747.287 1.204.287.476 0 .847-.103 1.113-.308.266-.206.399-.495.399-.868 0-.28-.091-.52-.273-.721-.182-.201-.511-.338-.987-.414l-.574-.084a4.741 4.741 0 01-.924-.217c-.28-.098-.525-.229-.735-.392s-.374-.366-.49-.609a1.983 1.983 0 01-.175-.868c0-.354.065-.665.196-.931.13-.266.31-.488.539-.665s.501-.311.819-.399a3.769 3.769 0 011.022-.133c.588 0 1.08.103 1.477.308.396.206.744.49 1.043.854l-.742.672c-.159-.224-.392-.427-.7-.609-.308-.182-.695-.272-1.162-.272s-.819.1-1.057.3c-.238.201-.357.474-.357.819 0 .354.119.611.357.77.238.159.581.275 1.029.35l.56.084c.803.122 1.372.353 1.708.693.336.341.504.786.504 1.337 0 .7-.238 1.251-.714 1.652-.476.402-1.13.603-1.96.603zm6.733 0c-.672 0-1.234-.128-1.687-.385s-.842-.6-1.169-1.029l.798-.644c.28.355.593.628.938.819.345.191.747.287 1.204.287.476 0 .847-.103 1.113-.308.266-.206.399-.495.399-.868 0-.28-.091-.52-.273-.721-.182-.201-.511-.338-.987-.413l-.574-.084c-.336-.046-.644-.119-.924-.217s-.525-.229-.735-.392-.374-.366-.49-.609a1.983 1.983 0 01-.175-.868c0-.354.065-.665.196-.931.13-.266.31-.488.539-.665.229-.177.501-.311.819-.399a3.769 3.769 0 011.022-.133c.588 0 1.08.103 1.477.308.396.206.744.49 1.043.854l-.742.672c-.158-.224-.392-.427-.7-.609s-.695-.273-1.162-.273-.819.101-1.057.301c-.238.201-.357.474-.357.819 0 .354.119.611.357.77s.581.275 1.029.35l.56.084c.803.122 1.372.353 1.708.693.337.341.505.786.505 1.337 0 .7-.238 1.251-.715 1.652-.475.401-1.129.602-1.96.602zm7.378 0c-.485 0-.929-.089-1.33-.266s-.744-.432-1.028-.763a3.584 3.584 0 01-.665-1.19 4.778 4.778 0 01-.238-1.561c0-.569.079-1.087.238-1.554a3.56 3.56 0 01.665-1.197c.284-.332.627-.586 1.028-.763s.845-.266 1.33-.266.927.089 1.323.266.739.432 1.029.763c.289.331.513.73.672 1.197.158.467.238.985.238 1.554 0 .579-.08 1.099-.238 1.561a3.546 3.546 0 01-.672 1.19c-.29.331-.633.585-1.029.763a3.19 3.19 0 01-1.323.266zm0-.995c.606 0 1.102-.187 1.484-.56.383-.373.574-.942.574-1.708v-1.036c0-.765-.191-1.334-.574-1.708s-.878-.56-1.484-.56-1.102.187-1.483.56c-.383.374-.574.943-.574 1.708v1.036c0 .766.191 1.335.574 1.708.382.374.877.56 1.483.56z"></path>
                      <path fill="none" d="M0 0H32V32H0z"></path>
                    </svg>
                    <span style={{color: "white !important"}}>Sign In with My OIDC Provider</span>
                  </Button>
                <Divider label="or" size="small"/>
            </Flex>
          </div>
        );
      }
    }
  }}
  loginMechanisms={['email']}
  signUpAttributes={['email']}
  initialState="signIn"
  hideSignUp={true}
/>
{{< /highlight >}}

## Tip 2: Building Passwordless Authentication

[Amazon Cognito now supports passwordless authentication][cognito-passwordless], including sign-in with passkeys, email, and text messages. While the Authenticator component doesn't natively support these features, you can create a custom authentication experience using the Amplify JS library.

{{< highlight tsx "hl_lines=20-29" >}}
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { signIn, confirmSignIn, fetchUserAttributes } from 'aws-amplify/auth';
import { TextField, Button, CircularProgress, Alert } from '@mui/material';

export default function Home() {
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [showConfirmation, setShowConfirmation] = useState(false);
  const router = useRouter();

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      const { nextStep } = await signIn({
        username: email,
        options: {
          authFlowType: 'USER_AUTH',
          preferredChallenge: 'EMAIL_OTP',
        },
      });
      if (nextStep.signInStep === 'CONFIRM_SIGN_IN_WITH_EMAIL_CODE' ||
        nextStep.signInStep === 'CONTINUE_SIGN_IN_WITH_FIRST_FACTOR_SELECTION'
      ) {
        setShowConfirmation(true);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Sign in failed');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const { nextStep: confirmSignInNextStep } = await confirmSignIn({ challengeResponse: code });

      if (confirmSignInNextStep.signInStep === 'DONE') {
      const attributes = await fetchUserAttributes();
      if (attributes.email) {
        router.push('/home');
      }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Confirmation failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="w-full max-w-md p-6">
        <div className="text-center mb-8">
          <h1 className="text-2xl font-bold mb-2">Sign in to My App</h1>
          <p className="text-gray-600">
            {showConfirmation ? 'Enter the code sent to your email' : 'Enter your email to receive a code'}
          </p>
        </div>

        {error && (
          <Alert severity="error" className="mb-4">
            {error}
          </Alert>
        )}

        {!showConfirmation ? (
          <form onSubmit={handleSignIn}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              disabled={loading}
              required
              className="mb-4"
            />
            <Button
              fullWidth
              variant="contained"
              type="submit"
              disabled={loading}
              className="mt-2"
            >
              {loading ? <CircularProgress size={24} /> : 'Continue'}
            </Button>
          </form>
        ) : (
          <form onSubmit={handleConfirmSignIn}>
            <TextField
              fullWidth
              label="Verification Code"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              disabled={loading}
              required
              className="mb-4"
            />
            <Button
              fullWidth
              variant="contained"
              type="submit"
              disabled={loading}
              className="mt-2"
            >
              {loading ? <CircularProgress size={24} /> : 'Verify'}
            </Button>
          </form>
        )}
      </div>
    </div>
  );
}
{{< /highlight >}}

## Tip 3: Managing Backend Access with ID Tokens

When working with authenticated users, proper token management is crucial. While Amplify automatically handles access tokens for data API requests, some scenarios require manual token management for accessing user attributes in your backend services.

{{< highlight tsx "hl_lines=10-12" >}}
import { fetchAuthSession } from 'aws-amplify/auth';

const session = await fetchAuthSession();
if (!session.tokens?.idToken) throw new Error('User not signed in');

await client.mutations.action({
  ...formData,
}, {
  authMode: 'userPool',
  headers: {
    'Authorization': session.tokens.idToken.toString(),
  }
});
{{< /highlight >}}

In the backend, you can use the email attribute of the user like below if you are using AppSync JS resolver:
{{< highlight js "hl_lines=4" >}}
import { util } from '@aws-appsync/utils';

export function request(ctx) {
  const owner = ctx.identity.claims.email || ctx.identity.username;
}

export function response(ctx) {
  return ctx.result;
} 
{{< /highlight >}}

## Tip 4: Mastering UI Development

[Amplify UI provides a rich set of components][amplify-ui-components] designed for seamless integration. Learn how to maintain a consistent look and feel when combining Amplify UI with other popular libraries like [Material-UI (MUI)][mui].

{{< highlight tsx "hl_lines=47-55" >}}
import { ThemeProvider, createTheme, defaultDarkModeOverride } from '@aws-amplify/ui-react';
import { styled, ThemeProvider as MUIThemeProvider, createTheme } from '@mui/material/styles';

const theme = createTheme({
    name: 'christmas-theme',
    tokens: {
      colors: {
        background: {
          primary: { value: '#FFFFFF' },   // Snow white background
          secondary: { value: '#165B33' }, // Christmas green
        },
      },
      components: {
        button: {
          primary: {
            backgroundColor: { value: '#CC231E' },
            color: { value: '#FFFFFF' },
            _hover: {
              backgroundColor: { value: '#165B33' },
            },
          },
        },
      },
    },
    overrides: [defaultDarkModeOverride]
});

const muiTheme = createTheme({
  palette: {
    primary: {
      main: theme.tokens.colors.font.interactive.value,
    },
  },
});

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.className}>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </head>
      <body>
        <ThemeProvider theme={theme}>
          <AmplifyProvider>
            <main className="min-h-screen">
              <MUIThemeProvider theme={muiTheme}>
                {children}
              </MUIThemeProvider>
            </main>
          </AmplifyProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
{{< /highlight >}}

## Tip 5: Extending Infrastructure with CDK

For complex backend requirements, AWS CDK enables powerful customization of your [Amplify backend][amplify-data-backend]. This allows you to manage all types of AWS resources while benefiting from the extensive CDK construct ecosystem.

{{< highlight ts >}}
(backend.leagueHandler.resources.lambda.node.defaultChild as CfnFunction).addPropertyOverride('LoggingConfig', {
  LogFormat: 'JSON',
  ApplicationLogLevel: process.env.PRODUCTION ? 'WARN' : 'TRACE',
  SystemLogLevel: 'INFO',
});
{{< /highlight >}}

## Tip 6: Optimizing DynamoDB Access

Learn how to handle common challenges like circular dependencies when accessing DynamoDB tables from Lambda resolvers in your [Amplify-generated AppSync API][amplify-data]. You can access user identity information in your resolvers using [AppSync identity context][appsync-identity].

{{< highlight ts >}}
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { data, leagueHandler } from './data/resource';
export const backend = defineBackend({
  auth,
  data,
  leagueHandler,
});

const externalTableStack = backend.createStack('ExternalTableStack');

const leagueTable = new Table(externalTableStack, 'League', {
  partitionKey: {
    name: 'id',
    type: AttributeType.STRING
  },
  billingMode: BillingMode.PAY_PER_REQUEST,
  removalPolicy: RemovalPolicy.DESTROY,
});

backend.data.addDynamoDbDataSource(
  "ExternalLeagueTableDataSource",
  leagueTable as any
);

leagueTable.grantReadWriteData(backend.leagueHandler.resources.lambda);
(backend.leagueHandler.resources.lambda as NodejsFunction).addEnvironment('LEAGUE_TABLE_NAME', leagueTable.tableName);
{{< /highlight >}}
declare the DynamoDB table outside of generated Amplify stack in `amplify/backend.ts`
{{< highlight ts >}}
const schema = a.schema({
  League: a.customType({
    id: a.string().required(),
    leagueCountry: a.ref('LeagueCountry'),
    teams: a.ref('Team').array(),
    season: a.integer(),
  }),
});
{{< /highlight >}}
Declare the DynamoDB schema as a custom type for AppSync in `amplify/data/resource.ts`, see [here][amplify-connect-ddb] for more details.

## Tip 7: Building Resilient AI Features

Improve your application's reliability by implementing cross-region model inference with the [Amplify AI Kit][ai-kit]. While not supported out-of-the-box, you can achieve this using CDK Interoperability.

Hack the role of Lambda function for `conversation` and AppSync resolver role for `generate` in `amplify/backend.ts`
{{< highlight ts >}}
function createBedrockPolicyStatement(currentRegion: string, accountId: string, modelId: string, crossRegionModel: string) {
  return new PolicyStatement({
    resources: [
      `arn:aws:bedrock:*::foundation-model/${modelId}`,
      `arn:aws:bedrock:${currentRegion}:${accountId}:inference-profile/${crossRegionModel}`,
    ],
    actions: ['bedrock:InvokeModel*'],
  });
}

if (CROSS_REGION_INFERENCE && CUSTOM_MODEL_ID) {
  const currentRegion = getCurrentRegion(backend.stack);
  const crossRegionModel = getCrossRegionModelId(currentRegion, CUSTOM_MODEL_ID);
  
  // [chat converstation]
  const chatStack = backend.data.resources.nestedStacks?.['ChatConversationDirectiveLambdaStack'];
  if (chatStack) {
    const conversationFunc = chatStack.node.findAll()
      .find(child => child.node.id === 'conversationHandlerFunction') as IFunction;

    if (conversationFunc) {
      conversationFunc.addToRolePolicy(
        createBedrockPolicyStatement(currentRegion, backend.stack.account, CUSTOM_MODEL_ID, crossRegionModel)
      );
    }
  }

  // [insights generation]
  const insightsStack = backend.data.resources.nestedStacks?.['GenerationBedrockDataSourceGenerateInsightsStack'];
  if (insightsStack) {
    const dataSourceRole = insightsStack.node.findChild('GenerationBedrockDataSourceGenerateInsightsIAMRole') as IRole;
    if (dataSourceRole) {
      dataSourceRole.attachInlinePolicy(
        new Policy(insightsStack, 'CrossRegionInferencePolicy', {
          statements: [
            createBedrockPolicyStatement(currentRegion, backend.stack.account, CUSTOM_MODEL_ID, crossRegionModel)
          ],
        }),
      );
    }
  }
}
{{< /highlight >}}

Specify the model ID in `amplify/data/resource.ts`
{{< highlight ts "hl_lines=3-4 21-22" >}}
const schema = a.schema({
  generateInsights: a.generation({
    aiModel: CROSS_REGION_INFERENCE ? {
      resourcePath: getCrossRegionModelId(getCurrentRegion(undefined), CUSTOM_MODEL_ID!),
     } : a.ai.model(LLM_MODEL),
    systemPrompt: LLM_SYSTEM_PROMPT,
    inferenceConfiguration: {
      maxTokens: 1000,
      temperature: 0.65,
    },
  })
  .arguments({
    requirement: a.string().required(),
    })
    .returns(a.customType({
      insights: a.string().required(),
    }))
    .authorization(allow => [allow.authenticated()]),

  chat: a.conversation({
    aiModel: CROSS_REGION_INFERENCE ? {
      resourcePath: getCrossRegionModelId(getCurrentRegion(undefined), CUSTOM_MODEL_ID!),
     } : a.ai.model(LLM_MODEL),
    systemPrompt: FOOTBALL_SYSTEM_PROMPT,
  }).authorization(allow => allow.owner()),
});
{{< /highlight >}}

## Tip 8: Creating Sophisticated Chat Interfaces

The [AIConversation component][ui-ai-conversation] provides a flexible foundation for building chat applications. Master state management and user context handling for multiple conversations.

{{< highlight tsx >}}
import { useState } from 'react';
import { Fab, Paper, IconButton, Box, Tooltip, Typography } from '@mui/material';
import { AIConversation } from '@aws-amplify/ui-react-ai';
import { Avatar } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import { generateClient } from 'aws-amplify/data';
import { createAIHooks } from '@aws-amplify/ui-react-ai';
import { type Schema } from '../../amplify/data/resource';
import ReactMarkdown from 'react-markdown';

const client = generateClient<Schema>({ authMode: 'userPool' });
const { useAIConversation } = createAIHooks(client);

interface ChatBotProps {
  chatId?: string;
  refreshKey: number;
  onStartNewChat: () => void;
  onLoadConversations: () => void;
  isLoading: boolean;
}

export default function ChatBot({ 
  chatId,
  refreshKey,
  onStartNewChat,
  onLoadConversations,
  isLoading 
}: ChatBotProps) {
  const [open, setOpen] = useState(refreshKey > 0);
  const [position, setPosition] = useState({ x: 0, y: 0 });

  const conversation = useAIConversation('chat', {
    id: chatId,
  });
  const [{ data: { messages }, isLoading: isLoadingChat }, sendMessage] = conversation;
  
  const handleOpen = () => {
    setOpen(true);
    onLoadConversations();
  };

  const handleClose = () => setOpen(false);

  const handleNewChat = () => {
    // Reset conversation and create new chat
    onStartNewChat();
  };

  return (
<Box sx={{ flexGrow: 1, overflow: 'hidden' }}>
  <AIConversation
    key={chatId}
    allowAttachments
    messages={messages}
    handleSendMessage={sendMessage}
    isLoading={isLoadingChat || isLoading}
    avatars={{
      user: {
        avatar: <Avatar size="small" alt={email} />,
        username: 'People'
      },
      ai: {
        avatar: <Avatar size="small" alt="AI" />,
        username: 'Chat Bot'
      }
    }}
    messageRenderer={{
      text: ({ text }) => <ReactMarkdown>{text}</ReactMarkdown>,
    }}
  />
</Box>
  );
}
{{< /highlight >}}

## Tip 9: Streamlining Deployment Debugging

When troubleshooting deployment issues in Amplify Hosting, leverage the `--debug` flag for deeper insights into pipeline failures, especially when code works in sandbox but fails in production.

{{< highlight yaml "hl_lines=9" >}}
version: 1
backend:
  phases:
    build:
      commands:
        - nvm install 20
        - nvm use 20
        - npm ci --cache .npm --prefer-offline
        - npx ampx pipeline-deploy --branch $AWS_BRANCH --app-id $AWS_APP_ID --debug
frontend:
  phases:
    preBuild:
      commands:
        - nvm install 20
        - nvm use 20
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - .next/cache/**/*
      - .npm/**/*
{{< /highlight >}}

## Conclusion

AWS Amplify Gen 2 represents a significant evolution in fullstack development on AWS, offering a developer experience comparable to platforms like Vercel with Next.js. These tips will help you leverage Amplify's generated services alongside CDK's powerful constructs to build sophisticated serverless applications efficiently. The platform's seamless integration with the AWS ecosystem makes it an excellent choice for teams looking to accelerate their development process while maintaining enterprise-grade quality and scalability.

[^1]: [Introducing the Next Generation of AWS Amplify's Fullstack Development Experience](https://aws.amazon.com/blogs/mobile/introducing-amplify-gen2/)
[^2]: [Fullstack TypeScript: Reintroducing AWS Amplify](https://aws.amazon.com/blogs/mobile/amplify-gen2-ga/)

[authenticator]: https://ui.docs.amplify.com/components/authenticator
[headers-and-footers]: https://ui.docs.amplify.aws/react/connected-components/authenticator/customization#headers--footers
[cognito-passwordless]: https://aws.amazon.com/about-aws/whats-new/2024/11/amazon-cognito-passwordless-authentication-low-friction-secure-logins/
[amplify-data]: https://docs.amplify.aws/react/build-a-backend/data/
[appsync-identity]: https://docs.aws.amazon.com/appsync/latest/devguide/resolver-context-reference-js.html#aws-appsync-resolver-context-reference-identity-js
[amplify-ui-components]: https://ui.docs.amplify.aws/react/components
[mui]: https://mui.com/material-ui/getting-started/
[amplify-data-backend]: https://docs.amplify.aws/vue/build-a-backend/data/set-up-data/#building-your-data-backend
[amplify-connect-ddb]: https://docs.amplify.aws/vue/build-a-backend/data/connect-to-existing-data-sources/connect-external-ddb-table/
[ai-kit]: https://docs.amplify.aws/react/ai/
[ui-ai-conversation]: https://docs.amplify.aws/react/ai/conversation/ai-conversation/