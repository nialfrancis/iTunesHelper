# Author: Nial Francis
# Date: 01/02/2020
# Version 2.1
# LINK
#    https://github.com/nialfrancis/iTunesHelper
# 
# EXAMPLE
#    Format-iTunesData
#    Will modify the selected track(s) in iTunes
#    from:
#    'I Can't Get No Sleep - Ken Lou 12" ft. India' by 'Masters At Work'
#    	to:
#    'I Can't Get No Sleep (Ken Lou 12")' by 'Masters At Work ft. India'

### VARS

$AutoUpdateYear = $true
$RegPath = "HKCU:\SOFTWARE\nialfrancis\iTunesHelper"

### FUNCTIONS

function GetDiscogsAPIToken {
	# ENSURE REGISTRY PATH EXISTS AND PULL PREVIOUS TOKEN
	if (!(Test-Path $RegPath)) {
		New-Item -Path $RegPath -Force | Out-Null
	}
	
	$regtokenset = (Get-ItemProperty -Path $RegPath).DiscogsAPIToken
	$script:dapitoken = $regtokenset
	
	do {
		# LOOP THROUGH AUTHENTICATION TEST AND APIKEY PROMPT UNTIL A WORKING KEY IS ENTERED
		try {
			if ($dapitoken -eq $null) {throw}
			$dac = Invoke-RestMethod "https://api.discogs.com/oauth/identity" -Headers @{ Authorization="Discogs token=$dapitoken" } -ErrorAction Stop
		} catch {
			if (!($devpageopen)) {
				$devpageopen = $true
			
				# OPEN THE KEY GENERATION PAGE TO HELP THE USER ACQUIRE IT
				Start-Process "https://www.discogs.com/settings/developers"
				Write-Host -ForegroundColor Yellow "The Discogs page which allows you to generate a token has been opened. Please paste your Personal Access Token (click 'Generate new token' if none exists).`nIf the page did not open, browse to https://www.discogs.com/settings/developers"
			}
			$dapitoken = Read-Host "Personal Access Token"
		}
	} while ( $dac.username -eq $null )
	
	if ($dapitoken -ne $regtokenset) {
		Set-ItemProperty -Path $RegPath -Name 'DiscogsAPIToken' -Value $dapitoken
	}
}

function StandardiseNamePart ($str) {
	$str = $TextInfo.ToTitleCase($str.ToLower())
	
	# WHOLE STRING MATCH
	if ($str -eq 'v') { $str = $str.Replace('V',' v ') }
	$str = $str -replace ('Presents\.|Presents|^Pr$|Pres\.|^Pres$|Pr\.','pres.')
	$str = $str -replace ('Featuring\.|Featuring|^Ft$|Feat\.|^Feat$|Ft\.','ft.')
	
	# PARTIAL STRING MATCH
	$str = $str -replace ('Dj','DJ')
	$str = $str -replace ('_',' ')
	$str = $str -replace ('Rmx','Remix')
	$str = $str -replace ('F\./|Ft\./','ft. ')
	$str = $str -replace ('Vs\.|vs','vs.')
	
	# Ensure Mctest is McTest
	$str = $str -replace '^(Mc).(.*)',('${1}' + ([string]$str[2]).ToUpper() + '${2}')
	
	return $str
}

function ProcessTrackName ($name) {
	$namearrres = @()
	
	# ALWAYS REPLACE SINGLE CHARS
	$name = $name.Replace([char]96,"'")
	$name = $name.Replace([char]8217,"'")
	$name = $name.Replace('[','(')
	$name = $name.Replace(']',')')
	$name = $name.Replace('{','(')
	$name = $name.Replace('}',')')
	
	if (($name.Length -gt 4) -and ($name -cnotmatch "[a-z]+")) {
		return StandardiseNamePart $name
	}
	
	$namearr = $name.Split(' ')
	
	foreach ($part in $namearr) {
		# IF THE ELEMENT IS SHORT AND CONTAINS A BRACKET
		if ($part -cmatch '\(|\)') {
			if (($part.Length -le 4) -and ($part -cmatch "^[A-Z0-9()]*$")) {
				$namearrres += $part
			} else {
				$part = StandardiseNamePart $part
				$namearrres += $part
			}
		# IF THE ELEMENT IS SHORT
		} elseif (($part.Length -le 3) -and ($part -cmatch "^[A-Z0-9\-\+]*$")) {
			$namearrres += $part
		} else {
			$part = StandardiseNamePart $part
			$namearrres += $part
		}
	}

	return $namearrres -join (' ')
}

