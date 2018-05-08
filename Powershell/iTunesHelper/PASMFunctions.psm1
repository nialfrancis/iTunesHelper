function Get-CommonPrefix {
    <#
        .SYNOPSIS
            Find the common prefix of two strings.
        .DESCRIPTION
            This function will get the common prefix of two strings; that is, all
            the letters that they share, starting from the beginning of the strings.
        .EXAMPLE
            Get-CommonPrefix 'Card' 'Cartoon'
            Will get the common prefix of both string. Should output 'car'.
        .LINK
            https://communary.wordpress.com/
            https://github.com/gravejester/Communary.PASM
        .INPUTS
            System.String
        .OUTPUTS
            System.String
        .NOTES
            Author: Ã˜yvind Kallstad
            Date: 03.11.2014
            Version 1.1
            Dependencies: none
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$String1,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$String2,

        # Maximum length of the returned prefix.
        [Parameter()]
        [int]$MaxPrefixLength,

        # Makes matches case-sensitive. By default, matches are not case-sensitive.
        [Parameter()]
        [switch] $CaseSensitive
    )

    if (-not($CaseSensitive)) {
        $String1 = $String1.ToLowerInvariant()
        $String2 = $String2.ToLowerInvariant()
    }

    $outputString = New-Object 'System.Text.StringBuilder'
    $shortestStringLength = [Math]::Min($String1.Length,$String2.Length)

    # Let the maximum prefix length be the same as the length of the shortest of
    # the two input strings, unless defined by the MaxPrefixLength parameter.
    if (($shortestStringLength -lt $MaxPrefixLength) -or ($MaxPrefixLength -eq 0)) {
        $MaxPrefixLength = $shortestStringLength
    }

    # Loop from the start and add any characters found that are equal
    for ($i = 0; $i -lt $MaxPrefixLength; $i++) {
        if ($String1[$i] -ceq $String2[$i]) {
            [void]$outputString.Append($String1[$i])
        }
        else { break }
    }

    Write-Output $outputString.ToString()
}

function Get-FuzzyMatchScore {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string] $Search,

        [Parameter(Position = 1)]
        [string] $String
    )

    $score = 100

    # Use approximate string matching to get some values needed to calculate the score of the result
    $longestCommonSubstring = Get-LongestCommonSubstring -String1 $String -String2 $Search
    $levenshteinDistance = Get-LevenshteinDistance -String1 $String -String2 $Search
    $commonPrefix = Get-CommonPrefix -String1 $String -String2 $Search

    # By running the result through this regex pattern we get the length of the match as well as the
    # the index of where the match starts. The shorter the match length and the index, the more
    # score will be added for the match.
    $regexMatchFilter = $Search.ToCharArray() -join '.*?'
    $match = Select-String -InputObject $String -Pattern $regexMatchFilter -AllMatches
    $matchLength = ($match.Matches | Sort-Object Length | Select-Object -First 1).Value.Length
    $matchIndex = ($match.Matches | Sort-Object Length | Select-Object -First 1).Index

    # Calculate score
    $score = $score - $levenshteinDistance
    $score = $score * $longestCommonSubstring.Length
    $score = $score - $matchLength
    $score = $score - $matchIndex

    if ($commonPrefix) {
        $score =  $score + $commonPrefix.Length
    }

    Write-Output $score
}

function Get-HammingDistance {
    <#
        .SYNOPSIS
            Get the Hamming Distance between two strings or two positive integers.
        .DESCRIPTION
            The Hamming distance between two strings of equal length is the number of positions at which the
            corresponding symbols are different. In another way, it measures the minimum number of substitutions
            required to change one string into the other, or the minimum number of errors that could have
            transformed one string into the other. Note! Even though the original Hamming algorithm only works for
            strings of equal length, this function supports strings of unequal length as well.
            The function also calculates the Hamming distance between two positive integers (considered as binary
            values); that is, it calculates the number of bit substitutions required to change one integer into
            the other.
        .EXAMPLE
            Get-HammingDistance 'karolin' 'kathrin'
            Calculate the Hamming distance between the two strings. The result is 3.
        .EXAMPLE
            Get-HammingDistance 'karolin' 'kathrin' -NormalizedOutput
            Calculate the normalized Hamming distance between the two strings. The result is 0.571428571428571.
        .EXAMPLE
            Get-HammingDistance -Int1 61 -Int2 15
            Calculate the hamming distance between 61 and 15. The result is 3.
        .LINK
            http://en.wikipedia.org/wiki/Hamming_distance
            https://communary.wordpress.com/
            https://github.com/gravejester/Communary.PASM
        .NOTES
            Author: Ã˜yvind Kallstad
            Date: 03.11.2014
            Version: 1.0
    #>
    [CmdletBinding(DefaultParameterSetName = 'String')]
    param (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string] $String1,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string] $String2,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Integer')]
        [ValidateNotNullOrEmpty()]
        [uint32] $Int1,

        [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'Integer')]
        [ValidateNotNullOrEmpty()]
        [uint32] $Int2,

        # Makes matches case-sensitive. By default, matches are not case-sensitive.
        [Parameter(ParameterSetName = 'String')]
        [switch] $CaseSensitive,

        # Normalize the output value. When the output is not normalized the maximum value is the length of the longest string, and the minimum value is 0,
        # meaning that a value of 0 is a 100% match. When the output is normalized you get a value between 0 and 1, where 1 indicates a 100% match.
        [Parameter(ParameterSetName = 'String')]
        [switch] $NormalizeOutput
    )

    try {
        if ($PSCmdlet.ParameterSetName -eq 'String') {
            # handle case insensitivity
            if (-not($CaseSensitive)) {
                $String1 = $String1.ToLowerInvariant()
                $String2 = $String2.ToLowerInvariant()
            }

            # set initial distance
            $distance = 0

            # get max and min length of the input strings
            $maxLength = [Math]::Max($String1.Length,$String2.Length)
            $minLength = [Math]::Min($String1.Length,$String2.Length)

            # calculate distance for the length of the shortest string
            for ($i = 0; $i -lt $minLength; $i++) {
                if (-not($String1[$i] -ceq $String2[$i])) {
                    $distance++
                }
            }

            # add the remaining length to the distance
            $distance = $distance + ($maxLength - $minLength)

            if ($NormalizeOutput) {
                Write-Output (1 - ($distance / $maxLength))
            }

            else {
                Write-Output $distance
            }
        }

        else {
            $distance = 0
            $value = $Int1 -bxor $Int2
            while ($value -ne 0) {
                $distance++
                $value = $value -band ($value - 1)
            }
            Write-Output $distance
        }
    }

    catch {
        Write-Warning $_.Exception.Message
    }
}

