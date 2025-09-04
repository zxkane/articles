---
title: "Leveraging MCP Client's OAuthClientProvider for Seamless AWS AgentCore Authentication"
description: "A deep dive into using the native MCP SDK OAuth Client Provider to authenticate with MCP servers on AWS AgentCore, featuring M2M authentication, 403 error handling, and automated token management"
date: 2025-09-04
draft: false
thumbnail: ../invoke-mcp-hosted-on-aws-agentcore/images/cover.png
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
- OAuth Client Provider
- AWS AgentCore Runtime
- AWS AgentCore Gateway
- OAuth
- M2M Authentication
- Authentication
keywords:
- aws agentcore
- mcp client oauth
- oauth client provider
- m2m authentication
- bedrock agentcore
- mcp sdk oauth
---

## Overview

Building on my [previous exploration of connecting to MCP servers hosted on AWS AgentCore][previous-agentcore-post], I've been working extensively with the native MCP SDK's OAuth Client Provider to streamline authentication workflows. The MCP SDK's built-in OAuth support has evolved significantly, offering robust solutions for both interactive user authentication and machine-to-machine (M2M) flows.

In this follow-up article, I'll share the key improvements and special techniques I've discovered for using the MCP Client's `OAuthClientProvider` with AWS AgentCore, including handling AgentCore's unique behavior with 403 responses, implementing M2M authentication flows, and leveraging automatic token refresh capabilities.

What makes this approach particularly compelling is how the native SDK abstracts away much of the OAuth complexity while providing the flexibility needed for enterprise-grade deployments on AWS AgentCore.

## Key Improvements Over Manual OAuth Implementation

The native MCP SDK OAuth Client Provider offers several advantages over the manual OAuth implementations I covered in my previous post:

### 1. **Automatic Token Management**
- Built-in token storage and refresh mechanisms
- Seamless handling of expired tokens with automatic retry logic
- Support for both `refresh_token` (interactive) and `client_credentials` (M2M) flows

### 2. **AgentCore-Specific Compatibility**
- Custom handling of 403 HTTP responses (AgentCore returns 403 instead of 401 for unauthorized requests)
- Proper cross-domain OAuth metadata configuration
- Enhanced error handling and debugging capabilities

### 3. **Dual-Mode Authentication**
- Automatic detection of M2M vs Interactive mode based on client configuration
- Single codebase supporting both authentication patterns
- Intelligent scope selection based on OAuth provider type

## The AgentCoreOAuthClientProvider

The heart of this improved implementation is a custom OAuth provider that extends the native MCP SDK's `OAuthClientProvider`:

```python
class AgentCoreOAuthClientProvider(OAuthClientProvider):
    """Custom OAuth provider that triggers on 403 (not just 401) for AgentCore compatibility.
    
    Supports both interactive OAuth flows and M2M (client_credentials) flows with automatic
    token refresh for both modes.
    """
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.is_m2m_mode = False  # Will be set after client info is available
    
    def _detect_m2m_mode(self) -> bool:
        """Detect if we're in M2M mode based on client_secret availability."""
        return bool(
            self.context.client_info and 
            self.context.client_info.client_secret and
            hasattr(self.context, 'client_metadata') and
            not hasattr(self.context.client_metadata, 'redirect_uris') or
            not self.context.client_metadata.redirect_uris
        )
    
    async def async_auth_flow(self, request: httpx.Request) -> AsyncGenerator[httpx.Request, httpx.Response]:
        """HTTPX auth flow integration with 403 support and M2M mode."""
        # ... initialization logic ...
        
        response = yield request

        # CUSTOM FIX: Trigger OAuth flow on 403 OR 401 (AgentCore returns 403)
        if response.status_code in (401, 403):
            # Perform appropriate OAuth flow based on mode
            if self.is_m2m_mode:
                # M2M mode: Use client_credentials directly, no browser interaction
                token_request = await self._get_m2m_token()
                token_response = yield token_request
                await self._handle_m2m_token_response(token_response)
            else:
                # Interactive mode: Use authorization code flow
                auth_code, code_verifier = await self._perform_authorization()
                token_request = await self._exchange_token(auth_code, code_verifier)
                token_response = yield token_request
                await self._handle_token_response(token_response)

        # Retry with new tokens
        self._add_auth_header(request)
        yield request
```

## Special Tricks for AgentCore Runtime

### 1. **403 Response Handling**

AWS AgentCore returns HTTP 403 (Forbidden) instead of the standard HTTP 401 (Unauthorized) when authentication is required. This is a critical detail that trips up most OAuth implementations:

