# iTunesFormatter
An iTunes electronic music formatting system for PowerShell and macOS.

## Description

Formats track names and artists in iTunes. It will:
- Ensure the fields have title capitalisation.
- Replace square brackets [] with round brackets ().
- Modify track names with dash remix (eg. title - mix) to title (mix).
- Contracts presents/featuring in artist names to pres./ft.
- Displays the original track data in the PowerShell host or Message log . Useful in case it breaks something.

It does these things becuase this is how I like them formatted. It is quite simple to update the function to suit yourself.

## Usage

###Windows:
Dump the iTumesFormatter directory into your modules directory. Run ' $env:PSModulePath.Split(';')[0] ' to display it.

Open PowerShell and run Import-Module iTunesFormatter.

In iTunes, select one or multiple tracks then go back to PowerShell and run Format-iTunesData.

###macOS:
Download and install satimage osax http://www.satimage.fr/software/en/downloads/downloads_companion_osaxen.html

Open Script Editor and iTunes.

Copy the text from iTunesFormatter/iTunes Formatter.scpt.txt into your Script Editor window.

In iTunes, select one or multiple tracks then go back to Script Editor and press the Run button.
