---
title: "Protect website with Cognito"
description : "Create authentication and authorization server in minutes"
date: 2022-09-04
draft: false
thumbnail: ./cover.png
usePageBundles: true
codeMaxLines: 30
codeLineNumbers: true
categories:
- blogging
series:
- effective-cloud-computing
- serverless-computing
isCJKLanguage: false
tags:
- Serverless
- AWS
- AWS CDK
- Cognito
- Amplify
- authentication
- authorization
---

[Previous post][static-website] we demonstrated how distributing and securely deploying the website to global end users.
The authentication and authorization are always mandatory features of web application. 
[Amazon Cognito][cognito] is a managed AWS serverless service helping the applications to implement AuthN and AuthZ,
with Cognito the applications securely scales to millions of users(up to 50,000 free users)
supporting identity and access management standards, such as OAuth 2.0, SAML 2.0, and OpenID Connect.

<!--more-->

The web application uses [AWS Amplify][amplify] to integrate with AWS services, such as Cognito and API Gateway.
Below the procedures how integrating Cognito as AuthN via Amplify in Todolist project,

1. add `amplify` JS libraries into your project's dependencies
```json {hl_lines=["4-5"]}
{
  "name": "todo-list",
  "dependencies": {
    "@aws-amplify/ui-react": "^3.5.0",
    "aws-amplify": "^4.3.34",
    "axios": "^0.27.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-icons": "^4.4.0",
    "sweetalert2": "^11.4.24",
    "uuid": "^8.3.2"
  }
}
```
2. load the configuration file from server side and configure the `Amplify` categories
```jsx {hl_lines=["3-7"]}
  useEffect(() => {
    setLoadingConfig(true);
    Axios.get("/aws-exports.json").then((res) => {
      const configData = res.data;
      const tokenHeader = async () => { return { Authorization: `Bearer ${(await Auth.currentSession()).getIdToken().getJwtToken()}` }; };
      configData.API.endpoints[0].custom_header = tokenHeader;
      Amplify.configure(configData);
      apiEndpointName = configData.API.endpoints[0].name;
      setApiEndpoint(configData.API.endpoints[0].name);
      
      Hub.listen('auth', ({ payload }) => {
        const { event } = payload;
        switch (event) {
          case 'signIn':
          case 'signUp':
          case 'autoSignIn':
            getTasks();
            break;
        }
      });
      
      getTasks();
      
      setLoadingConfig(false);
    });
  }, []);
```
3. use [Authenticator component][authenticator] adding complete authentication flows with minimal boilerplate
```jsx {hl_lines=["2-3"]}
  return (
    <Authenticator components={components} loginMechanisms={['email']}>
      {({ signOut, user }) => (
        <Flex
          direction="column"
          justifyContent="flex-start"
          alignItems="center"
          alignContent="flex-start"
          wrap="nowrap"
          gap="1rem"
          textAlign="center"
        >
          <View width="100%">
            ...
          </View>
        </Flex>
      )}
    </Authenticator>    
  )
```
4. update TODO CRUD methods to use Amplify's API catagory to make HTTP requests to API Gateway
```jsx {hl_lines=["11-21"]}
  const getTasks = async () => {
    const canEnter = await ionViewCanEnter();
    if (canEnter) {
      try {
        setLoadingData(true);
        
        const initData = {
          headers: { "content-type": "application/json" }, // OPTIONAL
          response: true, // OPTIONAL (return the entire Axios response object instead of only response.data)
        };        
        API
        .get(apiEndpointName || apiEndpoint, "/todo", initData)
        .then(res => {
          setLoadingData(false);
          const tasksData = res.data;
          if ((typeof tasksData === "string")) {
            Swal.fire("Ops..", tasksData);
          } else {
            setTasks(tasksData);
          }
        })
        .catch(error => {
          setLoadingData(false);
          console.error(error);
          Swal.fire(
            `${error.message}`,
            `${error?.response?.data?.message}`,
            undefined
          );
        });
      } catch (error) {
        console.info(error);
      }
    }
  };
```

All above changes are implemented Cognito authN with the web react application.

In the server-side the Cognito user pool will be provisioned, the API Gateway endpoint is authorized by 
Cognito user pool authorizer. The Amplify configuration file `aws-exports.json` will be created on the air
when provisioning the stack with the user pool and API information.

As usual, all AWS resources are orchestrated by [AWS CDK project][example-repo], it's easliy to be deployed to any account and any region of AWS!

Happying protecting the website with Cognito :lock: :laughing::laughing::laughing:

[static-website]: {{< relref "/posts/2022/build-serverless-app-on-aws/static-website/index.md" >}}
[cognito]: https://aws.amazon.com/cognito/
[amplify]: https://aws.amazon.com/amplify/
[authoricator]: https://ui.docs.amplify.aws/react/connected-components/authenticator
[example-repo]: https://github.com/zxkane/cdk-collections/tree/master/serverlesstodo