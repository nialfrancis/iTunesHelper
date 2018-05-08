# Author: Nial Francis
# Date: 08/05/2018
# Version 1.1
# LINK
#    https://github.com/nialfrancis/iTunesFormatter
# 
# EXAMPLE
#    Format-iTunesData
#    Will modify the selected track(s) in iTunes
#    from:
#    'I Can't Get No Sleep - Ken Lou 12" ft. India' by 'Masters At Work'
#    	to:
#    'I Can't Get No Sleep (Ken Lou 12")' by 'Masters At Work ft. India'

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
	
	return $str
}

function ProcessTrackName ($name) {
	$namearrres = @()
	
	# ALWAYS REPLACE SINGLE CHARS
	$name = $name.Replace([char]96,"'")
	$name = $name.Replace([char]8217,"'")
	$name = $name.Replace('[','(')
	$name = $name.Replace(']',')')
	
	if ($name  -cnotmatch "[a-z]+") {
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
	param
	(
		[switch]$MoveFeatured
	)
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	$TextInfo = (Get-Culture).TextInfo

	foreach ($track in $itunesobj.SelectedTracks) {
		$orign = $track.Name
		$origa = $track.Artist
		$tname = $orign

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

		if ($procname -cne $orign) {$track.Name = $procname.Trim(); $ch = 1}

		$procart = ProcessTrackName $track.Artist
		if ($artistadd) { $track.AlbumArtist = $procart; $procart = $procart + $artistadd }
		$artistadd = $null
		if ($procart -cne $origa) {$track.Artist = $procart.Trim(); $ch = 1}
		
		if ($ch -eq 1) { Write-Host "Processed: $orign - $origa" }
	}
}

function Format-iTunesNameFromTitle {
	param
	(
		[switch]$ArtistFirst
	)
	
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}

	foreach ($track in $itunesobj.SelectedTracks) {
		$orign = $track.Name
		
		if ($ArtistFirst) {
			$tart = ($track.Name -Split(' - '))[0]
			$tname = ($track.Name -Split(' - '))[1]
		} else {
			$tart = ($track.Name -Split(' - '))[1]
			$tname = ($track.Name -Split(' - '))[0]
		}
		
		$track.Artist = $tart.Trim()
		$track.Name = $tname.Trim()
		
		Write-Host "Processed: $orign"
	}
}

function ReplaceRegex ($str) {
	return $str -replace '\?','' -replace '\+','' -replace '\(','' -replace '\)',''
}

function Find-iTunesDupes {
	[cmdletbinding()]
	Param()
	$results = @()
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	
	if ($($itunesobj.SelectedTracks).Count -gt 3) {
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
			$tscore = Get-FuzzyMatchScore (ReplaceRegex $libtrack.Name) (ReplaceRegex $track.Name)
			$artistext = Get-FuzzyMatchScore (ReplaceRegex $libtrack.Artist) (ReplaceRegex $track.Artist)
			$lendelta = ([timespan]::Parse("0:$($libtrack.Time)")).TotalSeconds - ([timespan]::Parse("0:$($track.Time)")).TotalSeconds
			$lendelta = [System.Math]::Abs($lendelta)
			$score = $tscore
			$score += $artistext
			$score -= $lendelta * 10
			Write-Verbose "$($libtrack.Name) $($libtrack.Artist) $score = $tscore + $artistext - $($lendelta * 10)"
			if ( ($score -gt 1100) -and ($libtrack.TrackDatabaseID -ne $track.TrackDatabaseID) -and ($libtrack.Location) ) {
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

function Set-iTunesGenreMulti {
	if (!$itunesobj) {$script:itunesobj = New-Object -com iTunes.Application}
	
	# Update this list with your choices of keys and genre titles
	$genretable = [ordered]@{
		'D' = 'Deep House'
		'H' = 'House'
		'Z' = 'Skipped'
	}
	#
	
	$functionkeys = [ordered]@{
		'Tab' = 'Player skip 20s ahead'
		'~' = 'Review previous track'
		'Shift (left)' = 'Skip track'
	}
	
	Write-Output "Options:"
	
	$genretable.GetEnumerator() | Select-Object -Property @(
		@{ Name = 'Key'; Expression={ $_.Name }}
		@{ Name = 'Genre'; Expression={ $_.Value }}
	) | Format-Table

	$functionkeys.GetEnumerator() | Select-Object -Property @(
		@{ Name = 'Key'; Expression={ $_.Name }}
		@{ Name = 'Function'; Expression={ $_.Value }}
	) | Format-Table

	$itunesobj.Play()

	while ($true) {
		$newgenre = $false
		$skip = $false
		
		$key = $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
		
		switch ($key.VirtualKeyCode) {
			9   { $itunesobj.PlayerPosition = $itunesobj.PlayerPosition + 20 }
			16  { $skip = $true }
			192 { $itunesobj.PreviousTrack(); $itunesobj.PlayerPosition = 65 }
		}

		if ($genretable[[string]$key.Character]) {
			$newgenre = $genretable[[string]$key.Character]
		}
	
		if ($newgenre) {
			if ($itunesobj.CurrentTrack.Genre -eq $null) {$itunesobj.CurrentTrack.Genre = 'null'}
			$datatable = [PSCustomObject]@{
				'Name'		= $itunesobj.CurrentTrack.Name.PadRight(30,' ')
				'Artist'	= $itunesobj.CurrentTrack.Artist.PadRight(30,' ')
				'Old Genre'	= $itunesobj.CurrentTrack.Genre.PadRight(15,' ')
				'New Genre'	= $newgenre.PadRight(15,' ') }
			$itunesobj.CurrentTrack.Genre = $newgenre
			$datatable
		}
    
		if ($newgenre -or $skip) {
			$itunesobj.NextTrack()
			$itunesobj.PlayerPosition = 65
			$itunesobj.Play()
		}
	}
}

function Exit-iTunes {
	if ($itunesobj) {
		$itunesobj.quit()
		exit
	}
}