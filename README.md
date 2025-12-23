# Wallpaper Name Notification

A lightweight PowerShell utility that monitors your desktop wallpaper changes and sends a Windows system notification displaying the name of the current image.

<img width="688" height="432" alt="image" src="https://github.com/user-attachments/assets/2f323ce1-03ce-4350-a23c-b5dd34e7dd0b" />


## Features

This script detects Slideshow changes to the Windows desktop wallpaper and displays a notification with the name of the wallpaper (minus path or exentension) in it.

The notification appears via the regular Windows Action Center, taking advantage of the PowerShell "BurnToast" notification module.

This script is particulary indicated for slideshows in which wallpapers have intelligible names (photographer, artist, title, mood, subject, season etc.), but, with approrpiately named wallpapers, it could be used to send any sort of message as the slideshow progresses.

## Installation
Download the script `wnn.ps1`.

Set Execution Policy: Ensure you can run PowerShell scripts locally by running this in an Administrator PowerShell window:

`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

Run the script: Right-click wnn.ps1 and select Run with PowerShell, or call it from the terminal:

`./wnn.ps1`

## Configuration and Usage

Within the script file, you can modify the `$pollMs` variable, to indicate the frequency at which the wallpaper should be monitored

After having been run once, the script will contiue monitoring wallpaper changes and showing notifications until interrupted.