<#
.SYNOPSIS
    Monitor the current Windows desktop wallpaper and show a BurntToast notification when it changes.

.DESCRIPTION
    This script polls the current wallpaper cache in the Registry (the 'TranscodedImageCache' value),
    and extracts the currently active wallpaper file basename (without path or extension).
    When the slideshow changes wallpaper, the script displays the wallpaper name as a Rainmeter overlay
    over the background, or as a Windows notification using the BurntToast module. 
    This is a companion script for my AutoTheme project, but can be used independently.

.LINK
    https://github.com/unalignedcoder/monitor-wallpaper

.NOTES
    - Added Rainmeter integration (see wnn.ini)
    - Added logging system
    - Added workflow to automate tagging and releases
    - Several improvements and fixes
#>

# ============= Script Version ==============

$scriptVersion = "1.0.26"

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

# ============= Script Logic ==============

# Logging Function using Write-Information and ANSI colors
function LogThis {
    param ([string]$Message, [string]$Color = "White")
    
    # Define ANSI color codes
    $colors = @{
        "Red"    = "$([char]27)[31m"
        "Green"  = "$([char]27)[32m"
        "Yellow" = "$([char]27)[33m"
        "Cyan"   = "$([char]27)[36m"
        "White"  = "$([char]27)[37m"
        "Reset"  = "$([char]27)[0m"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $plainMessage = "[$timestamp] $Message"
    
    # Use the requested color or default to White
    $colorCode = if ($colors.ContainsKey($Color)) { $colors[$Color] } else { $colors["White"] }
    $coloredMessage = "$colorCode$plainMessage$($colors['Reset'])"

    # Write to Information Stream (Stream 6) - visible in console by default in PS7+
    # For PS5.1, we set InformationAction to ensure visibility
    Write-Information $coloredMessage -InformationAction Continue
    
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

# Only import BurntToast if a notification is required
if ($howToDisplayName -eq "notification" -or $howToDisplayName -notmatch "rainmeter") {
    Import-Module BurntToast
}

LogThis "Polling every $pollMs ms" "Yellow"

# Track last filename
$lastFile = ""

while ($true) {

    # Decode TranscodedImageCache, from registry binary to string
    $bytes   = (Get-ItemProperty "HKCU:\Control Panel\Desktop").TranscodedImageCache
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
                
                # update the registry value with the clean name
                if ($writeRegistry) { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName }

                # Show toast notification
                New-BurntToastNotification -Text "Your Wallpaper: ", $cleanName
                LogThis "Notification sent for: $cleanName" "Green"

            } elseif ($howToDisplayName -eq "rainmeter") {
                
                # ONLY update the registry (Rainmeter requires this, regardless of $writeRegistry setting)
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName
                
                # Force Rainmeter to refresh and pick up the new registry value immediately
                if (Test-Path "C:\Program Files\Rainmeter\Rainmeter.exe") {
                    & "C:\Program Files\Rainmeter\Rainmeter.exe" !RefreshApp
                }
                
                LogThis "Registry updated and Rainmeter refreshed: $cleanName" "Cyan"

            } else {
                # Fallback: if value is null or unrecognized
                if ($writeRegistry) { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName }
                New-BurntToastNotification -Text "Your Wallpaper: ", $cleanName
                LogThis "Fallback triggered for: $cleanName" "Red"
            }

            $lastFile = $cleanName
        }
    }

    Start-Sleep -Milliseconds $pollMs
}