function Format-iTunesData {
	[cmdletbinding()]
	param()
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	$TextInfo = (Get-Culture).TextInfo

	foreach ($track in $itunesobj.SelectedTracks) {
		$orign = $track.Name
		$origa = $track.Artist
		$tname = $orign.Trim()

		if ( $tname.Contains(' -') ) {
			$tname = $tname.Replace('- ','-')
			$tname = "$($tname.Split('-')[0])($($tname.Split('-')[1]))"
		}
		
		$procname = ProcessTrackName $tname

		$brackarr = ([regex]"\(([^)]*)\)").Matches($procname)
		foreach ($item in $brackarr) {
			if ($item.Groups[1].Value -like "ft. *") {
				$artistadd = ' ' + $item.Groups[1].Value
				$replstr = ' ' + $item.Groups[0].Value
				$procname = $procname.Replace($replstr,'')
			}
		}

		if ($procname -like "*ft.*") {
			$lfarr = $procname -split ('ft. ')
			$procname = $($lfarr[0]).Trim()
			$artistadd = ' ft. ' + $lfarr[1]
			
			if ($artistadd[-1] -eq ')') {
				$artistadd = $artistadd -replace ".$"
				$procname = $procname + ')'
			}
		}

		if ($procname -cne $orign) {
			$chn = 1
			$track.Name = $procname.Trim()
		}

		$procart = ProcessTrackName $track.Artist
		if ($artistadd) {
			$track.AlbumArtist = $procart
			$procart = $procart + $artistadd
		}
		$artistadd = $null
		if ($procart -cne $origa) {
			$cha = 1
			$track.Artist = $procart.Trim()
		}
		
		if ($cha+$chn -ge 1) {
			Write-Host -NoNewLine 'Processed title: '
			Write-Host -NoNewLine -Foreground $(if ($chn -eq 1) {'Yellow'} else {'White'}) "$orign"
			Write-Host -NoNewLine ' - '
			Write-Host -Foreground $(if ($cha -eq 1) {'Yellow'} else {'White'}) "$origa"
		}
		
		if ($AutoUpdateYear) {
			Set-iTunesTrackYear
		}
	}
}

function Format-iTunesNameFromTitle {
	param(
		[switch]$ArtistFirst
	)
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	foreach ($track in $itunesobj.SelectedTracks) {
		$orign = $track.Name
		
		if ($ArtistFirst) {
			$tart = ($track.Name -Split('-'))[0]
			$tname = ($track.Name -Split('-'))[1]
		} else {
			$tart = ($track.Name -Split('-'))[1]
			$tname = ($track.Name -Split('-'))[0]
		}
		
		$track.Artist = $tart.Trim()
		$track.Name = $tname.Trim()
		
		Write-Host "Processed: $orign"
	}
}

function ReplaceRegex ($str) {
	return $str -replace '\?','' -replace '\+','' -replace '\(','' -replace '\)',''
}