```python
# Standard OAuth implementations only handle 401
if response.status_code == 401:
    # Trigger OAuth flow

# AgentCore-compatible implementation handles both
if response.status_code in (401, 403):
    # Trigger OAuth flow - works with both standard servers and AgentCore
```

### 2. **Cross-Domain Metadata Configuration**

AgentCore MCP servers run on a different domain from the OAuth provider (typically AWS Cognito). This requires manual configuration of protected resource metadata:

```python
# Extract OAuth server URL from discovery URL
oauth_server_url = config['discovery_url'].replace('/.well-known/openid_configuration', '')

# Create protected resource metadata pointing to Cognito
protected_metadata = ProtectedResourceMetadata(
    resource=PydanticUrl(config['mcp_server_url']),
    authorization_servers=[PydanticUrl(oauth_server_url)]
)

# Manually inject the metadata into the OAuth context
oauth_auth.context.protected_resource_metadata = protected_metadata
oauth_auth.context.auth_server_url = oauth_server_url
```

### 3. **Pre-configured Client Information**

AWS Cognito doesn't support OAuth dynamic client registration, so we need to pre-configure client information:

```python
# Pre-configure client info to skip registration
client_info = OAuthClientInformationFull(
    client_id=config['client_id'],
    client_secret=config.get('client_secret'),
    authorization_endpoint="",  # Will be populated during OAuth metadata discovery
    token_endpoint="",  # Will be populated during OAuth metadata discovery
    redirect_uris=redirect_uris
)
await token_storage.set_client_info(client_info)
```

## M2M Authentication Flow Support

One of the most significant improvements is robust support for M2M authentication using the OAuth 2.0 client credentials flow:

### Automatic Mode Detection

The system automatically detects whether to use M2M or interactive authentication based on the presence of a client secret:

```python
# Detect M2M mode based on client_secret presence
is_m2m_mode = bool(config.get('client_secret'))

if is_m2m_mode:
    print("🏭 Detected client_secret - using M2M authentication")
    print("🚀 No user interaction required - fully automated")
else:
    print("🔐 No client_secret detected - using interactive authentication")
    print("🌐 Browser-based user authentication required")
```

### M2M Token Acquisition

The M2M flow bypasses browser-based authorization entirely:

```python
async def _get_m2m_token(self) -> httpx.Request:
    """Get M2M access token using client_credentials flow."""
    token_data = {
        "grant_type": "client_credentials",
        "client_id": self.context.client_info.client_id,
        "client_secret": self.context.client_info.client_secret,
    }
    
    # Add scope if specified
    if self.context.client_metadata.scope:
        token_data["scope"] = self.context.client_metadata.scope
    
    return httpx.Request(
        "POST", 
        token_url, 
        data=token_data, 
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
```

### AWS Cognito M2M Configuration

For AWS Cognito M2M flows, specific configuration is required:

```python
# For AWS Cognito M2M, configure appropriate scopes
if 'cognito-idp' in discovery_url.lower():
    if is_m2m_mode:
        # Use configured M2M scopes or None for default
        scope = config['m2m_scopes']  # e.g., "mcp-server/read mcp-server/write"
    else:
        scope = 'openid email aws.cognito.signin.user.admin'
```

## Complete Implementation Example

Here's how to use the improved OAuth Client Provider:

```python
async def test_native_sdk_oauth_flow(config: dict):
    """Test native MCP SDK OAuth flow with auto-detection of M2M vs interactive mode."""
    # Detect M2M mode based on client_secret presence
    is_m2m_mode = bool(config.get('client_secret'))
    
    # Configure appropriate scopes based on provider and mode
    if 'cognito-idp' in config['discovery_url'].lower():
        if is_m2m_mode:
            scope = config['m2m_scopes']  # Resource server scopes
        else:
            scope = 'openid email aws.cognito.signin.user.admin'
    else:
        scope = 'openid email profile' if not is_m2m_mode else config['m2m_scopes']
    
    # Create OAuth client metadata
    client_metadata = OAuthClientMetadata(
        client_name="MCP AgentCore OAuth Client",
        redirect_uris=[AnyUrl("http://localhost:3000")],
        grant_types=["authorization_code", "refresh_token"],
        response_types=["code"],
        scope=scope,
    )
    
    # Create token storage with debugging
    token_storage = DebugTokenStorage()
    
    # Pre-configure client info
    client_info = OAuthClientInformationFull(
        client_id=config['client_id'],
        client_secret=config.get('client_secret'),
        authorization_endpoint="",
        token_endpoint="",
        redirect_uris=[AnyUrl("http://localhost:3000")]
    )
    await token_storage.set_client_info(client_info)
    
    # Create custom OAuth client provider with AgentCore compatibility
    oauth_auth = AgentCoreOAuthClientProvider(
        server_url=config['mcp_server_url'],
        client_metadata=client_metadata,
        storage=token_storage,
        redirect_handler=handle_redirect if not is_m2m_mode else dummy_handler,
        callback_handler=handle_callback if not is_m2m_mode else dummy_handler,
    )
    
    # Configure protected resource metadata for cross-domain support
    oauth_server_url = config['discovery_url'].replace('/.well-known/openid_configuration', '')
    protected_metadata = ProtectedResourceMetadata(
        resource=PydanticUrl(config['mcp_server_url']),
        authorization_servers=[AnyUrl(oauth_server_url)]
    )
    oauth_auth.context.protected_resource_metadata = protected_metadata
    oauth_auth.context.auth_server_url = oauth_server_url
    
    # Use the OAuth provider with streamable HTTP client
    async with streamablehttp_client(config['mcp_server_url'], auth=oauth_auth) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()
            
            # List and invoke tools
            tools_result = await session.list_tools()
            print(f"Found {len(tools_result.tools)} tools available")
            
            return True
```

