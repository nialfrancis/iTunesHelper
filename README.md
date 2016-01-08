# iTunesFormatter
A PowerShell track name formatting system.

## Description

Formats track names and artists in iTunes. It will:
- Ensure the fields have title capitalisation.
- Replace square brackets [] with round brackets ().
- Modify track names with dash remix (eg. title - mix) to title (mix).
- Contracts presents/featuring in artist names to pres./ft.
- Displays the original track data in the PS window. Useful in case it breaks something.

It does these things becuase this is how I like them formatted. It is quite simple to update the function to suit yourself.

## Usage

Dump the iTumesFormatter directory into your modules directory. Run ' $env:PSModulePath.Split(';')[0] ' to display it.

Open PowerShell and run Import-Module iTunesFormatter.

In iTunes, select one or multiple tracks then go back to PowerShell and run Format-iTunesData.