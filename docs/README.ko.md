# GitHub Actions 가상 워크스페이스

본 저장소는 GitHub 호스팅 러너(Runner) 리소스를 직접 사용하여 대화형 가상 개발 환경(macOS, Windows Server, Ubuntu Linux)을 자동으로 프로비저닝하고 연결할 수 있는 자동화 인프라를 제공합니다. 모든 연결은 Tailscale 오버레이 네트워크를 통해 안전하게 라우팅됩니다.

## 주요 특징
- **macOS 워크스페이스**: 대화형 데스크톱 세션(Xcode 명령줄 도구, noVNC 브라우저 클라이언트 및 code-server 포함)을 제공합니다.
- **Windows 워크스페이스**: RDP (원격 데스크톱 프로토콜) 서버 세션을 제공합니다.
- **Ubuntu 워크스페이스**: 격리된 터미널 세션 및 웹 기반 VS Code를 제공합니다.
- **안전한 네트워크 연결**: 모든 연결은 Tailscale 터널을 통해 전송되므로, 외부 공용 포트를 열거나 역방향 프록시를 설정할 필요가 없습니다.

---

## 사전 요구 사항

1. **Tailscale 계정**: [tailscale.com](https://tailscale.com)에서 무료 계정을 생성합니다.
2. **Tailscale 인증 키 (Auth Key)**: Tailscale 관리 콘솔 -> Settings -> Keys로 이동하여 새로운 인증 키를 생성합니다.
3. **FileVault 비활성화 (macOS)**: 자체 호스팅(Self-hosted) macOS 하드웨어를 사용하는 경우 FileVault가 비활성화되어 있는지 확인하십시오. 디스크 암호화가 활성화된 경우 자동 로그인이 차단되어 호스트가 수동으로 잠금 해제될 때까지 원격 관리 또는 화면 공유가 시작되지 않습니다.

---

## 구성 설정

저장소 설정의 **Settings > Secrets and variables > Actions**에서 다음 세 가지 Secret을 정의해야 합니다.

| Secret 키 | 설명 |
| :--- | :--- |
| `TS_KEY` | Tailscale 인증 키. |
| `VNC_USER_PASSWORD` | 사용자 계정 비밀번호. VM 로그인 및 code-server 인증에 사용됩니다. |
| `VNC_PASSWORD` | VNC 화면 공유 세션 전용 액세스 비밀번호. |

*참고: `VNC_USER_PASSWORD` 또는 `VNC_PASSWORD`가 GitHub Secrets로 설정되지 않은 경우, 설정 스크립트가 안전한 임의의 비밀번호를 자동으로 생성하고 워크플로(Workflow) 실행 로그에 표시합니다.*

---

## 빠른 시작

1. 본 저장소를 포크(Fork)합니다.
2. 저장소 설정에서 위의 세 가지 Secret을 구성합니다.
3. 저장소의 **Actions** 탭으로 이동합니다.
4. 사이드바에서 다음 통합 워크플로 중 하나를 선택합니다:
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. **Run workflow**를 클릭하고 VM 사양 매개변수를 지정한 다음 실행합니다.
6. 환경이 실행되면 실행 단계 로그를 확인하여 Tailscale IP 주소와 연결 링크를 가져옵니다.

---

## 지원되는 연결 방법

환경이 GitHub Runner에서 실행되고 Tailscale 네트워크에 연결되면, 다음 방법을 사용하여 VM에 액세스할 수 있습니다.

| OS 플랫폼 | 연결 유형 | 대상 주소 / URL | 사용자 이름 | 비밀번호 |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | 웹 VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / 화면 공유 앱 | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | 웹 VS Code | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *없음* | `VNC_USER_PASSWORD` |
| **macOS** | SSH 터미널 | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | 원격 데스크톱 (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(설정하지 않은 경우 기본값: Qwer!234)* |
| **Ubuntu** | 웹 VS Code | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *없음* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH 터미널 | `ssh runner@<Tailscale-IP>` | `runner` | 비밀번호 없음 (기본 Runner SSH 키 사용) |
