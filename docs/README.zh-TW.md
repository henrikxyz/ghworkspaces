# GitHub Actions 虛擬工作空間

本專案提供自動化基礎設施，讓您能直接利用 GitHub 託管的執行器 (Runner) 資源，佈署並連線到互動式虛擬開發環境 (macOS、Windows Server 以及 Ubuntu Linux)。所有連線皆透過 Tailscale 覆蓋網路 (Overlay Network) 進行安全路由。

## 主要特色
- **macOS 工作空間**：提供互動式桌面工作階段 (包含 Xcode 命令列工具、noVNC 瀏覽器用戶端及 code-server)。
- **Windows 工作空間**：提供 RDP (遠端桌面協定) 伺服器工作階段。
- **Ubuntu 工作空間**：提供隔離的終端機工作階段及網頁版 VS Code。
- **安全網路連線**：所有連線均透過 Tailscale 通道傳輸，無需開啟外部公共埠或設定反向代理。

---

## 前提條件

1. **Tailscale 帳號**：於 [tailscale.com](https://tailscale.com) 註冊免費帳號。
2. **Tailscale 認證金鑰 (Auth Key)**：前往 Tailscale 管理控制台 -> Settings -> Keys，並產生一組新的認證金鑰。
3. **關閉 FileVault (macOS)**：若您使用自託管 (Self-hosted) 的 macOS 硬體，請確保已關閉 FileVault。開啟硬碟加密會阻止系統自動登入，並導致遠端管理或螢幕共享在手動解鎖前無法啟動。

---

## 參數設定

您必須在專案設定的 **Settings > Secrets and variables > Actions** 中定義以下三個 Secret：

| Secret 鍵值 | 描述 |
| :--- | :--- |
| `TS_KEY` | 您的 Tailscale 認證金鑰。 |
| `VNC_USER_PASSWORD` | 使用者帳號密碼。用於登入虛擬機器及 code-server 驗證。 |
| `VNC_PASSWORD` | 專門用於 VNC 螢幕共享工作階段的存取密碼。 |

*注意：若未設定 `VNC_USER_PASSWORD` 或 `VNC_PASSWORD` 作為 GitHub Secret，設定指令碼會自動隨機產生一組安全密碼，並顯示於工作流 (Workflow) 的執行日誌中。*

---

## 快速開始

1. Fork 本專案。
2. 於專案設定中配置上述三個 Secret。
3. 前往專案的 **Actions** 頁籤。
4. 在側邊欄中選擇其中一個整合工作流：
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. 點擊 **Run workflow**，指定虛擬機器規格參數，並觸發執行。
6. 當環境運行後，檢視執行步驟的日誌，以取得 Tailscale IP 位址與連線連結。

---

## 支援的連線方式

當環境在 GitHub Runner 上運行並連線至您的 Tailscale 網路後，您可以使用以下方式存取虛擬機器：

| 作業系統平台 | 連線類型 | 目標位址 / URL | 使用者名稱 | 密碼 |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | 網頁版 VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / 螢幕共享 App | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | 網頁版 VS Code | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *無* | `VNC_USER_PASSWORD` |
| **macOS** | SSH 終端機 | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | 遠端桌面 (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(若未設定則預設為 Qwer!234)* |
| **Ubuntu** | 網頁版 VS Code | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *無* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH 終端機 | `ssh runner@<Tailscale-IP>` | `runner` | 免密碼 (使用預設 Runner SSH 金鑰) |
