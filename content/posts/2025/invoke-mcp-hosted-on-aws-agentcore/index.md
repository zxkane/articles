---
title: "How invoking remote MCP servers hosted on AWS AgentCore"
description: "A comprehensive guide to connecting with MCP servers deployed on AWS AgentCore, covering OAuth authentication, client implementation, and practical usage patterns"
date: 2025-08-22
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
featured: true
codeMaxLines: 70
codeLineNumbers: true
toc: true
categories:
- blogging
isCJKLanguage: false
tags:
- MCP
- MCP Client
- AWS AgentCore Runtime
- AWS AgentCore Gateway
- OAuth
- Authentication
keywords:
- aws agentcore
- mcp servers
- oauth authentication
- bedrock agentcore
---

## Overview

Recently, I've been exploring [AWS AgentCore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)'s new capability to host [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers, and I wanted to share my experience with connecting to these remote servers as a client. The Model Context Protocol is an open standard that enables AI assistants to securely connect with external data sources and tools, and AWS AgentCore provides a managed hosting environment for these servers with built-in authentication and scaling capabilities.

In this article, I'll walk through the process of invoking MCP servers hosted on [AWS AgentCore Runtime](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html) or proxied via [AgentCore Gateway](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html), covering different authentication methods, client implementation patterns, and practical considerations. What struck me most about this approach is how it bridges the gap between local development and enterprise-grade deployment while maintaining the flexibility that makes MCP so powerful.

## Understanding AWS AgentCore and MCP

Before diving into the implementation details, let's understand what we're working with. AWS AgentCore is Amazon's managed runtime environment for AI agent applications that supports the Model Context Protocol natively. When you deploy an MCP server to AgentCore Runtime or Gateway, you get:

- **Managed Infrastructure**: No need to worry about scaling, monitoring, or infrastructure management
- **Built-in Authentication**: [OAuth 2.0](https://oauth.net/2/) and [AWS SigV4](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_aws-signing.html) authentication out of the box  
- **Session Isolation**: Each client connection gets its own isolated session
- **Serverless Scaling**: Automatically scales based on demand

The MCP servers deployed on AgentCore expose their tools and resources through a standardized HTTP interface, making them accessible from any MCP-compatible client regardless of where it's running.

## Authentication Methods

One of the first challenges I encountered was understanding the authentication options. AWS AgentCore supports several authentication mechanisms for MCP servers:

### 1. OAuth 2.0 Authentication

This is the most common approach for production deployments. The OAuth flow involves several modes:

**Manual Mode**: Interactive browser-based authentication
```python
class OAuth2Handler:
    def __init__(self, discovery_url: str, client_id: str, client_secret: str = None):
        self.discovery_url = discovery_url.rstrip('/')
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = "http://localhost:3000"
        
    async def discover_endpoints(self) -> dict:
        """Discover OAuth 2.0 endpoints using well-known configuration."""
        async with httpx.AsyncClient() as client:
            response = await client.get(self.discovery_url, timeout=10.0)
            if response.status_code == 200:
                return response.json()
            raise ValueError(f"Discovery failed: HTTP {response.status_code}")
    
    async def get_authorization_url(self) -> str:
        config = await self.discover_endpoints()
        auth_endpoint = config.get('authorization_endpoint')
        
        params = {
            'response_type': 'code',
            'client_id': self.client_id,
            'redirect_uri': self.redirect_uri,
            'scope': 'openid email aws.cognito.signin.user.admin',
            'state': 'random_state_12345'
        }
        return f"{auth_endpoint}?{urlencode(params)}"
    
    async def exchange_code_for_tokens(self, authorization_code: str) -> dict:
        config = await self.discover_endpoints()
        token_endpoint = config.get('token_endpoint')
        
        data = {
            'grant_type': 'authorization_code',
            'client_id': self.client_id,
            'code': authorization_code,
            'redirect_uri': self.redirect_uri
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(token_endpoint, data=data)
            if response.status_code == 200:
                return response.json()
            raise ValueError(f"Token exchange failed: {response.status_code}")

# Usage example
async def manual_oauth_flow():
    handler = OAuth2Handler(
        discovery_url="https://cognito-idp.us-east-1.amazonaws.com/.../openid-configuration",
        client_id="your-cognito-client-id"
    )
    
    auth_url = await handler.get_authorization_url()
    webbrowser.open(auth_url)
    
    # User completes auth and provides callback URL
    callback_url = input("Enter callback URL: ")
    code = parse_qs(urlparse(callback_url).query)["code"][0]
    
    tokens = await handler.exchange_code_for_tokens(code)
    return tokens['access_token']
```

**Machine-to-Machine Mode**: For automated systems using client credentials

```python
async def get_m2m_token(oauth_handler: OAuth2Handler) -> dict:
    """Get M2M access token using client_credentials flow."""
    config = await oauth_handler.discover_endpoints()
    token_endpoint = config.get('token_endpoint')
    
    data = {
        'grant_type': 'client_credentials',
        'client_id': oauth_handler.client_id,
        'client_secret': oauth_handler.client_secret,
    }
    
    async with httpx.AsyncClient() as client:
        response = await client.post(token_endpoint, data=data)
        if response.status_code == 200:
            return response.json()
        raise ValueError(f"M2M token request failed: {response.status_code}")

# Usage example
async def m2m_oauth_flow():
    handler = OAuth2Handler(
        discovery_url="https://cognito-idp.us-east-1.amazonaws.com/.../openid-configuration",
        client_id="your-m2m-client-id",
        client_secret="your-m2m-client-secret"
    )
    
    tokens = await get_m2m_token(handler)
    return tokens['access_token']
```

**Quick Mode**: For AWS Cognito with existing user credentials
```python
async def cognito_quick_mode(discovery_url: str, client_id: str, username: str, password: str):
    """Quick token retrieval using AWS Cognito direct authentication."""
    # Extract region from discovery URL
    region = re.search(r'cognito-idp\.([^.]+)\.amazonaws\.com', discovery_url).group(1)
    
    # Use boto3 for direct authentication
    session = boto3.Session()
    cognito_client = session.client('cognito-idp', region_name=region)
    
    response = cognito_client.initiate_auth(
        ClientId=client_id,
        AuthFlow='USER_PASSWORD_AUTH',
        AuthParameters={'USERNAME': username, 'PASSWORD': password}
    )
    
    return response['AuthenticationResult']['AccessToken']
```

### 2. AWS SigV4 Authentication

For AWS-native integrations, you can use SigV4 signing with your AWS credentials:

```python
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest

class HTTPXSigV4Auth(httpx.Auth):
    def __init__(self, credentials, service: str, region: str):
        self.credentials = credentials
        self.service = service
        self.region = region
        
    def auth_flow(self, request: httpx.Request):
        # Extract request body for signing
        body = request.content if hasattr(request, 'content') else b''
        
        # Create AWS request for signing
        aws_request = AWSRequest(method=request.method, url=str(request.url), data=body)
        aws_request.headers['Host'] = request.url.host
        
        # Sign the request
        signer = SigV4Auth(self.credentials, self.service, self.region)
        signer.add_auth(aws_request)
        
        # Update HTTPX request with signed headers
        for name, value in aws_request.headers.items():
            request.headers[name] = value
        
        yield request

class SigV4AgentCoreMCPClient:
    def __init__(self, agent_arn: str, region: str = "us-west-2"):
        self.agent_arn = agent_arn
        self.region = region
        self.session = boto3.Session()
        self.credentials = self.session.get_credentials()
        
    def get_mcp_url(self) -> str:
        encoded_arn = self.agent_arn.replace(':', '%3A').replace('/', '%2F')
        return f"https://bedrock-agentcore.{self.region}.amazonaws.com/runtimes/{encoded_arn}/invocations?qualifier=DEFAULT"
    
    async def connect(self):
        mcp_url = self.get_mcp_url()
        auth = HTTPXSigV4Auth(self.credentials, 'bedrock-agentcore', self.region)
        
        async with streamablehttp_client(url=mcp_url, auth=auth) as (read, write, _):
            async with ClientSession(read, write) as session:
                await session.initialize()
                return session

# Usage example
async def sigv4_connection_example():
    client = SigV4AgentCoreMCPClient(
        agent_arn="arn:aws:bedrock-agentcore:us-west-2:123456789012:runtime/my-server"
    )
    session = await client.connect()
    return session
```

## Client Implementation Patterns

Based on my experience, here are the key patterns I've found effective for implementing MCP clients that connect to AgentCore-hosted servers:

### Basic Client Structure

```python
async def connect_to_agentcore_server(agent_arn, bearer_token):
    # Encode the ARN for URL usage
    encoded_arn = agent_arn.replace(':', '%3A').replace('/', '%2F')
    mcp_url = f"https://bedrock-agentcore.us-west-2.amazonaws.com/runtimes/{encoded_arn}/invocations?qualifier=DEFAULT"
    
    headers = {"authorization": f"Bearer {bearer_token}"}
    
    async with streamablehttp_client(mcp_url, headers) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # Discover capabilities
            tools = await session.list_tools()
            resources = await session.list_resources()
            
            return session

# Usage
async def main():
    session = await connect_to_agentcore_server(agent_arn, bearer_token)
    result = await session.call_tool("add_numbers", {"a": 5, "b": 3})
    print(f"Result: {result}")
```

### MCP Connection Testing

Here's a simplified approach to test MCP connections:

```python
async def test_mcp_connection(mcp_server_url: str, access_token: str):
    """Test MCP connection with access token."""
    headers = {"Authorization": f"Bearer {access_token}"}
    
    async with streamablehttp_client(mcp_server_url, headers) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # List available tools and resources
            tools = await session.list_tools()
            resources = await session.list_resources()
            
            print(f"Found {len(tools.tools)} tools and {len(resources.resources)} resources")
            return session

def load_config() -> dict:
    """Load configuration from environment variables."""
    return {
        'discovery_url': os.getenv('OAUTH_DISCOVERY_URL'),
        'client_id': os.getenv('OAUTH_CLIENT_ID'),
        'agentcore_runtime_arn': os.getenv('AGENTCORE_RUNTIME_ARN'),
        'agentcore_region': os.getenv('AGENTCORE_REGION', 'us-west-2'),
    }

async def test_oauth_flow(config: dict):
    """Test OAuth flow and MCP connection."""
    # Get OAuth token
    handler = OAuth2Handler(config['discovery_url'], config['client_id'])
    auth_url = await handler.get_authorization_url()
    webbrowser.open(auth_url)
    
    # User provides callback URL
    callback_url = input("Enter callback URL: ")
    code = parse_qs(urlparse(callback_url).query)["code"][0]
    
    tokens = await handler.exchange_code_for_tokens(code)
    
    # Test MCP connection
    encoded_arn = config['agentcore_runtime_arn'].replace(':', '%3A').replace('/', '%2F')
    mcp_url = f"https://bedrock-agentcore.{config['agentcore_region']}.amazonaws.com/runtimes/{encoded_arn}/invocations?qualifier=DEFAULT"
    
    session = await test_mcp_connection(mcp_url, tokens['access_token'])
    return session
```

## Practical Usage Patterns

### Tool Discovery and Invocation

MCP enables dynamic discovery of server capabilities:

```python
async def explore_server_capabilities(session):
    # Discover available tools and resources
    tools_response = await session.list_tools()
    resources_response = await session.list_resources()
    
    for tool in tools_response.tools:
        print(f"Tool: {tool.name} - {tool.description}")
    
    for resource in resources_response.resources:
        print(f"Resource: {resource.name} ({resource.mimeType})")

async def call_tool_dynamically(session, tool_name, **kwargs):
    result = await session.call_tool(tool_name, kwargs)
    return result.content
```

### Resource Access

Access server resources with simple calls:

```python
async def read_server_resource(session, resource_uri):
    result = await session.read_resource(resource_uri)
    return result.contents

# Example usage
contents = await read_server_resource(session, "file://config.json")
for content in contents:
    print(f"{content.mimeType}: {content.text}")
```

## Complete Working Example

Here's a simplified production-ready example:

```python
async def main():
    """Main function demonstrating MCP client connection."""
    config = load_config()
    
    print("Select authentication mode:")
    print("1. OAuth 2.0 (Manual)")
    print("2. AWS Cognito (Quick)")
    print("3. AWS SigV4")
    
    choice = input("Choose (1/2/3): ")
    
    if choice == "1":
        session = await test_oauth_flow(config)
    elif choice == "2":
        token = await cognito_quick_mode(
            config['discovery_url'], 
            config['client_id'],
            config['test_username'], 
            config['test_password']
        )
        session = await test_mcp_connection(config['mcp_server_url'], token)
    elif choice == "3":
        client = SigV4AgentCoreMCPClient(config['agentcore_runtime_arn'])
        session = await client.connect()
    
    # Use the session
    tools = await session.list_tools()
    print(f"Connected! Found {len(tools.tools)} tools available.")

# Environment setup example
def setup_environment():
    """Required environment variables."""
    env_vars = {
        'OAUTH_DISCOVERY_URL': 'https://cognito-idp.us-east-1.amazonaws.com/.../openid-configuration',
        'OAUTH_CLIENT_ID': 'your-cognito-client-id',
        'AGENTCORE_RUNTIME_ARN': 'arn:aws:bedrock-agentcore:us-west-2:123456789012:runtime/my-server',
        'OAUTH_TEST_USERNAME': 'testuser@example.com',
        'OAUTH_TEST_PASSWORD': 'your-password'
    }
    
    for key, example in env_vars.items():
        print(f"export {key}='{example}'")

if __name__ == "__main__":
    asyncio.run(main())
```

## Key Learnings

### 1. Authentication Complexity

The biggest lesson from working with MCP servers on AgentCore is that authentication setup is often the most complex part. Whether you're using OAuth with Cognito, Azure AD, or other providers, getting the client credentials and discovery URLs right is crucial. I recommend starting with the manual OAuth mode for testing before moving to automated flows.

### 2. Connection Lifecycle Management

Unlike local MCP servers where you might maintain persistent connections, AgentCore-hosted servers require careful attention to connection lifecycle. The platform provides session isolation, but you need to handle reconnection gracefully in your client code.

### 3. Error Handling is Critical

Remote MCP servers introduce network-related failure modes that don't exist with local servers. Building robust retry logic and graceful degradation from the start saves significant debugging time later.

### 4. Tool Discovery Enables Dynamic Behavior

One of MCP's most powerful features is tool discovery. Rather than hard-coding tool names and parameters, building clients that dynamically discover and adapt to server capabilities makes your code much more resilient to server updates.

## Conclusion

Working with MCP servers hosted on AWS AgentCore opens up exciting possibilities for building distributed AI agent systems. The combination of MCP's flexible protocol with AgentCore's managed infrastructure provides a powerful foundation for enterprise AI applications.

The key to success lies in understanding the authentication flows, building robust connection management, and embracing MCP's dynamic discovery capabilities. While there are complexity challenges, particularly around authentication and error handling, the benefits of managed hosting and automatic scaling make this approach very compelling for production deployments.

As the ecosystem continues to mature, I expect we'll see more standardized client libraries and simplified authentication flows that make this integration even more accessible to developers.

## Resources

- [AWS AgentCore Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Amazon Bedrock AgentCore MCP Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html)
- [MCP Inspector Tool](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-using-inspector.html)
- [Sample Implementation](https://gist.github.com/zxkane/2b9d7da3cdb08b4ea91bcbc7235ef6f0)
