# iTunesHelper
An iTunes electronic music formatting system for PowerShell and macOS. The PowerShell version includes additional functions for cataloguing.

Thanks to Øyvind Kallstad https://github.com/gravejester for the string matching component of this module in PASMFunctions.psm1.

## Description

Formats track names and artists in iTunes. It will:
- Ensure the fields have title capitalisation.
- Replace square brackets [] with round brackets ().
- Modify track names with dash remix (eg. title - mix) to title (mix).
- Contracts presents/featuring in artist names to pres./ft.
- Displays the original track data in the PowerShell host or Message log. Useful in case it breaks something.
- Moves featured (ft.) artists from title to artist fields

Additional PowerShell features:
- Set-iTunesGenreMulti - 1 key genre setting for a playlist. Not a bulk change, but individually reviews each track and sets the genre, then moves on.
- Find-iTunesDupes - shows duplicate or similar tracks.

It does these things becuase this is how I like them formatted. It is quite simple to update the function to suit yourself.

## Example (PowerShell)

iTunes track selected:
> Title: I Can't Get No Sleep - Ken Lou 12" ft. India

> Artist: Masters At Work

PS> Format-iTunesData
> Processed: I Can't Get No Sleep - Ken Lou 12" ft. India - Masters At Work

iTunes track selected:
> Title: I Can't Get No Sleep (Ken Lou 12")

> Artist: Masters At Work ft. India

## Usage

### Windows:
Dump the iTunesHelper directory into your modules directory. Run ' $env:PSModulePath.Split(';')[0] ' to display it.

In iTunes, select one or multiple tracks then go back to PowerShell and run Format-iTunesData.

### macOS:
Download and install satimage osax http://www.satimage.fr/software/en/downloads/downloads_companion_osaxen.html

Open Script Editor and iTunes.

Copy the text from iTunesHelper/AppleScript/iTunes Formatter.scpt.txt into your Script Editor window.

In iTunes, select one or multiple tracks then go back to Script Editor and press the Run button.
