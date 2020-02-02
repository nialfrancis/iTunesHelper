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
- Set-iTunesGenreMulti - 1 key genre setting for a playlist. Not a bulk change, but individually reviews each track and sets the genre, then moves on
- Find-iTunesDupes - shows duplicate or similar tracks
- Set-iTunesYear - Adds missing or updates the year value from Discogs

It does these things becuase this is how I like them formatted. It is quite simple to update the function to suit yourself.

## Version 2 Update
#### Minor title format updates and a Discogs API
The Discogs API is enabled by default (I assume you have a Discogs.com account, you'll need one to use this). The first time it tries to pull data from Discogs you will be guided through providing your personal API token. To disable year searches you can modify iTunesFunctions.psm1 and change $AutoUpdateYear = $true to $false to prevent Set-iTunesYear from being called.

Set-iTunesYear will find any matching track(s) on Discogs via their search API and return the year of the EARLIEST match. This can cause issues if you run against all the tracks of an album as the album date may be 2007 but the tracks were released at different times prior. I suggest setting the album year on all tracks when you rip them.

The search works pretty well, but sometimes Discogs can have trouble finding your track if the name isn't quite exact.

#### Set-iTunesGenreMulti changes
The genres used by this function have been split out into StyleLists.ps1 as they are custom so the next update will be easier for you.

There is also a new StyleList parameter (set to Common by default, or SecondReview to access the alternative list) to allow you to categorise different types of music at once. Essentially it is an alternative genre list so you could have electronic styles in common and rock in secondreview for example.

There is also a modifier added that can append a string or genre so you can have two items in the genre field. May be useful for DJs identifying tracks for a certain venue.
Remove-iTunesSecondaryGenres will remove this if you no longer need it.

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
#### As of the version 2 update in 2020, the macOS version has been deprecated due to divergence and lack of use
Download and install satimage osax http://www.satimage.fr/software/en/downloads/downloads_companion_osaxen.html

Open Script Editor and iTunes.

Copy the text from iTunesHelper/AppleScript/iTunes Formatter.scpt.txt into your Script Editor window.

In iTunes, select one or multiple tracks then go back to Script Editor and press the Run button.
