$forwardZone = ( Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $false -and $_.ZoneType -eq "Primary" -and $_.ZoneName -notlike "TrustAnchors" } ) | Get-Random
 $record = Get-DnsServerResourceRecord -ZoneName $forwardZone.ZoneName | Where-Object {$_.HostName -notlike "*@*" }  | Get-Random
 $record.HostName

 $reverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true -and $_.ZoneType -eq "Primary" -and $_.ZoneName -notmatch "(0|127|255).in*"}

 [hashtable] $hash = @{}

 foreach ($zone in $reverseZones) {
     [string []] $data = @()

     Get-DnsServerResourceRecord -ZoneName $zone.ZoneName |  Where-Object {$_.HostName -notlike "*@*"} | ForEach-Object {
         $data += $_.RecordData.PtrDomainName
     }
     $hash.Add($zone.ZoneName, $data)
 }

 [int] $hashRow = 0
 [bool] $found = $false
 [string] $reverseZoneName = [string]::Empty

 #$hash

 while ($hashRow -lt $hash.Count -and $found -eq $false) {
     foreach ($key in $hash.keys) {
         [int] $arrayIndex = 0
         while ($arrayIndex -lt $hash[$key].Count -and $found -eq $false) {
            if ( $hash[$key][$arrayIndex] -like ($record.HostName + "*") ) {
                $found = $true
                $reverseZoneName = $key
            }
            $arrayIndex++ 
         }

     }
    $hashRow++ 
 }


 <#

 while ($hashRow -lt $hash.Count -and $found -eq $false) {
    [string] $text = "hashrow: " + $($hashRow)

 foreach ($key in $hash.keys) {
        [int] $arrayIndex = 0
        $text += " $key"
        $text
        $hash[$key]
        
       # while ($arrayIndex -lt $hash.Values.Length -and $found -eq $false) {
        #    $arrayIndex++
            "`tarrayIndex: " + $($arrayIndex) #+ " " + $hash.data
            <#
              if ($hash.Values[$arrayIndex] -like ($record.HostName + ".*") ) {
                $found = $true
                $reverseZoneName = $key
            }
            #>
       # }
        #>
 #   }

 #   $hashRow++

 #}

 #>
[string] $result =  "The randommly selected host named " + $record.HostName
$result += ", with ipaddress " + $record.RecordData.IPv4Address.ToString() 
$result += " was found in FLZ: " + $forwardZone.ZoneName 
$result += " and its' corresponding RLZ: " + $reverseZoneName 

$result