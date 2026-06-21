# Espacios de Trabajo Virtuales de GitHub Actions

Este repositorio proporciona una infraestructura automatizada para aprovisionar y conectarse a entornos de desarrollo virtuales interactivos (macOS, Windows Server y Ubuntu Linux) directamente utilizando los recursos de ejecución (Runner) alojados en GitHub. La conectividad se enruta de forma segura a través de una red superpuesta (Overlay Network) de Tailscale.

## Características Clave
- **Espacio de trabajo macOS**: Proporciona una sesión de escritorio interactiva (que incluye herramientas de línea de comandos de Xcode, cliente de navegador noVNC y code-server).
- **Espacio de trabajo Windows**: Proporciona una sesión de servidor RDP (Remote Desktop Protocol).
- **Espacio de trabajo Ubuntu**: Proporciona una sesión de terminal aislada y VS Code basado en la web.
- **Red Segura**: Todas las conexiones se tunelizan a través de Tailscale, eliminando la necesidad de abrir puertos públicos o configurar proxies inversos.

---

## Requisitos Previos

1. **Cuenta de Tailscale**: Cree una cuenta gratuita en [tailscale.com](https://tailscale.com).
2. **Clave de autenticación de Tailscale (Auth Key)**: Vaya a su Consola de administración de Tailscale -> Settings -> Keys, y genere una nueva clave de autenticación.
3. **Desactivar FileVault (macOS)**: Si utiliza hardware macOS autohospedado, asegúrese de desactivar FileVault. La encriptación de disco bloquea el inicio de sesión automático e impide que el uso compartido de pantalla o la gestión remota se inicie hasta que se desbloquee manualmente.

---

## Parámetros de Configuración

Debe definir los siguientes tres Secrets en la configuración de su repositorio en **Settings > Secrets and variables > Actions**:

| Clave del Secret | Descripción |
| :--- | :--- |
| `TS_KEY` | Su clave de autenticación de Tailscale. |
| `VNC_USER_PASSWORD` | La contraseña de la cuenta de usuario. Se utiliza para iniciar sesión en la VM y autenticar code-server. |
| `VNC_PASSWORD` | La contraseña de acceso utilizada estrictamente para sesiones de pantalla compartida VNC. |

*Nota: Si `VNC_USER_PASSWORD` o `VNC_PASSWORD` no están configurados como GitHub Secrets, los scripts de configuración generarán automáticamente una contraseña aleatoria segura y la mostrarán en los registros de ejecución del flujo de trabajo (Workflow).*

---

## Inicio Rápido

1. Realice un Fork de este repositorio.
2. Configure los tres Secrets enumerados anteriormente en la configuración de su repositorio.
3. Vaya a la pestaña **Actions** del repositorio.
4. Seleccione una de las opciones de flujo de trabajo unificado en la barra lateral:
   - **macOS Remote Desktop**
   - **Windows Remote Desktop**
   - **Ubuntu Development Server**
5. Haga clic en **Run workflow**, especifique el parámetro de especificación de la VM y active la acción.
6. Una vez que el entorno esté en ejecución, vea los registros del paso activo para obtener la dirección IP de Tailscale y los enlaces de conexión.

---

## Métodos de Conexión Soportados

Una vez que el entorno se esté ejecutando en el GitHub Runner y esté conectado a su red Tailscale, puede acceder a las VM utilizando los siguientes métodos de conexión:

| Plataforma SO | Tipo de Conexión | Dirección de Destino / URL | Usuario | Contraseña |
| :--- | :--- | :--- | :--- | :--- |
| **macOS** | Web VNC (noVNC) | `https://<Tailscale-IP>:6080/vnc.html` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VNC / App de pantalla compartida | `<Tailscale-IP>:5900` | `vncuser` | `VNC_PASSWORD` |
| **macOS** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/Users/vncuser` | *Ninguno* | `VNC_USER_PASSWORD` |
| **macOS** | Terminal SSH | `ssh vncuser@<Tailscale-IP>` | `vncuser` | `VNC_USER_PASSWORD` |
| **Windows** | Escritorio remoto (RDP) | `<Tailscale-IP>:3389` | `RDP` | `VNC_USER_PASSWORD` *(valor predeterminado si no se configura: Qwer!234)* |
| **Ubuntu** | VS Code Web | `https://<Tailscale-IP>:8181/?folder=/home/runner` | *Ninguno* | `VNC_USER_PASSWORD` |
| **Ubuntu** | Terminal SSH | `ssh runner@<Tailscale-IP>` | `runner` | Sin contraseña (usa la clave SSH predeterminada del Runner) |
