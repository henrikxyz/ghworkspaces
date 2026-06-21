# setup_windows.ps1 - Windows provisioner for interactive GitHub Actions runner environments

# Enable error handling
$ErrorActionPreference = "Stop"

function Log-Info {
    param ([string]$Message)
    Write-Host "[INFO] $Message"
}

function Configure-RDPSubsystem {
    Log-Info "Configuring Remote Desktop configuration..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0 -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0 -Force
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 0 -Force

    netsh advfirewall firewall delete rule name="RDP-Tailscale" 2>$null | Out-Null
    netsh advfirewall firewall add rule name="RDP-Tailscale" dir=in action=allow protocol=TCP localport=3389 | Out-Null
    
    Restart-Service -Name TermService -Force
}

function Create-UserAccount {
    Log-Info "Evaluating credentials..."
    $password = $env:VNC_USER_PASSWORD
    if (-not $password) {
        # Generate secure random password
        $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#%"
        $password = -join (1..12 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
        $script:passwordLog = $password
        Log-Info "No VNC_USER_PASSWORD secret found. Generated random password."
    } else {
        $script:passwordLog = "[Configured via GitHub Secrets]"
    }
    
    Log-Info "Creating user account [RDP]..."
    $securePass = ConvertTo-SecureString $password -AsPlainText -Force
    
    New-LocalUser -Name "RDP" -Password $securePass -AccountNeverExpires | Out-Null
    Add-LocalGroupMember -Group "Administrators" -Member "RDP"
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member "RDP"
    
    # Enable dark theme registry keys
    $registryPath = 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Get-ChildItem 'Registry::HKEY_USERS' | Where-Object { $_.Name -match 'S-1-5-21' -and $_.Name -notmatch '_Classes$' } | ForEach-Object {
        $p = "Registry::$($_.Name)\$registryPath"
        if (-not (Test-Path $p)) {
            New-Item $p -Force | Out-Null
        }
        Set-ItemProperty $p AppsUseLightTheme 0 -Type DWord
        Set-ItemProperty $p SystemUsesLightTheme 0 -Type DWord
    }
    reg load HKU\D "$env:SystemDrive\Users\Default\NTUSER.DAT" | Out-Null
    $p = 'Registry::HKEY_USERS\D\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    if (-not (Test-Path $p)) {
        New-Item $p -Force | Out-Null
    }
    Set-ItemProperty $p AppsUseLightTheme 0 -Type DWord
    Set-ItemProperty $p SystemUsesLightTheme 0 -Type DWord
    reg unload HKU\D | Out-Null
    
    Stop-Process -Name explorer -Force
}

function Install-TailscaleSubsystem {
    Log-Info "Downloading and installing Tailscale..."
    $tsUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-1.90.9-amd64.msi"
    $installerPath = "$env:TEMP\tailscale.msi"
    
    # Bypass certificate issues if any by forcing TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $tsUrl -OutFile $installerPath
    Start-Process msiexec.exe -ArgumentList "/i", "`"$installerPath`"", "/quiet", "/norestart" -Wait
    Remove-Item $installerPath -Force
}

function Connect-Tailscale {
    Log-Info "Bringing up Tailscale connection..."
    & "$env:ProgramFiles\Tailscale\tailscale.exe" up --authkey=$env:TS_KEY

    $tsIP = $null
    $retries = 0
    while (-not $tsIP -and $retries -lt 10) {
        $tsIP = & "$env:ProgramFiles\Tailscale\tailscale.exe" ip -4
        Start-Sleep -Seconds 5
        $retries++
    }

    if (-not $tsIP) {
        throw "Failed to acquire Tailscale IP."
    }
    return $tsIP
}

function Verify-RDP {
    param ([string]$ip)
    Log-Info "Testing RDP port accessibility on $ip..."
    $testResult = Test-NetConnection -ComputerName $ip -Port 3389
    if (-not $testResult.TcpTestSucceeded) {
        throw "RDP port test failed."
    }
}

function Print-Summary {
    param ([string]$ip)
    Write-Host "`n"
    Write-Host "===================================================================="
    Write-Host "Windows Remote Desktop Environment Ready!"
    Write-Host "===================================================================="
    Write-Host "Connection Details:"
    Write-Host "  - Tailscale IP:        $ip"
    Write-Host "  - Username:            RDP"
    Write-Host "  - Password:            $script:passwordLog"
    Write-Host "--------------------------------------------------------------------"
    Write-Host "Quick Connect Links:"
    Write-Host "  - RDP Direct Port:     $ip`:3389"
    Write-Host "===================================================================="
    Write-Host "`n"
}

function Start-Workspace {
    Configure-RDPSubsystem
    Create-UserAccount
    Install-TailscaleSubsystem
    $ip = Connect-Tailscale
    Verify-RDP $ip
    Print-Summary $ip
    
    while ($true) {
        Write-Host "[$(Get-Date)] Windows RDP running... (Cancel the workflow in GitHub to stop)"
        Start-Sleep -Seconds 300
    }
}

Start-Workspace
