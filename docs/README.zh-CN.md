# GitHub Actions 虚拟工作空间

本项目提供自动化基础设施，使您能够直接利用 GitHub 托管的执行器 (Runner) 资源，部署并连接到交互式虚拟开发环境 (macOS、Windows Server 以及 Ubuntu Linux)。所有连接均通过 Tailscale 覆盖网络 (Overlay Network) 进行安全路由。

## 主要特色
- **macOS 工作空间**：提供交互式桌面会话 (包含 Xcode 命令行工具、noVNC 浏览器客户端及 code-server)。
- **Windows 工作空间**：提供 RDP (远程桌面协议) 服务器会话。
- **Ubuntu 工作空间**：提供隔离的终端会话及网页版 VS Code。
- **安全网络连接**：所有连接均通过 Tailscale 通道传输，无需开启外部公共端口或设置反向代理。

---

## 前提条件

1. **Tailscale 账号**：于 [tailscale.com](https://tailscale.com) 注册免费账号。
2. **Tailscale 认证密钥 (Auth Key)**：前往 Tailscale 管理控制台 -> Settings -> Keys，并生成一组新的认证密钥。
3. **关闭 FileVault (macOS)**：若您使用自托管 (Self-hosted) 的 macOS 硬件，请确保已关闭 FileVault。开启硬盘加密会阻止系统自动登录，并导致远程管理或屏幕共享在手动解锁前无法启动。

---

## 参数设置

您必须在项目设置的 **Settings > Secrets and variables > Actions** 中定义以下三个 Secret：

| Secret 键值 | 描述 |
| :--- | :--- |
| `TS_KEY` | 您的 Tailscale 认证密钥。 |
| `VNC_USER_PASSWORD` | 用户账号密码。用于登录虚拟机及 code-server 验证。 |
| `VNC_PASSWORD` | 专门用于 VNC 屏幕共享会话的访问密码。 |

*注意：若未设置 `VNC_USER_PASSWORD` 或 `VNC_PASSWORD` 作为 GitHub Secret，设置脚本会自动随机生成一组安全密码，并显示在工作流 (Workflow) 的执行日志中。*

---

## 快速开始

1. Fork 本项目。
2. 在项目设置中配置上述三个 Secret。
3. 前往项目的 **Actions** 标签页。
4. 在侧边栏中选择其中一个整合工作流：
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. 点击 **Run workflow**，指定虚拟机规格参数，并触发执行。
6. 当环境运行后，查看执行步骤的日志，以获取 Tailscale IP 地址与连接链接。

---

## 支持的连接方式

当环境在 GitHub Runner 上运行并连接到您的 Tailscale 网络后，您可以使用以下方式访问虚拟机：

| 操作系统平台 | 连接类型 | 目标地址 / URL | 用户名 | 密码 |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | 网页版 VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / 屏幕共享 App | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | 网页版 VS Code | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *无* | `VNC_USER_PASSWORD` |
| **macOS** | SSH 终端 | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | 远程桌面 (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(若未设置则默认为 Qwer!234)* |
| **Ubuntu** | 网页版 VS Code | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *无* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH 终端 | `ssh runner@<Tailscale-IP>` | `runner` | 免密码 (使用默认 Runner SSH 密钥) |
