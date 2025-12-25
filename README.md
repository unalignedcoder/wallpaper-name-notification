# Wallpaper Name Notification

A lightweight PowerShell utility that monitors the current Windows Slideshow desktop wallpaper, and displays the wallpaper name in a Rainmeter overlay or Windows notification.

## Features

This script detects Slideshow changes to the Windows desktop wallpaper and retrieves the Wallpaper name, without extension or path.

It then displays the name either in a [BurnToast](https://github.com/Windos/BurntToast) notification, with the name of the wallpaper (minus path or exentension) in it:

<img width="688" height="432" alt="image" src="https://github.com/user-attachments/assets/2f323ce1-03ce-4350-a23c-b5dd34e7dd0b" />
<p>&nbsp;</p>

Or in a [Rainmeter](https://ranimeter.net) overlay on the desktop background:

<img width="1251" height="581" alt="image" src="https://github.com/user-attachments/assets/1ee3a21a-eacd-4589-a316-fff5b7c3df62" />
<p>&nbsp;</p>

The name of the wallpaper can be clicked, to open a google search with the wallpaper name as search term.

The included `wnn.ini` file is ready to be loaded in Rainmeter, but it can of course be modified in infinite ways, as preferred by the user.

## Purpose
This script is particulary indicated for slideshows in which wallpapers have intelligible names (photographer, artist, title, mood, subject, season etc.), but, with approrpiately named wallpapers, it could be used to send any sort of inspiring, funny or interesting messages to the user, as the slideshow progresses.

## Installation
Download the [latest release](https://github.com/unalignedcoder/wallpaper-name-notification/releases).

If you intend to use the Rainmeter overlay, load the `wnn.ini` skin file in Rainmeter.

Run the script: `./wnn.ps1`

## Configuration and Usage

Within the script file, you can modify a number of options. Explanations are included.

<img width="890" height="675" alt="image" src="https://github.com/user-attachments/assets/366f0fba-8f7f-4b06-a807-7dd9862afbba" />

After having been run once, the script will contiue monitoring wallpaper changes and showing notifications until interrupted.

The powershell window can be completely hidden if ran from Task Scheduler or a shortcut, with the `-WindowStyle hidden` switch.
