function Generate-IPAddress () {
    [ipAddress] $ipAddress = $null

    [string] $octets = "192.168."
    [string] $firstOctet = [string] $(Get-Random -Minimum 1 -Maximum 254)
    [string] $secondOctet =[string] $(Get-Random -Minimum 0 -Maximum 254)
    [string] $thirdOctet = [string] $(Get-Random -Minimum 0 -Maximum 254)
    [string] $fourthOctet =[string] $(Get-Random -Minimum 1 -Maximum 254)

    $octets = $firstOctet + "." + $secondOctet + "." + $thirdOctet + "." + $fourthOctet
    $IPAddress = [ipaddress] $octets.Trim()

    return $ipAddress

} # <--- close Generate-IPAddress


function Get-NetworkID ([ipaddress] $ipAddress, [int] $maskLength = 24) {
    [string] $dottedNetMaskBits = [string]::Empty
    [string] $networkBits = [string]::Empty
    [string] $addressBits = [string]::Empty
    [string] $networkID = [string]::Empty
    [string] $bits = [string]::Empty

    [string []] $parts = @()
    [string] $rawNetMaskbits = ('1' * $maskLength).PadRight(32, '0')

    $ipAddress.IPAddressToString.split(".") | ForEach-Object { 
        $bits = $bits + $( [Convert]::ToString($_, 2).PadLeft(8, "0") ) 
    }
    $bits = $bits.Trim()

    $addressBits = $bits.Substring(0, 1)
    $dottedNetMaskBits = $rawNetMaskbits.Substring(0, 1)

    for ([int] $index = 1; $index -lt $bits.Length; $index++) {
        [string] $maskBit = $rawNetMaskbits.Substring($index, 1)
        [string] $bit = $bits.Substring($index, 1)

        if ($index -eq 7 -or $index -eq 15 -or $index -eq 23) { 
            $maskBit = $rawNetMaskbits.Substring( ($index), 1) + "."
            $bit = $bits.Substring($index, 1) + "." 
        }
        $addressBits = $addressBits + $bit
        $dottedNetMaskBits = $dottedNetMaskBits + $maskBit
      #  "current addressBits: " + $addressBits
    }
    #"`nmaskBits: " + $dottedMaskBits + "`naddressBits: "  + $addressBits

    for ([int] $index = 0; $index -lt $addressBits.Length; $index++) {
        [string] $addressBit = $addressBits.Substring($index, 1)
        [string] $maskBit = $dottedNetMaskBits.Substring($index, 1)

        [string] $networkBit = $addressBit

        if ($addressBit -ne $maskBit) { 
            $networkBit = "0"
        }

        $networkBits = $networkBits + $networkBit
    }
    #"`nnetworkBits: " + $networkBits

    $parts = $networkBits.Split(".")
    foreach ($part in $parts) {
        [string] $decimal = [Convert]::ToInt32( $part, 2 )
        $networkID = $networkID + $decimal + "."
    } 
    #"`nnetworkID: " + $networkID
    $networkID = $networkID.TrimEnd(".").Trim()

    return $networkID

} # <--- close Get-NetworkID


function Get-HostID ([ipaddress] $ipAddress, [int] $maskLength = 24) {
    [string] $dottedHostMask = [string]::Empty
    [string] $addressBits = [string]::Empty 
    [string] $hostBits = [string]::Empty
    [string] $hostID = [string]::Empty
    [string] $bits = [string]::Empty

    [int] $totalHostBits = 32 - $maskLength
    #"total hostBits: " + $totalHostBits

    [string] $rawHostMaskBits = ('1' * $totalHostBits).PadLeft(32, '0')
    [string []] $parts = @()

    #"raw HostMask: " + $rawHostMask

    $ipAddress.IPAddressToString.split(".") | ForEach-Object { 
        $bits = $bits + $( [Convert]::ToString($_, 2).PadLeft(8, "0") ) 
    }
    $bits = $bits.Trim()

    $addressBits = $bits.Substring(0, 1)
    $dottedHostMask = $rawHostMaskBits.Substring(0, 1)

    for ([int] $index = 1; $index -lt $bits.Length; $index++) {
        [string] $hostMaskBit = $rawHostMaskBits.Substring($index, 1)
        [string] $bit = $bits.Substring($index, 1)

        if ($index -eq 7 -or $index -eq 15 -or $index -eq 23) { 
            $hostMaskBit = $rawHostMaskBits.Substring($index, 1) + "."
            $bit = $bits.Substring($index, 1) + "." 
        }
        $addressBits = $addressBits + $bit
        $dottedHostMask = $dottedHostMask + $hostMaskBit
      #  "current addressBits: " + $addressBits
    }
    #"`ndottedHostMask: " + $dottedHostMask + "`naddressBits: "  + $addressBits

    for ([int] $index = 0; $index -lt $addressBits.Length; $index++) {
        [string] $addressBit = $addressBits.Substring($index, 1)
        [string] $hostMaskBit = $dottedHostMask.Substring($index, 1)

        [string] $hostBit = $addressBit

        if ($addressBit -ne $hostMaskBit) { 
            $hostBit = "0"
        }
        $hostBits = $hostBits + $hostBit
    }
    $hostBits = $hostBits.TrimEnd(".").Trim()
    #"hostBits: " + $hostBits

    $parts = $hostBits.Split(".")
    foreach ($part in $parts) {
        [string] $decimal = [Convert]::ToInt32( $part, 2 )
        $hostID = $hostID + $decimal + "."     
    }
    $hostID = $hostID.TrimEnd(".").Trim("0.")
    #"`nhostID: " + $hostID

    return $hostID

} # <--- close Get-HostID

[ipaddress] $ip = Generate-IPAddress
[int] $maskLength = Get-Random -Minimum 1 -Maximum 31

"ipaddress: " + $ip.IPAddressToString + " maskLength: " + $maskLength

$networkID = Get-NetworkID -ipAddress $ip -maskLength $maskLength
$hostID = Get-HostID -ipAddress $ip -maskLength $maskLength

"`nnetworkID: " + $networkID + "`nhostID: " + $hostID