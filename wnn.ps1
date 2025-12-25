<#
.SYNOPSIS
    Monitor the current Windows desktop wallpaper and show a BurntToast notification or Rainmeter overlay when it changes.

.DESCRIPTION
    This script polls the current wallpaper cache in the Registry (the 'TranscodedImageCache' value),
    and extracts the currently active wallpaper file basename (without path or extension).
    When the slideshow changes wallpaper, the script displays the wallpaper name as a Rainmeter overlay
    over the background, or as a Windows notification using the BurntToast module. 
    This is a companion script for my AutoTheme project, but can be used independently.
    It comes with a convenient, bundled .exe, compiled thanks to PS2EXE.

.LINK
    https://github.com/unalignedcoder/monitor-wallpaper

.NOTES
    fixing workflows
    
#>

# ============= Script Version ==============

$scriptVersion = "1.0.27"

# ============= Configuration ==============

<# Write Wallpaper name in Registry, for other apps/scripts to read.
This is required to be $true for the Rainmeter method (see below.)
Also meant be used for future integration with my AutoTheme script. #>
$writeRegistry = $true

<# How to display the wallpaper name?
Options: "notification" and "rainmeter" (more will be added in future.)
"notification" requires the BurnToast PowerShell module, and shows a Windows notification on screen.
"rainmeter" requires the Rainmeter tool (rainmeter.net), and shows the wallpaper name as an overlay on the desktop. #>
$howToDisplayName = "rainmeter"

# How often to poll for wallpaper changes (milliseconds)
$pollMs = 30000 #30 seconds

# Logging Configuration
$logFile     = $true
$logReverse  = $true
$logFilePath = "$PSScriptRoot\wallpaper-monitor.log"

# ============= Detection Logic ==============

function Get-ExecutionEnvironment {
    <# 
    Detects the environment to prevent 'Write-Information' from creating 
    popup dialogs when no console window is present.
    #>
    $pPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    
    # 1. Is it a compiled EXE? (Checking if host is not powershell.exe)
    $isExe = ($pPath -match '\.exe$' -and $pPath -notmatch 'powershell\.exe')
    
    # 2. Is it running via Task Scheduler?
    $isTask = ($null -ne [Environment]::GetEnvironmentVariable("TaskName")) -or ($host.UI.RawUI.WindowTitle -match "taskeng.exe")
    
    # 3. Is the session non-interactive?
    $isNonInteractive = [Environment]::UserInteractive -eq $false

    return [PSCustomObject]@{
        IsExe    = $isExe
        IsSilent = ($isExe -or $isTask -or $isNonInteractive)
    }
}

# Run detection once at startup
$EnvInfo = Get-ExecutionEnvironment

# ============= System Tray Icon ==============

# Check if container process is exe, and if so, create a tray icon
if ($EnvInfo.IsExe -and [Environment]::UserInteractive) {
    Add-Type -AssemblyName System.Windows.Forms
    $trayIcon = New-Object System.Windows.Forms.NotifyIcon
    
    # Extract the icon from the EXE file itself
    $trayIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    $trayIcon.Text = "Wallpaper Name Notifier (v$scriptVersion)"
    $trayIcon.Visible = $true

    # Right-click menu for the Tray Icon
    $contextMenu = New-Object System.Windows.Forms.ContextMenu

    # Add a disabled version label at the top
    $versionLabel = $contextMenu.MenuItems.Add("WNN v$scriptVersion")
    $versionLabel.Enabled = $false
    $contextMenu.MenuItems.Add("-") # This adds a separator line
    
    $exitButton = $contextMenu.MenuItems.Add("Exit")
    $exitButton.add_Click({
        $trayIcon.Visible = $false
        Stop-Process -Id $PID
    })
    
    # Show a brief balloon tip confirming startup / only for debug purposes
    # $trayIcon.ShowBalloonTip(3000, "WNN Active", "Monitoring wallpaper changes in the background.", "Info")
}

# ============= Logging Function ==============

