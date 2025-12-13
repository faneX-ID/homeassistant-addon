# faneX-ID Home Assistant Add-on

[![GitHub Release][releases-shield]][releases]
[![License][license-shield]](LICENSE)
[![GitHub Activity][commits-shield]][commits]
[![HACS][hacs-shield]][hacs]

![Project Maintenance][maintenance-shield]
[![Community Forum][forum-shield]][forum]

_Identity Management System with Social Features for Home Assistant._

![faneX-ID Logo](fanexid/logo.png)

## About

faneX-ID is a comprehensive identity management platform that brings social networking capabilities directly to your Home Assistant instance. This add-on packages the complete faneX-ID application (frontend and backend) into a single, easy-to-install package.

### Features

- 🔐 **User Authentication & Management** - Complete user lifecycle management
- 🔑 **SSO Support**
- 🔌 **Plugin System** - Extensible architecture for custom functionality
- 📱 **Mobile-Friendly** - Responsive design for all devices
- 🌍 **Multi-language**

## Installation

### Method 1: HACS (Recommended)

[![Open your Home Assistant instance and open a repository inside the Home Assistant Community Store.][hacs-install-shield]][hacs-install]

1. Ensure [HACS](https://hacs.xyz/) is installed
2. Click the button above **OR** follow these steps:
   - In HACS, go to **Integrations**
   - Click the three dots in the top right
   - Select **Custom repositories**
   - Add `https://github.com/faneX-ID/homeassistant-addon` as repository URL
   - Select **Integration** as category
   - Click **Add**
3. Find **faneX-ID** in the HACS integration list
4. Click **Download**
5. Restart Home Assistant
6. Configure the add-on (see [Configuration](#configuration) below)
7. Start the add-on

### Method 2: Add-on Store

1. Navigate to **Settings** → **Add-ons** in your Home Assistant instance
2. Click **Add-on Store** in the bottom right
3. Click the three dots menu in the top right → **Repositories**
4. Add this repository URL: `https://github.com/faneX-ID/homeassistant-addon`
5. Find **faneX-ID** in the list and click it
6. Click **Install**
7. Configure the add-on (see [Configuration](#configuration) below)
8. Start the add-on

### Method 3: Direct Repository Add

[![Add Repository][add-repo-shield]][add-repo]

Click the button above to add this repository to your Home Assistant instance automatically!

## Configuration

### Basic Configuration

⚠️ **Important**: The faneX-ID core repository is currently **private**. You need a [GitHub Personal Access Token](https://github.com/settings/tokens) to download the code.

**Supported Token Types:**
- ✅ **Fine-grained PAT** (recommended) - Starts with `github_pat_`
- ✅ **Classic PAT** (legacy) - Starts with `ghp_`

See the [detailed guide](fanexid/DOCS.md#how-to-create-a-github-token) for step-by-step instructions.

```yaml
version: "latest"
github_token: "ghp_your_github_token_here"  # Or github_pat_... for fine-grained
developer_mode: false
reset_database: false
log_level: info
database:
  type: sqlite
project_name: "faneX-ID"
debug: false
demo_mode: false
entra:
  enabled: false
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `version` | Version to install (`latest` or specific tag like `v1.0.0`) | `latest` |
| `github_token` | **Required**: GitHub PAT (Classic or Fine-grained) for private repo access | `""` |
| `developer_mode` | Use latest main branch code (for development only) | `false` |
| `reset_database` | ⚠️ **DANGEROUS** - Wipes all data on restart | `false` |
| `log_level` | Logging verbosity (`trace`, `debug`, `info`, `warning`, `error`, `fatal`) | `info` |
| `database.type` | Database backend (`sqlite` or `postgresql`) | `sqlite` |
| `project_name` | Display name for the application | `faneX-ID` |
| `debug` | Enable debug mode | `false` |
| `demo_mode` | Enable demo mode with sample data | `false` |
| `entra.enabled` | Enable Microsoft Entra ID SSO | `false` |

For detailed configuration options, see the [full documentation](fanexid/DOCS.md).

### Database Reset Warning

⚠️ **WARNING**: Enabling `reset_database` will **PERMANENTLY DELETE ALL DATA** including:
- All user accounts and profiles
- All matches and social connections
- All chat messages and history
- All uploaded files
- All settings and configurations

This action **CANNOT BE UNDONE**. Only enable this if you are absolutely sure you want to start fresh.

## Usage

After installation and startup:

1. Access faneX-ID through the **Home Assistant sidebar** (Ingress enabled)
2. Or navigate directly to your Home Assistant URL with the add-on port
3. Create your first admin account
4. Start building your community!

## Advanced Configuration

### PostgreSQL Database

For production deployments, PostgreSQL is recommended:

```yaml
github_token: "ghp_your_github_token_here"
database:
  type: postgresql
  postgresql_host: "192.168.1.100"
  postgresql_port: 5432
  postgresql_user: "fanexid"
  postgresql_password: "!secret fanexid_db_password"
  postgresql_database: "fanexid_db"
```

### Microsoft Entra ID SSO

Enable Single Sign-On with Microsoft:

```yaml
github_token: "ghp_your_github_token_here"
entra:
  enabled: true
  client_id: "your-app-client-id"
  tenant_id: "your-tenant-id"
  client_secret: "!secret entra_client_secret"
  redirect_uri: ""  # Leave empty for auto-configuration
```

### Developer Mode

For testing the latest features:

```yaml
github_token: "ghp_your_github_token_here"
developer_mode: true  # Downloads main branch on every restart
log_level: debug
```

⚠️ **Not recommended for production use** - May include unstable features!

## Support

- 🐛 [Report a Bug][issues]
- 💡 [Request a Feature][issues]
- 💬 [Community Forum][forum]
- 📖 [Documentation](fanexid/DOCS.md)

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](.github/CONTRIBUTING.md) for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Authors & Contributors

- **FaserF** - *Initial work* - [GitHub](https://github.com/FaserF)

See also the list of [contributors](https://github.com/faneX-ID/homeassistant-addon/contributors) who participated in this project.

## Acknowledgments

- Built on the excellent [faneX-ID Core](https://github.com/fanex-id/core) project
- Inspired by the Home Assistant Community Add-ons project
- Thanks to all contributors and users!

---

**Enjoy faneX-ID? Give us a ⭐ on GitHub!**

[add-repo]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FfaneX-ID%2Fhomeassistant-addon
[add-repo-shield]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[commits-shield]: https://img.shields.io/github/commit-activity/y/faneX-ID/homeassistant-addon.svg
[commits]: https://github.com/faneX-ID/homeassistant-addon/commits/main
[forum-shield]: https://img.shields.io/badge/community-forum-brightgreen.svg
[forum]: https://community.home-assistant.io/
[hacs]: https://github.com/hacs/integration
[hacs-install]: https://my.home-assistant.io/redirect/hacs_repository/?owner=faneX-ID&repository=homeassistant-addon&category=integration
[hacs-install-shield]: https://my.home-assistant.io/badges/hacs_repository.svg
[hacs-shield]: https://img.shields.io/badge/HACS-Default-orange.svg
[issues]: https://github.com/faneX-ID/homeassistant-addon/issues
[license-shield]: https://img.shields.io/github/license/faneX-ID/homeassistant-addon.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
[releases-shield]: https://img.shields.io/github/release/faneX-ID/homeassistant-addon.svg
[releases]: https://github.com/faneX-ID/homeassistant-addon/releases
