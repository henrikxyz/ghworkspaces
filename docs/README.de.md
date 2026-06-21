# Virtuelle Arbeitsbereiche für GitHub Actions

Dieses Repository bietet eine automatisierte Infrastruktur zur Bereitstellung und Verbindung mit interaktiven virtuellen Entwicklungsumgebungen (macOS, Windows Server und Ubuntu Linux) direkt unter Verwendung von von GitHub gehosteten Runner-Ressourcen. Die Konnektivität wird sicher über ein Tailscale-Overlay-Netzwerk geroutet.

## Hauptmerkmale
- **macOS-Arbeitsbereich**: Bietet eine interaktive Desktop-Sitzung (einschließlich Xcode-Befehlszeilentools, noVNC-Browser-Client und code-server).
- **Windows-Arbeitsbereich**: Bietet eine RDP-Server-Sitzung (Remote Desktop Protocol).
- **Ubuntu-Arbeitsbereich**: Bietet eine isolierte Terminal-Sitzung und webbasiertes VS Code.
- **Sicheres Netzwerk**: Alle Verbindungen werden über Tailscale getunnelt, sodass keine öffentlichen Ports geöffnet oder Reverse-Proxys eingerichtet werden müssen.

---

## Voraussetzungen

1. **Tailscale-Konto**: Erstellen Sie ein kostenloses Konto unter [tailscale.com](https://tailscale.com).
2. **Tailscale-Authentifizierungsschlüssel (Auth Key)**: Gehen Sie zu Ihrer Tailscale-Admin-Konsole -> Settings -> Keys und generieren Sie einen neuen Authentifizierungsschlüssel.
3. **FileVault deaktivieren (macOS)**: Wenn Sie selbst gehostete macOS-Hardware verwenden, stellen Sie sicher, dass FileVault deaktiviert ist. Die Aktivierung der Festplattenverschlüsselung blockiert die automatische Anmeldung und verhindert den Start der Bildschirmfreigabe oder Fernverwaltung, bis der Host manuell entsperrt wird.

---

## Konfigurationseinstellungen

Sie müssen die folgenden drei Secrets in Ihren Repository-Einstellungen unter **Settings > Secrets and variables > Actions** definieren:

| Secret-Schlüssel | Beschreibung |
| :--- | :--- |
| `TS_KEY` | Ihr Tailscale-Authentifizierungsschlüssel. |
| `VNC_USER_PASSWORD` | Das Passwort für das Benutzerkonto. Wird zur Anmeldung bei der VM und zur Authentifizierung von code-server verwendet. |
| `VNC_PASSWORD` | Das Zugriffspasswort, das ausschließlich für VNC-Bildschirmfreigabesitzungen verwendet wird. |

*Hinweis: Wenn `VNC_USER_PASSWORD` oder `VNC_PASSWORD` nicht als GitHub Secrets konfiguriert sind, generieren die Setup-Skripte automatisch ein sicheres Zufallspasswort und zeigen es in den Ausführungsprotokollen des Workflows an.*

---

## Schnellstart

1. Forken Sie dieses Repository.
2. Konfigurieren Sie die drei oben aufgeführten Secrets in Ihren Repository-Einstellungen.
3. Gehen Sie zur Registerkarte **Actions** des Repositories.
4. Wählen Sie einen der vereinheitlichten Workflows in der Seitenleiste aus:
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. Klicken Sie auf **Run workflow**, geben Sie den VM-Spezifikationsparameter an und starten Sie die Aktion.
6. Sobald die Umgebung ausgeführt wird, zeigen Sie die Protokolle des aktiven Schritts an, um die Tailscale-IP-Adresse und die Verbindungslinks abzurufen.

---

## Unterstützte Verbindungsmethoden

Sobald die Umgebung auf dem GitHub Runner ausgeführt wird und mit Ihrem Tailscale-Netzwerk verbunden ist, können Sie über die folgenden Verbindungsmethoden auf die VMs zugreifen:

| Betriebssystem-Plattform | Verbindungstyp | Zieladresse / URL | Benutzername | Passwort |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | Web VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / Bildschirmfreigabe-App | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *Keiner* | `VNC_USER_PASSWORD` |
| **macOS** | SSH-Terminal | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | Remotedesktop (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(Standardwert, falls nicht konfiguriert: Qwer!234)* |
| **Ubuntu** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *Keiner* | `VNC_USER_PASSWORD` |
| **Ubuntu** | SSH-Terminal | `ssh runner@<Tailscale-IP>` | `runner` | Passwortlos (verwendet den Standard-Runner-SSH-Schlüssel) |