function Set-iTunesTrackYear {
	[cmdletbinding()]
	param(
		[switch]$Overwrite
	)
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	Add-Type -AssemblyName System.Web
	
	foreach ($track in $itunesobj.SelectedTracks) {
		if (!$track.Year -or $Overwrite ) {
			if (!$dapitoken) { GetDiscogsAPIToken }
			
			$urleartist = [System.Web.HttpUtility]::UrlEncode( ($track.Artist -replace "'",'') )
			$urletrack = [System.Web.HttpUtility]::UrlEncode( ($track.Name -replace "'",'') )
			
			# DISCOGS SEARCHES FROM MORE TO LESS SPECIFIC
			# TRY A BASIC ARTIST + TRACK SEARCH EG. FOR A SINGLE
			$res = Invoke-RestMethod "https://api.discogs.com/database/search?track=$urletrack&artist=$urleartist" -Headers @{ Authorization="Discogs token=$dapitoken" }
			# IF NOTHING, TRY AN ALBUM SEARCH
			if (!$res.results -and $track.Album) {
				$urlealbum = [System.Web.HttpUtility]::UrlEncode( ($track.Album -replace "'",'') )
				$res = Invoke-RestMethod "https://api.discogs.com/database/search?type=release&track=$urletrack&title=$urlealbum" -Headers @{ Authorization="Discogs token=$dapitoken" }
			}
			# IF NOTHINNG, TRY A BROAD ARTIST + TRACK SEARCH
			if (!$res.results) {
				$res = Invoke-RestMethod "https://api.discogs.com/database/search?track=$urletrack&query=$urleartist" -Headers @{ Authorization="Discogs token=$dapitoken" }
			}
			
			try {
				$ysel = ($res.results | Where-Object { $_.year -ne $null } | Select-Object -Property year,id,type | Sort-Object -Property year)[0]
			} catch {
				Write-Host "No results for",$track.Artist,'-',$track.Name
				return
			}
			
			$discogsid = $ysel.type[0]+$ysel.id
			Write-Host -NoNewLine 'Modified year:',$track.Artist,'-',$track.Name,'FROM:',$track.Year,'TO: '
			Write-Host -NoNewLine -Foreground 'Yellow' $ysel.year
			Write-Host " from Discogs entry $discogsid"
			$track.Year = $ysel.year
		} else {
			Write-Verbose "Year unchanged"
		}
	}
	return
}

function Find-iTunesDupes {
	[cmdletbinding()]
	param()
	$results = @()
	$threshold = 1100
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	
	if ($($itunesobj.SelectedTracks).Count -gt 3) {
		Write-Progress -Activity "Converting iTunes Library to Powershell Object"
		$latestlib = $itunesobj.LibraryPlaylist.Tracks
		$latestlib = $latestlib | Where-Object {$_.Location -ne $null}
	}

	foreach ($track in $itunesobj.SelectedTracks) {
		Write-Progress -Activity "Matching" -Status "Track $($track.Index)"
		
		if ($latestlib) {
			if ($track.Name.Length -ge 3) {
				$contenders = $latestlib | Where-Object {$_.Name.Length -ge 3} | Where-Object {$_.Name.SubString(0,3) -eq $track.Name.SubString(0,3)}
			} else {
				$contenders = $latestlib | Where-Object {$_.Name -eq $track.Name}
			}
		} else {
			if ($track.Name.Length -ge 3) {
				$contenders = $itunesobj.LibraryPlaylist.Tracks | Where-Object {$_.Name.Length -ge 3} | Where-Object {$_.Name.SubString(0,3) -eq $track.Name.SubString(0,3)} | Where-Object {$_.Location -ne $null}
			} else {
				$contenders = $itunesobj.LibraryPlaylist.Tracks | Where-Object {$_.Name -eq $track.Name} | Where-Object {$_.Location -ne $null}
			}
		}

		foreach ($libtrack in $contenders) {
		
			if ((ReplaceRegex $libtrack.Name) -eq (ReplaceRegex $track.Name)) {
				$tscore = $threshold
			} else {
				$tscore = Get-FuzzyMatchScore (ReplaceRegex $libtrack.Name) (ReplaceRegex $track.Name)
			}
			
			$artistext = Get-FuzzyMatchScore (ReplaceRegex $libtrack.Artist) (ReplaceRegex $track.Artist)
			$lendelta = ([timespan]::Parse("0:$($libtrack.Time)")).TotalSeconds - ([timespan]::Parse("0:$($track.Time)")).TotalSeconds
			$lendelta = [System.Math]::Abs($lendelta)
			$score = $tscore
			$score += $artistext
			$score -= $lendelta * 10
			
			Write-Verbose "$($libtrack.Name) $($libtrack.Artist) $score = $tscore + $artistext - $($lendelta * 10)"
			
			if ( ($score -gt $threshold) -and ($libtrack.TrackDatabaseID -ne $track.TrackDatabaseID) -and ($libtrack.Location) ) {
				$match = [PSCustomObject]@{
					'Track'  = $track.Index
					'Score'  = $score
					'Name'   = $libtrack.Name
					'Artist' = $libtrack.Artist
					'Length' = $libtrack.Time
					'Diff'   = $lendelta }
				$results += $match
			}
		}
	}
	
	$results | Format-Table -AutoSize
}