## Configuration and Environment Setup

The improved implementation supports flexible configuration through environment variables:

```bash
# OAuth 2.0 Configuration
export OAUTH_DISCOVERY_URL="https://cognito-idp.us-east-1.amazonaws.com/us-east-1_ABC123/.well-known/openid_configuration"
export OAUTH_CLIENT_ID="your-cognito-client-id"

# M2M Mode (optional - enables machine-to-machine authentication)
export OAUTH_CLIENT_SECRET="your-client-secret"
export OAUTH_M2M_SCOPES="mcp-server/read mcp-server/write"

# AgentCore Runtime Configuration
export AGENTCORE_RUNTIME_ARN="arn:aws:bedrock-agentcore:us-west-2:123456789012:runtime/my-server"
export AGENTCORE_REGION="us-west-2"

# Interactive Mode Testing (optional)
export OAUTH_TEST_USERNAME="testuser@example.com"
export OAUTH_TEST_PASSWORD="your-password"
```

## Key Advantages

### 1. **Simplified Integration**
The native SDK OAuth provider handles all the complex OAuth state management, token storage, and refresh logic automatically.

### 2. **Production-Ready M2M Support**
M2M authentication enables fully automated server-to-server communication without user intervention, perfect for production deployments.

### 3. **AgentCore Compatibility**
Custom handling of AgentCore's 403 responses and cross-domain metadata configuration ensures seamless integration.

### 4. **Automatic Token Refresh**
Both interactive and M2M modes support automatic token refresh, ensuring long-running applications maintain connectivity.

### 5. **Comprehensive Error Handling**
Detailed logging and error handling makes troubleshooting authentication issues much easier.

## Troubleshooting Common Issues

### M2M Authentication Failures
```bash
# Ensure client_credentials flow is enabled in Cognito
aws cognito-idp update-user-pool-client \
  --user-pool-id <your-user-pool-id> \
  --client-id <your-client-id> \
  --allowed-o-auth-flows "client_credentials" \
  --generate-secret
```

### Scope Configuration
For AWS Cognito M2M, you may need to configure resource server scopes:
- Interactive mode: `openid email aws.cognito.signin.user.admin`
- M2M mode: Custom resource server scopes like `mcp-server/read mcp-server/write`

### Cross-Domain Issues
Ensure the protected resource metadata correctly maps your MCP server URL to the OAuth authorization server.

## Conclusion

The native MCP SDK's OAuth Client Provider, enhanced with AgentCore-specific compatibility fixes, provides a robust foundation for production MCP client applications. The automatic detection of M2M vs interactive modes, combined with comprehensive error handling and token management, significantly reduces the complexity of integrating with OAuth-protected MCP servers on AWS AgentCore.

The key innovations—handling 403 responses, cross-domain metadata configuration, and dual-mode authentication—make this approach far more reliable than manual OAuth implementations for enterprise deployments.

As the MCP ecosystem continues to evolve, I expect we'll see these patterns become standard practice for production MCP client implementations, particularly in enterprise environments where M2M authentication and automated token management are essential requirements.

## Resources

- [Previous Post: How invoking remote MCP servers hosted on AWS AgentCore][previous-agentcore-post]
- [AWS AgentCore Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [Amazon Bedrock AgentCore MCP Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-mcp.html)
- [MCP Inspector Tool](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-using-inspector.html)
- [Complete Sample Implementation](https://gist.github.com/zxkane/2b9d7da3cdb08b4ea91bcbc7235ef6f0)

[previous-agentcore-post]: {{< relref "/posts/2025/invoke-mcp-hosted-on-aws-agentcore/index.md" >}}
