function Format-iTunesData {

if (!$itunesobj) {$itunesobj = New-Object -com iTunes.Application}
$TextInfo = (Get-Culture).TextInfo

foreach ($track in $itunesobj.SelectedTracks) {
	$oname = $track.Name
	$oart = $track.Artist
	
	$name = $TextInfo.ToTitleCase($track.Name.ToLower())

	if ( $name.Contains(' -') ) {
		$name = $name.Replace('- ','-')
		$name = "$($name.Split('-')[0])($($name.Split('-')[1]))"
	}

	$name = $name.Replace('[','(')
	$name = $name.Replace(']',')')
	$name = $name -replace 'Vs\.|vs','vs.'

	if ($oname -cne $name) {$track.Name = $name.Trim(); $ch = 1}

	$art = $TextInfo.ToTitleCase($track.Artist.ToLower())
	
	$art = $art -replace 'Presents\.|Presents','pres.'
	$art = $art -replace 'Featuring\.|Featuring|Feat\.|Feat','ft.'
	$art = $art -replace 'Vs\.|vs','vs.'
	
	if ($oart -cne $art) {$track.Artist = $art.Trim(); $ch =1}
	
	if ($ch -eq 1) { Write-Host "Processed: $oname - $oart" }
}
}