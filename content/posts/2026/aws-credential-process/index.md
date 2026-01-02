---
title: "Secure AWS Credentials with credential_process"
description: "Learn how to protect your AWS access keys by using credential_process to retrieve credentials from encrypted sources, enabling safe dotfiles backup"
date: 2026-01-02
lastmod: 2026-01-02
draft: false
thumbnail: ./images/cover.png
usePageBundles: true
codeMaxLines: 50
codeLineNumbers: true
toc: true
categories:
- blogging
isCJKLanguage: false
tags:
- AWS
- AWS CLI
- Security
- Credentials
- Best Practices
keywords:
- AWS credential_process
- AWS CLI credentials
- secure AWS credentials
- encrypted AWS access keys
- dotfiles backup
- AWS SDK credential sourcing
---

Managing AWS credentials securely is a fundamental challenge for developers. Storing plain text access keys in `~/.aws/credentials` creates significant security risks, especially when backing up dotfiles to version control systems. This post introduces `credential_process`, a powerful AWS CLI feature that allows you to source credentials from external processes, enabling encrypted credential storage while maintaining seamless AWS access.

## The Problem with Plain Text Credentials

The traditional approach stores AWS credentials in `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

This approach has several drawbacks:

1. **Security Risk**: Plain text credentials can be exposed if the file is accidentally committed or shared
2. **Backup Challenges**: Cannot safely backup dotfiles to cloud storage or version control
3. **Credential Rotation**: Manual updates required across multiple machines
4. **Audit Difficulty**: No visibility into when and how credentials are accessed

## credential_process: A Better Approach

The `credential_process` configuration option, introduced in **AWS CLI v1.14.0** (November 2017) and **botocore 1.8.0**, allows the CLI and SDKs to retrieve credentials by executing an external command. This enables sophisticated credential management patterns including encryption, hardware security modules, and custom authentication flows.

### How It Works

Instead of storing credentials directly, you specify a command in your `~/.aws/config` file:

```ini
[profile secure-profile]
region = us-west-2
credential_process = /path/to/your/credential-script.sh profile-name
```

When the AWS CLI or SDK needs credentials for this profile, it executes the specified command and expects a JSON response on stdout.

### Required JSON Output Format

The external process must output valid JSON with the following structure:

```json
{
  "Version": 1,
  "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
  "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
  "SessionToken": "optional-session-token",
  "Expiration": "2025-01-01T12:00:00Z"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `Version` | Yes | Must be `1` |
| `AccessKeyId` | Yes | AWS access key ID |
| `SecretAccessKey` | Yes | AWS secret access key |
| `SessionToken` | No | Required for temporary credentials |
| `Expiration` | No | ISO8601 timestamp; triggers auto-refresh |

## Practical Implementation: Encrypted Credentials

Here's a practical implementation that stores credentials in an encrypted file, enabling safe backup of your dotfiles while keeping credentials secure.

### Step 1: Encrypt Your Credentials

First, create a credentials file in the standard format and encrypt it:

```bash
# Create a strong encryption key
mkdir -p ~/.secrets
openssl rand -base64 32 > ~/.secrets/aws-creds.key
chmod 600 ~/.secrets/aws-creds.key

# Encrypt your credentials file
openssl enc -aes-256-cbc -pbkdf2 \
  -in ~/.aws/credentials \
  -out ~/.aws/static_credentials.enc \
  -pass file:~/.secrets/aws-creds.key

# Remove the plain text file
rm ~/.aws/credentials
```

### Step 2: Create the Credential Retrieval Script

Create a script at `~/.aws/get_creds.sh`:

```bash
#!/bin/bash
ENC_FILE="$HOME/.aws/static_credentials.enc"
KEY_FILE="$HOME/.secrets/aws-creds.key"
PROFILE="${1:-default}"

if [ ! -f "$KEY_FILE" ]; then
  echo "Key file not found: $KEY_FILE" >&2
  exit 1
fi

CONTENT=$(openssl enc -aes-256-cbc -d -pbkdf2 \
  -in "$ENC_FILE" \
  -pass file:"$KEY_FILE" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Failed to decrypt credentials" >&2
  exit 1
fi

AK=$(echo "$CONTENT" | sed -n "/^\[$PROFILE\]/,/^\[/p" | \
     grep aws_access_key_id | cut -d= -f2 | tr -d ' ')
SK=$(echo "$CONTENT" | sed -n "/^\[$PROFILE\]/,/^\[/p" | \
     grep aws_secret_access_key | cut -d= -f2 | tr -d ' ')

if [ -z "$AK" ] || [ -z "$SK" ]; then
  echo "Profile '$PROFILE' not found" >&2
  exit 1
fi

cat <<EOF
{"Version":1,"AccessKeyId":"$AK","SecretAccessKey":"$SK"}
EOF
```

Make it executable:

```bash
chmod +x ~/.aws/get_creds.sh
```

### Step 3: Configure AWS CLI Profiles

Update your `~/.aws/config`:

```ini
[profile dev]
region = us-west-2
cli_pager =
credential_process = sh -c '$HOME/.aws/get_creds.sh dev'

[profile prod]
region = us-east-1
cli_pager =
credential_process = sh -c '$HOME/.aws/get_creds.sh prod'
```

### Step 4: Safe Dotfiles Backup

Now you can safely backup your AWS configuration:

```bash
# Files safe to backup (no plain text credentials)
~/.aws/config                    # Profile configurations
~/.aws/static_credentials.enc    # Encrypted credentials
~/.aws/get_creds.sh             # Retrieval script

# File to keep separate and secure
~/.secrets/aws-creds.key         # Encryption key - NEVER backup to public repos
```

## Supporting Temporary Credentials (STS)

For profiles that use temporary credentials from STS, create an extended script:

```bash
#!/bin/bash
PROFILE="${1:-default}"
CRED_FILE="$HOME/.aws/credential_$PROFILE"
FALLBACK_FILE="$HOME/.aws/credentials"

if [ -f "$CRED_FILE" ]; then
  FILE="$CRED_FILE"
else
  FILE="$FALLBACK_FILE"
fi

if [ ! -f "$FILE" ]; then
  echo "Credential file not found" >&2
  exit 1
fi

AK=$(sed -n "/^\[$PROFILE\]/,/^\[/p" "$FILE" | \
     grep aws_access_key_id | cut -d= -f2 | tr -d ' ')
SK=$(sed -n "/^\[$PROFILE\]/,/^\[/p" "$FILE" | \
     grep aws_secret_access_key | cut -d= -f2 | tr -d ' ')
ST=$(sed -n "/^\[$PROFILE\]/,/^\[/p" "$FILE" | \
     grep aws_session_token | cut -d= -f2 | tr -d ' ')

if [ -z "$AK" ] || [ -z "$SK" ]; then
  echo "Profile '$PROFILE' not found" >&2
  exit 1
fi

if [ -n "$ST" ]; then
  cat <<EOF
{"Version":1,"AccessKeyId":"$AK","SecretAccessKey":"$SK","SessionToken":"$ST"}
EOF
else
  cat <<EOF
{"Version":1,"AccessKeyId":"$AK","SecretAccessKey":"$SK"}
EOF
fi
```

## SDK and Tool Compatibility

The `credential_process` feature is supported across the AWS ecosystem:

| Tool/SDK | Minimum Version | Notes |
|----------|-----------------|-------|
| AWS CLI v1 | 1.14.0 | November 2017 |
| AWS CLI v2 | All versions | Built-in support |
| botocore | 1.8.0 | Python SDK foundation |
| boto3 | 1.5.0 | Python SDK |
| AWS SDK for Go | v1.15.0 | Go SDK |
| AWS SDK for Java | 2.x | Java SDK v2 |
| AWS SDK for JavaScript | v3 | Node.js SDK v3 |

## Security Best Practices

When implementing `credential_process`, follow these guidelines:

1. **Protect the encryption key**: Store it separately from encrypted credentials
2. **Use strong encryption**: AES-256 with PBKDF2 key derivation
3. **Set proper permissions**: `chmod 600` for sensitive files
4. **Never log secrets**: Avoid writing credentials to stderr
5. **Handle errors gracefully**: Return non-zero exit codes for failures
6. **Consider hardware security**: For high-security environments, integrate with HSMs or TPMs

## Advanced Use Cases

### Integration with Password Managers

```bash
#!/bin/bash
# Retrieve credentials from 1Password
PROFILE="${1:-default}"
op item get "AWS-$PROFILE" --format json | \
  jq '{Version:1, AccessKeyId:.fields[0].value, SecretAccessKey:.fields[1].value}'
```

### Integration with HashiCorp Vault

For organizations using HashiCorp Vault for secrets management:

```bash
#!/bin/bash
# Retrieve credentials from HashiCorp Vault
VAULT_PATH="${1:-secret/data/aws/credentials}"

SECRET=$(vault kv get -format=json "$VAULT_PATH" 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Failed to retrieve secret from Vault" >&2
  exit 1
fi

echo "$SECRET" | jq '{
  Version: 1,
  AccessKeyId: .data.data.access_key_id,
  SecretAccessKey: .data.data.secret_access_key
}'
```

### Alternative: AWS IAM Identity Center (SSO)

For environments using AWS IAM Identity Center (formerly AWS SSO), note that SSO provides a **native alternative** to `credential_process` rather than being combined with it. SSO handles temporary credential generation automatically:

```ini
[profile sso-profile]
sso_session = my-sso
sso_account_id = 123456789012
sso_role_name = DeveloperAccess

[sso-session my-sso]
sso_start_url = https://my-org.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```

**When to use each approach**:

| Approach | Use Case |
|----------|----------|
| `credential_process` | Long-term IAM credentials, custom auth systems, secrets managers |
| AWS SSO | Federated identity, temporary credentials, enterprise SSO integration |
| Both (rare) | Legacy systems requiring IAM credentials alongside SSO migration |

## Conclusion

The `credential_process` feature provides a flexible and secure approach to AWS credential management. By storing credentials in encrypted form and retrieving them through external processes, you can:

- Safely backup your AWS configuration to version control
- Implement custom authentication flows
- Integrate with enterprise security tools
- Maintain credential hygiene across multiple machines

For more AWS CLI tips and tricks, check out my post on [Awesome AWS CLI][awscli-collection].

## Resources

- [AWS CLI External Credential Sourcing Documentation][aws-docs-credential-process]
- [AWS Shared Credentials File Configuration][aws-docs-credentials]
- [OpenSSL Encryption Documentation][openssl-enc]

---

<!-- AWS Documentation -->
[aws-docs-credential-process]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html
[aws-docs-credentials]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
[openssl-enc]: https://www.openssl.org/docs/man1.1.1/man1/openssl-enc.html

<!-- Related Posts -->
[awscli-collection]: {{< relref "/posts/2024/awscli-collection/index.md" >}}
