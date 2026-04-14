# DNSZones_to_CSV
Converts DNS Zone File(s) to CSV

- Reads all `.dns` and `.zone` files from a folder
- Parses DNS zone file content as plain text
- Exports all parsed records into a single CSV file
- Appends all parsed records into one CSV output
- Adds the zone name as a dedicated column for easy filtering


## Setup
Run the script in the path where the Zone Files are stored. It does export a DNS_Zones_Export.csv in the same path.

To change the directory where the zonefiles are stored or the output path of the CSV change the following variables:
```PowerShell
$sourceFolder = "."
$outputCsv    = "DNS_Zones_Export.csv"
```


## File Extensions
Only Files with extension .dns or .zone are parsed. In order to adjust this change the Filter in approx. row 240 
```Powershell
Get-ChildItem -Path $sourceFolder -File | Where-Object {
    $_.Extension -in '.dns', '.zone' # <--- add / remove File extension as needed
} | ForEach-Object {
```

## Zone Name
The Script parses the ZoneName from the Filename. 
Be sure to name the File according to the zone.
For example:
- example.com.zone -> For Domain example.com

If you do have text in the filename which should be excluded alter the following line (approx. row 245):
```Powershell
$zoneName = $_.BaseName -replace '_new$', ''
```

## Known Issues
For Nameserver Entries it does add the Zonename to the FQDN which is wrong. But it didn't bother me so I didn't see the need to change it. :D