function LogThis {
    param ([string]$Message, [string]$Color = "White")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $plainMessage = "[$timestamp] $Message"
    
    # Log to terminal ONLY if not in a silent environment (Prevents MsgBox popups in EXE/Task mode)
    if (-not $EnvInfo.IsSilent) {
        # Define ANSI color codes
        $colors = @{
            "Red"    = "$([char]27)[31m"
            "Green"  = "$([char]27)[32m"
            "Yellow" = "$([char]27)[33m"
            "Cyan"   = "$([char]27)[36m"
            "White"  = "$([char]27)[37m"
            "Reset"  = "$([char]27)[0m"
        }

        # Use the requested color or default to White
        $colorCode = if ($colors.ContainsKey($Color)) { $colors[$Color] } else { $colors["White"] }
        $coloredMessage = "$colorCode$plainMessage$($colors['Reset'])"

        # Write to Information Stream (Stream 6)
        Write-Information $coloredMessage -InformationAction Continue
    }

    # Logging to file (Always active regardless of environment)
    if ($logFile) {
        $logDir = Split-Path $logFilePath
        if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

        if ($logReverse) {
            $existing = if (Test-Path $logFilePath) { Get-Content $logFilePath -Raw } else { "" }
            "$plainMessage`r`n$existing" | Set-Content $logFilePath -Encoding UTF8
        } else {
            $plainMessage | Out-File -Append $logFilePath -Encoding UTF8
        }
    }
}

# ============= Main Script Execution ==============

# Only import BurntToast if a notification is required
if ($howToDisplayName -eq "notification" -or $howToDisplayName -notmatch "rainmeter") {
    Import-Module BurntToast
}

LogThis "Polling every $pollMs ms" "Yellow"

# Track last filename to avoid duplicate triggers
$lastFile = ""

while ($true) {
    try {
        # Decode TranscodedImageCache, from registry binary to string
        $bytes   = (Get-ItemProperty "HKCU:\Control Panel\Desktop" -ErrorAction Stop).TranscodedImageCache
        $decoded = [System.Text.Encoding]::Unicode.GetString($bytes) -replace "`0",""

        # Extract the file path using regex
        if ($decoded -match "[A-Z]:\\.*") {
            $path = $matches[0]
            $filename = [System.IO.Path]::GetFileNameWithoutExtension($path)

            # Strip unwanted prefix if present (see my "AutoTheme" script project)
            $cleanName = $filename -replace "^_0_AutoTheme_", ""

            if ($cleanName -ne $lastFile -and $cleanName) {

                # Determine behavior based on $howToDisplayName
                if ($howToDisplayName -eq "notification") {
                    
                    # Update the registry value with the clean name
                    if ($writeRegistry) { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName }

                    # Consistent Notification Logic
                    if ($EnvInfo.IsExe -and $global:trayIcon) {

                        # Tray Balloon Tip for .exe users
                        $global:trayIcon.ShowBalloonTip(5000, "Your Wallpaper:", $cleanName, "None")
                        LogThis "Balloon Tip sent for: $cleanName" "Green"

                    } else {

                        # BurnToast notifications for .ps1 users.
                        New-BurntToastNotification -Text "Your Wallpaper: ", $cleanName
                        LogThis "BurntToast notification sent for: $cleanName" "Green"
                    }

                } elseif ($howToDisplayName -eq "rainmeter") {
                    
                    # ONLY update the registry (Rainmeter requires this, regardless of $writeRegistry setting)
                    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName
                    
                    # Force Rainmeter to refresh and pick up the new registry value immediately
                    if (Test-Path "C:\Program Files\Rainmeter\Rainmeter.exe") {
                        & "C:\Program Files\Rainmeter\Rainmeter.exe" !RefreshApp
                    }
                    
                    LogThis "Registry updated and Rainmeter refreshed: $cleanName" "Cyan"

                } else {

                    # Fail-Safe: Log the error, but don't annoy the user with a fallback notification
                    LogThis "Configuration Error: '$howToDisplayName' is not a valid display option." "Red"

                    if ($writeRegistry) { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName }
                }

                $lastFile = $cleanName
            }
        }
    } catch {
        LogThis "Error reading wallpaper cache: $($_.Exception.Message)" "Red"
    }

    Start-Sleep -Milliseconds $pollMs
}
