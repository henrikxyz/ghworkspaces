# GitHub Actions 仮想ワークスペース

このリポジトリは、GitHub ホスト型ランナー (Runner) のリソースを直接使用して、インタラクティブな仮想開発環境 (macOS、Windows Server、Ubuntu Linux) をプロビジョニングし接続するための自動化インフラを提供します。すべての接続は、Tailscale オーバーレイネットワークを介して安全にルーティングされます。

## 主な機能
- **macOS ワークスペース**: インタラクティブなデスクトップセッション (Xcode コマンドラインツール、noVNC ブラウザクライアント、および code-server を含む) を提供します。
- **Windows ワークスペース**: RDP (リモートデスクトッププロトコル) サーバーセッションを提供します。
- **Ubuntu ワークスペース**: 隔離されたターミナルセッションおよび Web ベースの VS Code を提供します。
- **安全なネットワーク**: すべての接続は Tailscale を介してトンネリングされるため、パブリックポートの開放やリバースプロキシの構築は不要です。

---

## 前提条件

1. **Tailscale アカウント**: [tailscale.com](https://tailscale.com) で無料アカウントを作成します。
2. **Tailscale 認証キー (Auth Key)**: Tailscale 管理コンソール -> Settings -> Keys に移動し、新しい認証キーを生成します。
3. **FileVault の無効化 (macOS)**: セルフホスト型 macOS ハードウェアを使用する場合は、FileVault が無効になっていることを確認してください。ディスク暗号化が有効な場合、自動ログインがブロックされ、手動でロック解除されるまでリモート管理や画面共有が起動しません。

---

## 設定パラメータ

リポジトリ設定の **Settings > Secrets and variables > Actions** で、以下の 3 つの Secret を定義する必要があります。

| Secret キー | 説明 |
| :--- | :--- |
| `TS_KEY` | Tailscale 認証キー。 |
| `VNC_USER_PASSWORD` | ユーザーアカウントのパスワード。VM へのログインおよび code-server の認証に使用されます。 |
| `VNC_PASSWORD` | VNC 画面共有セッション専用のアクセスパスワード。 |

*注意: `VNC_USER_PASSWORD` または `VNC_PASSWORD` が GitHub Secrets として設定されていない場合、セットアップスクリプトは安全なランダムパスワードを自動生成し、ワークフロー (Workflow) の実行ログに表示します。*

---

## クイックスタート

1. このリポジトリをフォークします。
2. リポジトリ設定で上記の 3 つの Secret を設定します。
3. リポジトリの **Actions** タブに移動します。
4. サイドバーで以下のいずれかのワークフローを選択します：
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. **Run workflow** をクリックし、VM スペックパラメータを指定して実行します。
6. 環境の起動後、実行ステップのログを表示して、Tailscale IP アドレスと接続リンクを取得します。

---

## サポートされている接続方法

環境が GitHub Runner 上で動作し、Tailscale ネットワークに接続されると、以下の方法で VM にアクセスできます。

| OS プラットフォーム | 接続タイプ | 対象アドレス / URL | ユーザー名 | パスワード |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | Web VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / 画面共有アプリ | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *なし* | `VNC_USER_PASSWORD` |
| **macOS** | SSH ターミナル | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | リモートデスクトップ (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(未設定時のデフォルト: Qwer!234)* |
| **Ubuntu** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *なし* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH ターミナル | `ssh runner@<Tailscale-IP>` | `runner` | パスワードなし (デフォルトの Runner SSH キーを使用) |
