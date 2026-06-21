# GitHub Actions Virtual Workspaces

Translations: [繁體中文](docs/README.zh-TW.md) | [简体中文](docs/README.zh-CN.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md) | [Español](docs/README.es.md) | [Deutsch](docs/README.de.md)

This repository provides an automated infrastructure to provision and connect to interactive virtual development environments (macOS, Windows Server, and Ubuntu Linux) directly using GitHub-hosted runner resources. Connectivity is securely routed through a Tailscale overlay network.

## Key Features
- **macOS Workspace**: Provides an interactive desktop session (including Xcode command line tools, noVNC browser client, and code-server).
- **Windows Workspace**: Provides an RDP (Remote Desktop Protocol) server session.
- **Ubuntu Workspace**: Provides an isolated terminal session and web-based VS Code.
- **Secure Networking**: All connections are tunneled through Tailscale, removing the need for open public ports or reverse proxies.

---

## Prerequisites

1. **Tailscale Account**: Create a free account at [tailscale.com](https://tailscale.com).
2. **Tailscale Auth Key**: Go to your Tailscale Admin Console -> Settings -> Keys, and generate a new authentication key.
3. **Disable FileVault (macOS)**: If using self-hosted macOS hardware, ensure FileVault is disabled. Enabling disk encryption blocks automatic login and prevents Remote Management or Screen Sharing from starting until the host is manually unlocked.

---

## Configuration Settings

You must define the following three Secrets in your repository settings under **Settings > Secrets and variables > Actions**:

| Secret Key | Description |
| :--- | :--- |
| `TS_KEY` | Your Tailscale authentication key. |
| `VNC_USER_PASSWORD` | The user account password. Used to log into the VM and authenticate code-server. |
| `VNC_PASSWORD` | The access password used strictly for VNC screen sharing sessions. |

*Note: If `VNC_USER_PASSWORD` or `VNC_PASSWORD` are not configured as GitHub Secrets, the setup scripts will automatically generate a secure random password and display it in the workflow execution logs.*

---

## Quick Start

1. Fork this repository.
2. Configure the three Secrets listed above in your repository settings.
3. Go to the **Actions** tab of the repository.
4. Select one of the unified workflow options in the sidebar:
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. Click **Run workflow**, specify the VM specification parameter, and trigger the action.
6. Once the environment is running, view the active step logs to get the Tailscale IP address and connection links.

---

## Supported Connection Methods

Once the environment is running on the GitHub runner and connected to your Tailscale network, you can access the VMs using the following connection methods:

| OS Platform | Connection Type | Target Address / URL | Username | Password |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | Web VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / Screen Sharing App | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *None* | `VNC_USER_PASSWORD` |
| **macOS** | SSH Terminal | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | Remote Desktop (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(defaults to Qwer!234)* |
| **Ubuntu** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *None* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH Terminal | `ssh runner@<Tailscale-IP>` | `runner` | Passwordless (Default Runner SSH Key) |

