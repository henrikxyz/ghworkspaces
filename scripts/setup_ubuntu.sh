#!/bin/bash
# setup_ubuntu.sh - Ubuntu provisioner for interactive GitHub Actions runner environments

set -eo pipefail

# Input parameters
raw_vnc_user_password="$1"
raw_vnc_password="$2"
readonly TS_KEY="$3"

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

validate_args() {
    if [[ -z "$TS_KEY" ]]; then
        log_error "Missing required TS_KEY parameters."
        exit 1
    fi
}

generate_passwords() {
    log_info "Evaluating credentials..."
    
    # Evaluate VNC_USER_PASSWORD
    if [[ -z "$raw_vnc_user_password" ]]; then
        VNC_USER_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
        VNC_USER_PASSWORD_LOG="$VNC_USER_PASSWORD"
        log_info "No VNC_USER_PASSWORD secret found. Generated random password."
    else
        VNC_USER_PASSWORD="$raw_vnc_user_password"
        VNC_USER_PASSWORD_LOG="[Configured via GitHub Secrets]"
    fi
}

sys_info() {
    log_info "Collecting environment details..."
    echo "--- VM Specifications ---"
    uname -a
    free -h
    df -h
    echo "-------------------------"
}

configure_system() {
    log_info "Configuring system settings..."
    sudo hostnamectl set-hostname "ubuntu-$(hostname)"
}

install_packages() {
    log_info "Installing required packages..."
    sudo apt update >/dev/null 2>&1 || true
    sudo apt install -y unzip curl openssl >/dev/null 2>&1 || true
}

configure_network() {
    log_info "Setting up overlay network via Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || true
    sudo systemctl enable --now tailscaled >/dev/null 2>&1 || true
    sleep 5
    sudo tailscale up --authkey "$TS_KEY"
}

install_code_server() {
    log_info "Installing and starting code-server..."
    curl -fsSL https://code-server.dev/install.sh | sh >/dev/null 2>&1 || true

    mkdir -p "$HOME/.certs"
    cd "$HOME/.certs"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout code-server.key \
      -out code-server.crt \
      -subj "/C=US/O=Development/CN=code-server" >/dev/null 2>&1 || true

    mkdir -p "$HOME/.config/code-server"
    cat > "$HOME/.config/code-server/config.yaml" <<EOF
bind-addr: 0.0.0.0:8181
cert: $HOME/.certs/code-server.crt
cert-key: $HOME/.certs/code-server.key
auth: password
password: $VNC_USER_PASSWORD
EOF
    rm -rf "$HOME/.cache"

    nohup code-server >/dev/null 2>&1 &

    # Enable Tailscale Funnel
    sudo tailscale funnel 8080 >/dev/null 2>&1 &
}

print_summary() {
    local ip
    ip=$(tailscale ip -4)
    echo ""
    echo "===================================================================="
    echo "Ubuntu Remote Workspace Provisioned Successfully"
    echo "===================================================================="
    echo "Connection Parameters:"
    echo "  - Tailscale IP:        $ip"
    echo "  - Login Account:       runner"
    echo "  - Password:            $VNC_USER_PASSWORD_LOG (for VS Code Web)"
    echo "--------------------------------------------------------------------"
    echo "Web Entrypoints:"
    echo "  - VS Code Web:         https://$ip:8181/?folder=/home/runner"
    echo "  - SSH Shell Command:   ssh runner@$ip"
    echo "===================================================================="
    echo ""
}

keep_alive() {
    log_info "Workspace is active. Cancel the workflow in GitHub to terminate."
    while true; do
        sleep 300
        echo "[KEEP-ALIVE] $(date): Session is active"
    done
}

main() {
    validate_args
    generate_passwords
    sys_info
    configure_system
    install_packages
    configure_network
    install_code_server
    print_summary
    keep_alive
}

main