function Remove-iTunesSecondaryGenres {
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	
	foreach ($track in $itunesobj.SelectedTracks) {
		$dg = ($track.Genre -Split (', '))[0]
		$track.Genre = $dg
	}
}

function Set-iTunesGenreMulti {
	param(
		[Parameter()]
		[ValidateSet('Common','SecondReview')]
		[string]$StyleList = 'Common'
	)
	
	if (!($stylelistloaded)) { . "$PSScriptRoot\StyleLists.ps1"; 'loaded' }
	
	if ($StyleList -eq 'Common') {
		$genretable = $genrecommon
	} elseif ($StyleList -eq 'SecondReview') {
		$genretable = $genrereview
	}
	
	$functionkeys = [ordered]@{
		'Tab'		= 'Player skip 20s ahead'
		'~'			= 'Review previous track'
		'Shift'		= 'Skip track'
	}
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	
	Write-Output "Options:`n"
	
	( $genretable.GetEnumerator() | Select-Object -Property @(
		@{ Name = 'Key'; Expression={ $_.Name.PadRight(12,' ') }}
		@{ Name = 'Genre'; Expression={ $_.Value }}
	) | Format-Table | Out-String).Trim()
	
	Write-Output ""
	
	( $functionkeys.GetEnumerator() | Select-Object -Property @(
		@{ Name = 'Key'; Expression={ $_.Name.PadRight(12,' ') }}
		@{ Name = 'Function'; Expression={ $_.Value }}
	) | Format-Table | Out-String ).Trim()
	
	Write-Output ""
	
	( $addgenre.GetEnumerator() | Select-Object -Property @(
		@{ Name = 'Key'; Expression={ $_.Name.PadRight(12,' ') }}
		@{ Name = 'Adds Genre'; Expression={ $_.Value }}
	) | Format-Table | Out-String ).Trim()
	
	$itunesobj.Play()
	
	while ($true) {
		if ($itunesobj.CurrentTrack.Genre -eq $null) {
			$oldgenre = 'null'
		} else {
			$oldgenre = $itunesobj.CurrentTrack.Genre
		}
		$newgenre = $false
		$skip = $false
		$phpercent = ($itunesobj.PlayerPosition / $itunesobj.CurrentTrack.Finish) * 100
		
		
		Write-Progress -Activity ("{0}. {1}" -f $itunesobj.CurrentTrack.Index,$itunesobj.CurrentTrack.Name) -Status $itunesobj.CurrentTrack.Artist -CurrentOperation $oldgenre -PercentComplete $phpercent
				
		$key = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		
		switch ($key.VirtualKeyCode) {
			9   { $itunesobj.PlayerPosition = $itunesobj.PlayerPosition + 20 }
			16  { $skip = $true }
			192 { $itunesobj.PreviousTrack(); $itunesobj.PlayerPosition = 65 }
		}
		
		if ($genretable[[string]$key.Character]) {
			$newgenre = $genretable[[string]$key.Character]
		}
		
		foreach ($modifier in ($key.ControlKeyState -split(', ').Trim() )) {
			if ($addgenre[$modifier] -and ($key.Character -or $skip)) {
				if ($skip -eq $true) {$newgenre = $oldgenre; $skip = $false}
				if ($newgenre -notmatch $addgenre[$modifier]) {
					$newgenre = @($newgenre, $addgenre[$modifier]) -join ', '
				}
			}
		}
		
		if ($newgenre) {
			
			try {
				$itunesobj.CurrentTrack.Genre = $newgenre
			} catch {
				$newgenre = 'Not Settable'
			}
			
			[PSCustomObject]@{
				'Name'		= $itunesobj.CurrentTrack.Name.PadRight(40,' ')
				'Artist'	= $itunesobj.CurrentTrack.Artist.PadRight(30,' ')
				'Old Genre'	= $oldgenre.PadRight(30,' ')
				'New Genre'	= $newgenre.PadRight(30,' ')
			}
			
			$datatable
		}
		
		if ($newgenre -or $skip) {
			try {
				$itunesobj.NextTrack()
				$itunesobj.PlayerPosition = 65
				$itunesobj.Play()
			} catch {}
		}
	}
}

function Exit-iTunes {
	if ($itunesobj) {
		$itunesobj.quit()
		exit
	}
}