function Get-LevenshteinDistance {
    <#
        .SYNOPSIS
            Get the Levenshtein distance between two strings.
        .DESCRIPTION
            The Levenshtein Distance is a way of quantifying how dissimilar two strings (e.g., words) are to one another by counting the minimum number of operations required to transform one string into the other.
        .EXAMPLE
            Get-LevenshteinDistance 'kitten' 'sitting'
        .LINK
            http://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Levenshtein_distance#C.23
            http://en.wikipedia.org/wiki/Edit_distance
            https://communary.wordpress.com/
            https://github.com/gravejester/Communary.PASM
        .NOTES
            Author: Ã˜yvind Kallstad
            Date: 07.11.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$String1,

        [Parameter(Position = 1)]
        [string]$String2,

        # Makes matches case-sensitive. By default, matches are not case-sensitive.
        [Parameter()]
        [switch] $CaseSensitive,

        # A normalized output will fall in the range 0 (perfect match) to 1 (no match).
        [Parameter()]
        [switch] $NormalizeOutput
    )

    if (-not($CaseSensitive)) {
        $String1 = $String1.ToLowerInvariant()
        $String2 = $String2.ToLowerInvariant()
    }

    $d = New-Object 'Int[,]' ($String1.Length + 1), ($String2.Length + 1)

    try {
        for ($i = 0; $i -le $d.GetUpperBound(0); $i++) {
            $d[$i,0] = $i
        }

        for ($i = 0; $i -le $d.GetUpperBound(1); $i++) {
            $d[0,$i] = $i
        }

        for ($i = 1; $i -le $d.GetUpperBound(0); $i++) {
            for ($j = 1; $j -le $d.GetUpperBound(1); $j++) {
                $cost = [Convert]::ToInt32((-not($String1[$i-1] -ceq $String2[$j-1])))
                $min1 = $d[($i-1),$j] + 1
                $min2 = $d[$i,($j-1)] + 1
                $min3 = $d[($i-1),($j-1)] + $cost
                $d[$i,$j] = [Math]::Min([Math]::Min($min1,$min2),$min3)
            }
        }

        $distance = ($d[$d.GetUpperBound(0),$d.GetUpperBound(1)])

        if ($NormalizeOutput) {
            Write-Output (1 - ($distance) / ([Math]::Max($String1.Length,$String2.Length)))
        }

        else {
            Write-Output $distance
        }
    }

    catch {
        Write-Warning $_.Exception.Message
    }
}

function Get-LongestCommonSubstring {
    <#
        .SYNOPSIS
            Get the longest common substring of two strings.
        .DESCRIPTION
            Get the longest common substring of two strings.
        .EXAMPLE
            Get-LongestCommonSubstring 'Karolin' 'kathrin' -CaseSensitive
        .LINK
            https://fuzzystring.codeplex.com/
            http://en.wikipedia.org/wiki/Longest_common_substring_problem
            https://communary.wordpress.com/
            https://github.com/gravejester/Communary.PASM
        .NOTES
            Adapted to PowerShell from code by Kevin Jones (https://fuzzystring.codeplex.com/)
            Author: Ã˜yvind Kallstad
            Date: 03.11.2014
            Version: 1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string] $String1,

        [Parameter(Position = 1)]
        [string] $String2,

        [Parameter()]
        [switch] $CaseSensitive
    )

    if (-not($CaseSensitive)) {
        $String1 = $String1.ToLowerInvariant()
        $String2 = $String2.ToLowerInvariant()
    }

    $array = New-Object 'Object[,]' $String1.Length, $String2.Length
    $stringBuilder = New-Object System.Text.StringBuilder
    $maxLength = 0
    $lastSubsBegin = 0

    for ($i = 0; $i -lt $String1.Length; $i++) {
        for ($j = 0; $j -lt $String2.Length; $j++) {
            if ($String1[$i] -cne $String2[$j]) {
                $array[$i,$j] = 0
            }
            else {
                if (($i -eq 0) -or ($j -eq 0)) {
                    $array[$i,$j] = 1
                }
                else {
                    $array[$i,$j] = 1 + $array[($i - 1),($j - 1)]
                }
                if ($array[$i,$j] -gt $maxLength) {
                    $maxLength = $array[$i,$j]
                    $thisSubsBegin = $i - $array[$i,$j] + 1
                    if($lastSubsBegin -eq $thisSubsBegin) {
                        [void]$stringBuilder.Append($String1[$i])
                    }
                    else {
                        $lastSubsBegin = $thisSubsBegin
                        $stringBuilder.Length = 0
                        [void]$stringBuilder.Append($String1.Substring($lastSubsBegin, (($i + 1) - $lastSubsBegin)))
                    }
                }
            }
        }
    }

    Write-Output $stringBuilder.ToString()
}