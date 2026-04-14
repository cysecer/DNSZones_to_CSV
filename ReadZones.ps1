function Convert-DnsZoneTextToCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ZoneText,

        [Parameter(Mandatory)]
        [string]$ZoneName,

        [Parameter(Mandatory)]
        [string]$SourceFile,

        [string]$OutputCsvPath = ".\dns-zone.csv"
    )

    $records = New-Object System.Collections.Generic.List[object]
    $zone = $ZoneName

    $lines = $ZoneText -replace "`r", "" -split "`n"

    $currentName = "@"
    $inSoa = $false
    $soaBuffer = New-Object System.Collections.Generic.List[string]

    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()

        if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith(";") -or $line.StartsWith("//")) {
            continue
        }

        if ($line -match '^(.*?)(\s*;.*)?$') {
            $line = $matches[1].Trim()
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($inSoa) {
            $soaBuffer.Add($line)

            if ($line -match '\)') {
                $inSoa = $false
                $soaText = ($soaBuffer -join ' ')

                if ($soaText -match '^(?<name>\S+)\s+(?:(?<ttl>\d+)\s+)?(?:(?<class>IN)\s+)?SOA\s+(?<mname>\S+)\s+(?<rname>\S+)\s*\(\s*(?<serial>\d+)\s+(?<refresh>\d+)\s+(?<retry>\d+)\s+(?<expire>\d+)\s+(?<minimum>\d+)\s*\)$') {
                    $records.Add([PSCustomObject]@{
                        Name           = $matches.name
                        FQDN           = if ($matches.name -eq "@") { $ZoneName } else { "$($matches.name).$ZoneName" }
                        Zone           = $zone
                        TTL            = $matches.ttl
                        Class          = if ($matches.class) { $matches.class } else { "IN" }
                        Type           = "SOA"
                        Data           = "$($matches.mname) $($matches.rname)"
                        Priority       = $null
                        Weight         = $null
                        Port           = $null
                        Serial         = $matches.serial
                        Refresh        = $matches.refresh
                        Retry          = $matches.retry
                        Expire         = $matches.expire
                        DefaultTTL     = $matches.minimum
                        SourceFile     = $SourceFile
                    })
                }

                $soaBuffer.Clear()
            }

            continue
        }

        if ($line -match '\bSOA\b' -and $line -notmatch '\)') {
            $inSoa = $true
            $soaBuffer.Add($line)
            continue
        }

        $tokens = $line -split '\s+'
        if ($tokens.Count -lt 2) {
            continue
        }

        $name = $null
        $ttl = $null
        $class = "IN"
        $type = $null
        $rest = @()

        $knownTypes = @("A","AAAA","CNAME","MX","TXT","NS","SRV","PTR","SOA","CAA","TLSA","NAPTR")

        $idx = 0

        if ($knownTypes -contains $tokens[0].ToUpper()) {
            $name = $currentName
        }
        else {
            $name = $tokens[0]
            $currentName = $name
            $idx = 1
        }

        if ($idx -lt $tokens.Count -and $tokens[$idx] -match '^\d+$') {
            $ttl = $tokens[$idx]
            $idx++
        }

        if ($idx -lt $tokens.Count -and $tokens[$idx].ToUpper() -eq "IN") {
            $class = "IN"
            $idx++
        }

        if ($idx -ge $tokens.Count) {
            continue
        }

        $type = $tokens[$idx].ToUpper()
        $idx++

        if ($idx -lt $tokens.Count) {
            $rest = $tokens[$idx..($tokens.Count - 1)]
        }

        $fqdn = if ($name -eq "@") { $ZoneName } else { "$name.$ZoneName" }

        switch ($type) {
            "MX" {
                $priority = if ($rest.Count -ge 1) { $rest[0] } else { $null }
                $data     = if ($rest.Count -ge 2) { $rest[1] } else { $null }

                $records.Add([PSCustomObject]@{
                    Name           = $name
                    FQDN           = $fqdn
                    Zone           = $zone
                    TTL            = $ttl
                    Class          = $class
                    Type           = $type
                    Data           = $data
                    Priority       = $priority
                    Weight         = $null
                    Port           = $null
                    Serial         = $null
                    Refresh        = $null
                    Retry          = $null
                    Expire         = $null
                    DefaultTTL     = $null
                    SourceFile     = $SourceFile
                })
            }

            "SRV" {
                $priority = if ($rest.Count -ge 1) { $rest[0] } else { $null }
                $weight   = if ($rest.Count -ge 2) { $rest[1] } else { $null }
                $port     = if ($rest.Count -ge 3) { $rest[2] } else { $null }
                $data     = if ($rest.Count -ge 4) { $rest[3] } else { $null }

                $records.Add([PSCustomObject]@{
                    Name           = $name
                    FQDN           = $fqdn
                    Zone           = $zone
                    TTL            = $ttl
                    Class          = $class
                    Type           = $type
                    Data           = $data
                    Priority       = $priority
                    Weight         = $weight
                    Port           = $port
                    Serial         = $null
                    Refresh        = $null
                    Retry          = $null
                    Expire         = $null
                    DefaultTTL     = $null
                    SourceFile     = $SourceFile
                })
            }

            "TXT" {
                $data = ($rest -join ' ') -replace '^\(\s*', '' -replace '\s*\)$', ''

                $records.Add([PSCustomObject]@{
                    Name           = $name
                    FQDN           = $fqdn
                    Zone           = $zone
                    TTL            = $ttl
                    Class          = $class
                    Type           = $type
                    Data           = $data
                    Priority       = $null
                    Weight         = $null
                    Port           = $null
                    Serial         = $null
                    Refresh        = $null
                    Retry          = $null
                    Expire         = $null
                    DefaultTTL     = $null
                    SourceFile     = $SourceFile
                })
            }

            default {
                $data = $rest -join ' '

                $records.Add([PSCustomObject]@{
                    Name           = $name
                    FQDN           = $fqdn
                    Zone           = $zone
                    TTL            = $ttl
                    Class          = $class
                    Type           = $type
                    Data           = $data
                    Priority       = $null
                    Weight         = $null
                    Port           = $null
                    Serial         = $null
                    Refresh        = $null
                    Retry          = $null
                    Expire         = $null
                    DefaultTTL     = $null
                    SourceFile     = $SourceFile
                })
            }
        }
    }

    $records | Export-Csv -Path $OutputCsvPath -NoTypeInformation -Encoding UTF8 -Append
    return $records
}



$sourceFolder = "."
$outputCsv    = "DNS_Zones_Export.csv"

if (Test-Path $outputCsv) {
    Remove-Item $outputCsv
}

Get-ChildItem -Path $sourceFolder -File | Where-Object {
    $_.Extension -in '.dns', '.zone' # add File extension as needed
} | ForEach-Object {
    Write-Host "Processing $($_.Name)..."

    $zoneText = Get-Content -Path $_.FullName -Raw
    $zoneName = $_.BaseName -replace '_new$', ''  # To Filter something out of the Filename add: -replace 'excludeme$', ''

    Convert-DnsZoneTextToCsv `
        -ZoneText $zoneText `
        -ZoneName $zoneName `
        -SourceFile $_.Name `
        -OutputCsvPath $outputCsv
}