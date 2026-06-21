#!/bin/bash
# setup_macos.sh - macOS provisioner for interactive GitHub Actions runner environments

set -eo pipefail

readonly ACCOUNT_NAME="vncuser"
readonly DISPLAY_NAME="User"
readonly UNIQUE_ID=1001
readonly GROUP_ID=80
readonly HOMEDIR="/Users/vncuser"

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

    # Evaluate VNC_PASSWORD
    if [[ -z "$raw_vnc_password" ]]; then
        VNC_PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
        VNC_PASSWORD_LOG="$VNC_PASSWORD"
        log_info "No VNC_PASSWORD secret found. Generated random password."
    else
        VNC_PASSWORD="$raw_vnc_password"
        VNC_PASSWORD_LOG="[Configured via GitHub Secrets]"
    fi
}

sys_info() {
    log_info "Collecting environment details..."
    echo "--- VM Specifications ---"
    sw_vers
    sysctl -n machdep.cpu.brand_string hw.memsize
    system_profiler SPHardwareDataType SPSoftwareDataType | grep -E "Model Identifier|Processor Name|Number of Processors|Total Number of Cores|Memory"
    echo "-------------------------"
}

optimize_perf() {
    log_info "Optimizing system performance profile..."
    nohup bash -c '
        sudo defaults write ~/.Spotlight-V100/VolumeConfiguration.plist Exclusions -array "/Volumes" || true
        sudo defaults write ~/.Spotlight-V100/VolumeConfiguration.plist Exclusions -array "/Network" || true
        sudo killall mds || true
        sleep 10
        sudo mdutil -a -i off / || true
        sudo mdutil -a -i off || true
        sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist || true
        sudo rm -rf /.Spotlight-V100/*
        sudo rm -rf ~/Library/Metadata/CoreSpotlight/ || true
        killall -KILL Spotlight spotlightd mds || true
        sudo rm -rf /System/Volumes/Data/.Spotlight-V100 || true
        brew install --cask keka || true
    ' >/dev/null 2>&1 &
}

create_account() {
    log_info "Provisioning secure interactive user account [${ACCOUNT_NAME}]..."
    sudo dscl . -create "/Users/${ACCOUNT_NAME}"
    sudo dscl . -create "/Users/${ACCOUNT_NAME}" UserShell /bin/bash
    sudo dscl . -create "/Users/${ACCOUNT_NAME}" RealName "${DISPLAY_NAME}"
    sudo dscl . -create "/Users/${ACCOUNT_NAME}" UniqueID ${UNIQUE_ID}
    sudo dscl . -create "/Users/${ACCOUNT_NAME}" PrimaryGroupID ${GROUP_ID}
    sudo dscl . -create "/Users/${ACCOUNT_NAME}" NFSHomeDirectory "${HOMEDIR}"
    sudo dscl . -passwd "/Users/${ACCOUNT_NAME}" "$VNC_USER_PASSWORD"
    sudo dscl . -passwd "/Users/${ACCOUNT_NAME}" "$VNC_USER_PASSWORD"
    sudo createhomedir -c -u "${ACCOUNT_NAME}" > /dev/null
}

apply_tcc_db() {
    log_info "Injecting OS permissions into TCC subsystem..."
    csrutil status || true
    
    local python_inject="
import sqlite3, os, time
db = '/Library/Application Support/com.apple.TCC/TCC.db'
if not os.path.exists(db):
    print('Failed to locate target TCC database.')
    exit(1)
try:
    conn = sqlite3.connect(db)
    cursor = conn.cursor()
    permissions = ['kTCCServiceScreenCapture', 'kTCCServicePostEvent', 'kTCCServiceAccessibility']
    agent = 'com.apple.screensharing.agent'
    timestamp = int(time.time())
    for perm in permissions:
        cursor.execute('''
            INSERT OR REPLACE INTO access 
            (service, client, client_type, auth_value, auth_reason, auth_version, csreq, policy_id, indirect_object_identifier_type, indirect_object_identifier, flags, last_modified)
            VALUES (?, ?, 0, 2, 4, 1, NULL, NULL, 0, \\'UNUSED\\', 0, ?)
        ''', (perm, agent, timestamp))
    conn.commit()
    conn.close()
    print('Access permissions configured.')
except Exception as err:
    print(f'TCC error: {err}')
    exit(1)
"
    sudo python3 -c "$python_inject"
}

configure_screen_sharing() {
    log_info "Configuring macOS Screen Sharing server..."
    
    # Configure macOS UI defaults
    sudo defaults write /Library/Preferences/com.apple.universalaccess reduceTransparency -bool true
    sudo defaults write /Library/Preferences/com.apple.universalaccess reduceMotion -bool true
    sudo defaults write /Library/Preferences/com.apple.dock launchanim -bool false
    sudo defaults write com.apple.dock mineffect -string scale
    killall Dock || true
    sudo defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
    sudo defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
    sudo defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
    killall Finder || true

    # Shortcuts
    sudo ln -s / ~/Desktop/Macintosh\ HD || true
    sudo ln -s ~ ~/Desktop/Home || true
    sudo ln -s / "/Users/${ACCOUNT_NAME}/Desktop/Macintosh HD" || true
    sudo ln -s "/Users/${ACCOUNT_NAME}" "/Users/${ACCOUNT_NAME}/Desktop/Home" || true

    # Dark Mode
    open -a Terminal && sleep 1 && osascript -e 'tell application "Terminal" to quit' || true
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' || true

    # Activate Remote Management Agent
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off || true
    sleep 1
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
      -activate -configure -access -on \
      -clientopts -setvnclegacy -vnclegacy yes \
      -clientopts -setvncpw -vncpw "$VNC_PASSWORD" \
      -restart -agent -privs -all -allowAccessFor -allUsers || true

    sudo dseditgroup -o edit -a "$(whoami)" -t user com.apple.access_screensharing || true

    # Write legacy VNC settings
    echo "$VNC_PASSWORD" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt > /dev/null

    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console || true
    sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate || true
}

configure_network() {
    log_info "Setting up overlay network via Tailscale..."
    brew install tailscale >/dev/null 2>&1 || true
    sudo brew services start tailscale >/dev/null 2>&1 || true
    sleep 5

    local host_name="macOS-$( [ "$(uname -m)" = "arm64" ] && echo M1 || echo Intel )-$(sw_vers -productVersion | cut -d. -f1)"
    sudo tailscale up --authkey "$TS_KEY" --hostname="$host_name"

    local ip
    ip=$(tailscale ip -4)
    local ip_dashed
    ip_dashed=$(echo "$ip" | tr '.' '-')
    
    sudo scutil --set HostName "${host_name}-node-${ip_dashed}"
    sudo scutil --set LocalHostName "${host_name}-node-${ip_dashed}"
    sudo scutil --set ComputerName "${host_name}-node-${ip_dashed}"
}

install_utilities() {
    log_info "Installing development utilities (noVNC & code-server)..."
    
    # noVNC
    pip install websockify >/dev/null 2>&1 || true
    cd ~
    rm -rf ~/noVNC
    git clone https://github.com/iambjlu/noVNC.git >/dev/null 2>&1 || true
    cd ~/noVNC
    nohup websockify --web . --cert self.crt --key self.key 6080 localhost:5900 >/dev/null 2>&1 &

    # code-server
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

    # Funnel
    sudo tailscale funnel 8080 >/dev/null 2>&1 &
}

print_summary() {
    local ip
    ip=$(tailscale ip -4)
    echo ""
    echo "===================================================================="
    echo "macOS Remote Workspace Provisioned Successfully"
    echo "===================================================================="
    echo "Connection Parameters:"
    echo "  - Tailscale IP:        $ip"
    echo "  - Login Account:       $ACCOUNT_NAME"
    echo "  - macOS Password:      $VNC_USER_PASSWORD_LOG"
    echo "  - VNC Password:        $VNC_PASSWORD_LOG"
    echo "--------------------------------------------------------------------"
    echo "Web Entrypoints:"
    echo "  - Web VNC (noVNC):     https://$ip:6080/vnc.html"
    echo "  - VS Code Web:         https://$ip:8181/?folder=/Users/vncuser"
    echo "  - SSH Shell Command:   ssh vncuser@$ip"
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
    optimize_perf
    create_account
    apply_tcc_db
    configure_screen_sharing
    configure_network
    install_utilities
    print_summary
    keep_alive
}

main
