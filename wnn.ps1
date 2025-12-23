<#
.SYNOPSIS
	Monitor the current Windows desktop wallpaper and show a BurntToast notification when it changes.

.DESCRIPTION
	This script polls the current wallpaper cache (TranscodedImageCache) in the registry,
	extracts the currently active wallpaper file basename (withput path or extension) 
    and displays a Windows toast notification using the BurntToast module when the wallpaper changes. 
    Conceived for when wallpaper names are meaningful in some way (artist, photographer, title, year etc).
    It is intended to run continuously (e.g., from a scheduled task or startup shortcut).
    This is a companion script for my AutoTheme project, but can be used independently.

.LINK
	https://github.com/unalignedcoder/monitor-wallpaper

.NOTES
 initial commit
#>

# ============= Script Version ==============

$scriptVersion = "0.1.2"

# ============= Configuration ==============

# Write Wallpaper name in registry, for other apps/scripts to read
$writeRegistry = $false

# How often to poll for wallpaper changes (milliseconds)
$pollMs = 30000 #30 seconds

# ============= Script Logic ==============

# Requires BurntToast module
Import-Module BurntToast

Write-Output "Polling every $pollMs ms"

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

        # Strip unwanted prefix if present
        $cleanName = $filename -replace "^_0_AutoTheme_", ""

        if ($cleanName -ne $lastFile -and $cleanName) {

            # update the registry value with the clean name
            if ($writeRegistry) { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperName" -Value $cleanName }

            # Show toast notification using your AppId
            New-BurntToastNotification -Text "Your Wallpaper: ", $cleanName

            Write-Output "Your wallpaper: $cleanName"
            $lastFile = $cleanName
        }
    }

    Start-Sleep -Milliseconds $pollMs
}
