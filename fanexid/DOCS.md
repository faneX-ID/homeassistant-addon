# Home Assistant Add-on: faneX-ID

All-in-one Identity Management System with Social Features for Home Assistant.

## About

faneX-ID is a comprehensive identity management platform that combines user management, social networking features, and authentication services. This add-on packages the entire application (frontend and backend) into a single, easy-to-install Home Assistant add-on.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the "faneX-ID" add-on
3. Configure the add-on (see configuration section below)
4. Start the add-on
5. Access faneX-ID through the Home Assistant interface using Ingress

## Configuration

### Basic Configuration

**version**: Version to install
- Use `latest` to automatically install the newest release
- Specify a version tag like `v1.0.0` for a specific version
- When using Renovate, this will be automatically updated

**github_token**: GitHub Personal Access Token (required)
- The faneX-ID core repository is currently **private**
- You need a GitHub Personal Access Token to download the code
- Supports both **Classic** and **Fine-grained** tokens
- Leave empty only after first successful download (code is cached)

#### How to Create a GitHub Token:

GitHub offers two types of Personal Access Tokens. **Fine-grained tokens** are recommended for better security, but **Classic tokens** work equally well.

##### Option 1: Fine-grained Personal Access Token (Recommended)

1. **Go to GitHub Token Settings**
   - Visit: [https://github.com/settings/personal-access-tokens/new](https://github.com/settings/personal-access-tokens/new)
   - Or: GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens

2. **Configure Token Basic Settings**
   - **Token name**: `fanexid-homeassistant-addon`
   - **Expiration**: 90 days (or custom - you'll need to renew when it expires)
   - **Description**: "Access for faneX-ID Home Assistant Addon"

3. **Repository Access**
   - Select **"Only select repositories"**
   - Choose **`fanex-id/core`** from the dropdown

4. **Permissions**
   - Under **"Repository permissions"**, expand **"Contents"**
   - Set to **"Read-only"** (this is all you need!)
   - All other permissions can remain as "No access"

5. **Generate Token**
   - Click **"Generate token"**
   - **Important**: Copy the token immediately (starts with `github_pat_`)
   - You won't see it again!

6. **Paste in Add-on Config**
   - In Home Assistant, go to the add-on configuration
   - Paste the token into the `github_token` field
   - Save the configuration

##### Option 2: Classic Personal Access Token (Legacy)

1. **Go to GitHub Token Settings**
   - Visit: [https://github.com/settings/tokens](https://github.com/settings/tokens)
   - Or: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)

2. **Generate New Token**
   - Click **"Generate new token (classic)"**
   - You may need to re-authenticate

3. **Configure Token**
   - **Note**: `fanexid-homeassistant-addon`
   - **Expiration**: Select an expiration (recommended: 90 days or 1 year)

4. **Select Scopes**
   - ✅ Check **`repo`** (Full control of private repositories)
     - This grants access to the private `fanex-id/core` repository
     - All sub-permissions under `repo` will be automatically selected
   - All other scopes can remain unchecked

5. **Generate Token**
   - Click **"Generate token"** at the bottom
   - **Important**: Copy the token immediately (starts with `ghp_`)
   - You won't see it again!

6. **Paste in Add-on Config**
   - In Home Assistant, go to the add-on configuration
   - Paste the token into the `github_token` field
   - Save the configuration

#### Token Format Recognition

The add-on automatically detects your token type:
- **Fine-grained**: Starts with `github_pat_` → Uses Bearer authentication
- **Classic**: Starts with `ghp_` → Uses token authentication
- Both formats work equally well!

⚠️ **Security Notes**:
- Never share your GitHub token publicly!
- If your token expires, generate a new one and update the configuration
- The token is stored securely by Home Assistant
- For maximum security, use fine-grained tokens with minimal permissions

**developer_mode**: Development mode (default: `false`)
- When enabled, downloads the latest code from the main branch on every restart
- Requires a valid `github_token` to be configured
- ⚠️ **Only for development**: May include unstable features!

**log_level**: Logging verbosity (default: `info`)
- Options: `trace`, `debug`, `info`, `warning`, `error`, `fatal`

### Database Configuration

**database.type**: Database backend (default: `sqlite`)
- `sqlite`: Simple embedded database (recommended for most users)
- `postgresql`: External PostgreSQL server (for advanced setups)

When using PostgreSQL, configure these settings:
- **postgresql_host**: Database server hostname
- **postgresql_port**: Database server port (default: 5432)
- **postgresql_user**: Database username
- **postgresql_password**: Database password
- **postgresql_database**: Database name

### Application Settings

**project_name**: Display name (default: `faneX-ID`)

**debug**: Debug mode (default: `false`)
- Enables detailed error messages
- ⚠️ Not recommended for production use

**demo_mode**: Demo mode (default: `false`)
- Populates the application with sample data
- Restricts some functionality

**secret_key**: Encryption key (optional)
- Leave empty to auto-generate a secure key
- Once generated, keep this value consistent

### Single Sign-On (SSO)

Configure Microsoft Entra ID (formerly Azure AD) for SSO:

**entra.enabled**: Enable Entra ID authentication (default: `false`)

When enabled, configure:
- **entra.client_id**: Application (client) ID from Azure
- **entra.tenant_id**: Directory (tenant) ID from Azure
- **entra.client_secret**: Client secret from Azure
- **entra.redirect_uri**: OAuth callback URL (leave empty to auto-configure)

### Advanced Options

**reset_database**: Reset all data (default: `false`)
- ⚠️ **DANGER**: This will DELETE ALL DATA including users, profiles, and chat history!
- The database will be completely wiped on next restart
- This action cannot be undone
- After restart, this option automatically resets to `false`

## Example Configuration

### SQLite (Simple Setup)

```yaml
version: "latest"
github_token: "ghp_your_github_token_here"
developer_mode: false
log_level: info
database:
  type: sqlite
project_name: "faneX-ID"
debug: false
demo_mode: false
entra:
  enabled: false
```

### PostgreSQL (Advanced Setup)

```yaml
version: "v1.0.0"
github_token: "ghp_your_github_token_here"
developer_mode: false
log_level: info
database:
  type: postgresql
  postgresql_host: "192.168.1.100"
  postgresql_port: 5432
  postgresql_user: "fanexid"
  postgresql_password: "secure_password_here"
  postgresql_database: "fanexid_db"
project_name: "faneX-ID"
secret_key: "your_secret_key_here"
entra:
  enabled: true
  client_id: "your_client_id"
  tenant_id: "your_tenant_id"
  client_secret: "your_client_secret"
```

### Developer Mode Setup

```yaml
version: "latest"
github_token: "ghp_your_github_token_here"
developer_mode: true  # Downloads main branch on every restart
log_level: debug
database:
  type: sqlite
project_name: "faneX-ID"
debug: true
demo_mode: false
```

## Support

For issues and feature requests:
- [GitHub Issues](https://github.com/fanex-id/core/issues)
- [Home Assistant Community Forum](https://community.home-assistant.io/)

## License

This add-on uses the faneX-ID project which is licensed under GPL-3.0.

## Authors

- Original faneX-ID Project: FaserF
- Home Assistant Add-on: FaserF
