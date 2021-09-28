using namespace Microsoft.Management.Infrastructure.CimInstance.*
#Add-Type 'Microsoft.Management.Infrastructure.CimInstance#root/Microsoft/Windows/DNS/DnsServerPrimaryZone'

#Import-Module ActiveDirectory
Import-Module Microsoft.PowerShell.*

#Import Microsoft.Management.Infrastructure.CimInstance.*

Set-PSDebug -Strict
Set-StrictMode -Version Latest

function Make-Switches () {
    [int] $freeSwitchCount = (Get-VMSwitch | Where-Object {$_.SwitchType -eq "Internal" -and $_.Name -like "Adapter-*"}).count

    if ( $freeSwitchCount -le 1 ) {
        for ([int] $index = 1; $index -lt 10; $index++) {
            [string] $switchName = "Adapter-0" + $index
            New-VMSWitch -Name $switchName -SwitchType Internal -Confirm:$false

            [string] $oldName = (Get-NetAdapter | Where-Object {$_.Name -like "*$switchName*" -and $_.InterfaceDescription -like "hyper-V*"}).Name
            Rename-NetAdapter -Name $oldName -NewName $switchName -Confirm:$false
        }
    }
}
Make-Switches

function Rename-Adapters () {
    $adapters = Get-NetAdapter | Where-Object {$_.Name -like "vethernet*" -and $_.Name -like "*Adapter-*" -and $_.InterfaceDescription -like "hyper-V*"}
    $adapters | ForEach-Object {
        $oldName = $_.Name
        $newName = $_.Name.SubString((($_.Name.IndexOf("(")) +1), 10 )
        Rename-NetAdapter -Name $oldName -NewName $newName
    }
}
Rename-Adapters


function Random-IPAddress () {
    [IPAddress] $ipAddress = $null

    [string] $octets = "192.168."
    [string] $thirdOctet = [string] $(Get-Random -Minimum 44 -Maximum 254)
    [string] $fourthOctet =[string] $(Get-Random -Minimum 1 -Maximum 254)

    $octets = $octets + $thirdOctet + "." + $fourthOctet
    $IPAddress = [IPAddress] $octets.Trim()

    return $IPAddress

} # <--- close Random-IPAddress


function Get-NetworkID ([ipaddress] $ipAddress, [int] $maskLength = 24) {
    [int] $maskLength = (Get-NetIPAddress -InterfaceAlias $this.AdapterName).PrefixLength

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

    return ([ipaddress] $networkID)

} # <--- close Get-NetworkID


### ------------------> Global Variables and constants <------------------ 
[string] $global:DHCP_STATUS = "disabled"
[string] $global:APIPA_ADDRESS = "169.*"

### ------------------> Enums <------------------
enum Action {
    Remove = 0; Install = 1
}

enum DNSZoneType {
    Forward = 0; Reverse = 1
}

enum TestResult {
	Fail = 0; Pass = 2
}

enum ServiceRole {
    None = 0; DNS = 1; DHCP = 2; LDAP = 3; DFS = 4; WDS = 5; IIS = 6; CA = 7
}

enum TLD {
    org; com; net; edu
}


#############################------- Define the Service CLASS -------#############################
class Service {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#
    [ServiceRole] $Role
    [string] $ServerName
    [string] $AdapterName
    [string] $BaseFeature
    [string []] $ExtraFeatures
    #[Microsoft.PowerShell.Commands.NetworkAdapter] $Adapter

  	#------------------ Constructors  -------------------#
    Service () {}
    Service ([ServiceRole] $serverRole) { $this.init($null, $serverRole) }
    Service ([string] $serverName, [ServiceRole] $serverRole) { $this.init($serverName, $serverRole) }

    hidden init ([string] $serverName, [ServiceRole] $serverRole) {
        $this.Role = $serverRole
        $this.ServerName = $this.setServerName($serverName)
        $this.configureAdapter()
        $this.featureHandler()

    } # <--- close init

    #------------------ Getters  -------------------#
    [ipaddress] adapterAddress() {
        [ipaddress []] $addresses = [ipaddress []] (Get-NetIPAddress -InterfaceAlias $this.AdapterName -AddressFamily IPv4).IPv4Address
        [ipaddress] $ip = $addresses[0]

        return $ip

    } # <--- close address

    #------------------ Setters  -------------------#
    [void] setServerName ([string] $name) {

        if ($null -eq $name -or ($name -eq $env:COMPUTERNAME)) {
            $this.ServerName = $env:COMPUTERNAME
        }
        else {
            $this.ServerName = $name
        }

    } # <--- close setServerName


    #------------------ Helper Functions -------------------#
    [void] featureHandler() {
        [string] $roleName = $this.Role.ToString()

        switch ($roleName) {
            "DNS" {  
                $this.BaseFeature = "DNS"
                $this.ExtraFeatures = @()
            }

            "DHCP" {  
                $this.BaseFeature = "DHCP"
                $this.ExtraFeatures = @()
            }

            "LDAP" {
                $this.BaseFeature = "AD-Domain-Services"
                $this.ExtraFeatures = @("GPMC")
            } 

            "WDS" {
                $this.BaseFeature = "WDS"
                $this.ExtraFeatures = @("WDS-Deployment", "WDS-AdminPack")
            }

            "CA" {
                $this.BaseFeature = "AD-Certificate"
                $this.ExtraFeatures = @("ADCS-Cert-Authority", "ADCS-Online-Cert")
            }
            
            "DFS" {
                $this.BaseFeature = "FS-DFS-Namespace"
                $this.Features = @("FS-Data-Deduplication", "FS-DFS-Replication")
            }

            "IIS" {
                $this.BaseFeatures = "Web-Server"
                $this.ExtraFeatures = @("Web-WebServer", "Web-Mgmt-Console", "Web-Mgmt-Compat", "Web-Metabase", "Web-Common-Http", "NET-Framework-45-Features")
                $this.ExtraFeatures = $this.ExtraFeatures + @("NET-Framework-45-Core", "NET-Framework-45-ASPNET")
            }

            Default {}
        }

    } # <--- close featureHandler


    hidden [void] configureAdapter () {
        $this.AdapterName = $this.Role.ToString().ToUpper() + "-NIC"  
        #[Microsoft.PowerShell.Commands.NetworkAdapter] $nic = $null
        [ipaddress] $ipAddress = $null
        [int] $adapterCount = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "hyper-v*"}).count

        if ($adapterCount -le 1) {
            throw $env:COMPUTERNAME + " must have at least two NICs available to provide " + $this.Role.ToString()
            exit 12000
        }

        if ($this.roleAdapterExists() -eq $false) {
            [string] $oldName = (Get-NetAdapter | Where-Object {$_.Name -notlike "*-NIC" -and $_.InterfaceDescription -like "hyper-V*"}).Name | Get-Random
            Rename-NetAdapter -Name $oldName -NewName $this.AdapterName -Confirm:$false
        }

        if ($this.hasIPAddress() -eq $false) {
            $ipAddress = $this.randomIPAddress()
            New-NetIPAddress -InterfaceAlias $this.AdapterName -AddressFamily IPv4 -IPAddress $ipAddress -PrefixLength 24 -Confirm:$false
         }

    } # <--- close configureAdapter


    [bool] hasIPAddress () {
        [bool] $hasAddress = $null -ne (Get-NetIPAddress -InterfaceAlias $this.AdapterName -AddressFamily IPv4)

        return $hasAddress

    } # <--- close getAddress


    hidden [bool] roleAdapterExists () {
        [bool] $roleAdapterExists = $null -ne ( Get-NetAdapter | Where-Object { $_.Name -eq $this.AdapterName } )
 
        return $roleAdapterExists

    } # <--- close activeExists


    [void] setRoleState ([Action] $action) {
        [string] $actionName = $action.ToString()
        [string []] $features = @($this.BaseFeature) +  $this.ExtraFeatures

        switch ($actionName) {
            "Install" {  
                if ($this.roleMissing() -eq $true) {
                    Install-WindowsFeature -Name $features -Confirm:$false -IncludeManagementTools -Restart
                }
            }

            "Remove" {
                if ($this.roleMissing() -eq $false) {
                    Remove-WindowsFeature -Name $features -Confirm:$false -IncludeManagementTools -Restart
                }
            }

            Default {}
        }

    } # <--- close setRoleState


    [bool] roleMissing () {
        [bool] $roleMissing = $null -eq ( Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $this.BaseFeature} )

        return $roleMissing

    } # <--- close roleMissing 


} # <--- end class Service


#############################------- Define the ServiceClient CLASS -------#############################
class ServiceClient {

    #------------------ Properties  -------------------#
    [string] $Hostname
    [ipaddress] $IPAddress

    #------------------ Constructors  -------------------#
    ServiceClient () {}

    ServiceClient([string] $name, [ipaddress] $ipAddress) {
        $this.Hostname = $name
        $this.IPAddress = $ipAddress

    } # <--- close Client

    #------------------ Getters  -------------------#
    [string] hostID ([int] $maskLength = 24) {
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

        $this.IPAddress.IPAddressToString.split(".") | ForEach-Object { 
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
        $hostID = $hostID.TrimEnd(".").TrimStart("0.")
        #"`nhostID: " + $hostID

        return $hostID

    } # <--- close hostID


    #------------------ Setters  -------------------#

    #------------------ Methods  -------------------#
    [string] toString() {
        [string] $text = [string]::Empty
        
        $text = "ServiceClient = [ Hostname: " + $this.Hostname + ", "
        $text = $text + "IPAddress: " + $this.IPAddress.IPAddressToString + ", "
        $text = $text + "HostID: " + $this.hostID(24) + " ]"

        return $text

    } # <--- close toString

    [bool] equals ([psobject] $obj) {
        [bool] $answer = $false

        if ($obj.GetType() -eq $this.GetType()) {
            [ServiceClient] $serviceClient = ([ServiceClient] $obj)

            if (($this.Hostname -eq $serviceClient.Hostname) -and ($this.IPAddress -eq $serviceClient.IPAddress)) {
                $answer = $true
            }
        }
        return $answer

    } # <--- close equals


    [bool] similar ([psobject] $obj) {
        [bool] $answer = $false

        if ($obj.GetType() -eq $this.GetType()) {
            [ServiceClient] $serviceClient = ([ServiceClient] $obj)

            if (($this.Hostname -eq $serviceClient.Hostname) -or ($this.IPAddress -eq $serviceClient.IPAddress)) {
                $answer = $true
            }
        }
        return $answer

    } # <--- close similar


    #------------------ Helper Functions -------------------# 

} # <--- end class ServiceClient

<#
    $serviceClient = [ServiceClient]::new((Get-Content "C:\Dropbox\scripts\datasets\single_words.txt" | Get-Random), (Random-IPAddress))
    $serviceClient
    $serviceClient.toString()
#>


#############################------- Define the DNSRealmCLASS -------#############################
class DNSRealm {

  	#------------------ Properties  -------------------#
    [string] $Domain
    [string] $ForwardZoneName
    [string] $ReverseZoneName
    [string] $Prefix
    [ServiceClient []] $Members
    [ipaddress] $NetworkID
	[int] $MaskLength
    [int] $Capacity


  	#------------------ Constructors  -------------------#
    DNSRealm() {}
    
	DNSRealm([string] $name, [ipaddress] $ipAddress) { $this.init($name, $ipAddress, 24)}

    hidden init ([string] $name, [ipaddress] $ipAddress, [int] $maskLength) {
        $this.Domain = $name
		$this.MaskLength = $maskLength
        $this.NetworkID = $this.netID($ipAddress)

        $this.ForwardZoneName = $this.forwardName()
        $this.ReverseZoneName = $this.reverseName()

        $this.Capacity = ( [Math]::Pow(2,(32 - $this.MaskLength))) - 2
        $this.Prefix = $this.cidr()

    } # <--- close init


    #------------------ Getters  -------------------# 
    [int] size() {
        return $this.Members.Length
    }


    #------------------ Setters  -------------------# 
    [void] addMember ([string] $hostName) {
        [ipAddress] $ipaddress = $this.hostAddress()

        if ($this.Capacity -le $this.Members.Length) {
            throw "There are no free ipaddresses in the network.  No additional hosts can be added"
            exit(111000)
        }

        $this.addMembr($hostName, $ipaddress)

    } # <--- close addMember


    [void] addMember () {

        if ($this.Capacity -le $this.Members.Length) {
            throw "There are no free ipaddresses in the network.  No additional hosts can be added"
            exit(111000)
        }

        [string] $hostName = Get-Content "C:\Dropbox\scripts\datasets\single_words.txt" | Where-Object {$_ -notlike "*-*"}| Get-Random
        [ipaddress] $ipaddress = $this.hostAddress()

        while ($this.hostnameExists($hostName) -eq $true) {
            $hostName = Get-Content "C:\Dropbox\scripts\datasets\single_words.txt" | Where-Object {$_ -notlike "*-*"}| Get-Random
        }

        while ($this.ipInUse($ipaddress) -eq $true) {
            $ipaddress = $this.hostAddress()
        }

        [ServiceClient] $member = [ServiceClient]::new($hostName, $ipaddress)
        $this.Members += $member

    } # <--- close addMember


    [void] addMember ([string] $hostName, [ipaddress] $ipaddress) {

        if ($this.Capacity -le $this.Members.Length) {
            throw "There are no free ipaddresses in the network.  No additional hosts can be added"
            exit(111000)
        }

        if ($this.nameExists($hostName) -eq $true) {
            throw "The name: <" + $hostname + "> is already assigned to a host"
            exit(45046)
        }

        if ($this.ipInUse($ipaddress) -eq $true) {
            throw "The ipaddress : <" + $ipaddress.IPAddressToString + "> is already in use in the network"
            exit(45046)
        }

        [ServiceClient] $member = [ServiceClient]::new($hostName, $ipaddress)
        $this.Members += $member
 
    } # <--- close addMember


    [void] addMember ([ServiceClient []] $clients) {
        [int] $availableSlots = $this.Capacity - $this.Members.Length

        if ($availableSlots -lt $clients.Length) {
            throw "There are no free ipaddresses in the network.  No additional hosts can be added"
            exit(111000)
        }

        if ( $this.validClientList($clients) -eq $false) {
            throw "The list of clients to import contains an ipaddress or hostname already in use.  "
            exit (45046)
        }

        foreach ($client in $clients) { 
            $this.Members += $client 
        }

    } # <--- close addMember

    [void] addMembers () {
        [int] $min = 0
        [int] $max = 0
        [int] $availableSlots = $this.Capacity - $this.Members.Length

        if ($availableSlots -gt 1 -and $availableSlots -le 15) {
            $min = 1
            $max = $availableSlots
        }


        if ($availableSlots -gt 15) { 
            $min = 4
            $max = 15
        }

        [int] $count = Get-Random -Minimum $min -Maximum $max

        for ([int] $index = 0; $index -lt $count; $index++) {
            $this.addMember()
        }

    }  # <--- close addMembers


    [void] removeMember ([string] $target) {
        [int] $startPosition = $this.location($target)

        if ($null -ne $startPosition) {
            for ([int] $index = $startPosition; $index -lt $this.Members.Length; $index++) {
                $this.Members[$index] = $this.Members[$index+1]
            }
        }

    } # <--- close removeMember


	#------------------ Methods -------------------#
    [string] forwardName () {
        [string] $zoneName = [string]::Empty
        [string []] $tlds = (".com", ".priv", ".net", ".org", ".local", ".internal")

        #if  ($this.Domain -match "[0-9]*" -or $this.Domain -match "*.*") { 
        #    throw "A forward zone's name cannot begin with numbers" 
        #    exit 449490
        #}
      
        $zoneName = $this.Domain.ToLower().Trim() + $($tlds | Get-Random)
        return $zoneName
        
    } # <--- close forwardZoneName


    [string] reverseName () {
        [string] $zoneName = [string]::Empty
        [string] $suffix = ".in-addr.arpa"

        $zoneName = $this.reverseNetworkID().Trim() + $suffix
        return $zoneName

    } # <--- close reverseZoneName


    [int] location ([string] $target) {
        [int] $index = 0

        while ( ($this.Members[$index].Hostname -ne $target) -and ($index -lt $this.Members.Length) ) {
            $index++
        }

        if ($index -gt $this.Members.Length -or $index -lt 0) {
            $index = $null
        }

        return $index

    } # <--- close location


    [ServiceClient] search ([string] $target) {
        [ServiceClient] $result = [ServiceClient]::new()
        [int] $index = $this.location($target)

        if ($null -ne $index) {
            $result = $this.Members[$index]
        }
        return $result

    } # <--- close search


    [string] toString () {
        [string] $text = [string]::Empty
        
        $text = "DNSRealm = [ Domain: " + $this.Domain + ", "
        $text = $text + "NetworkID: " + $this.NetworkID.IPAddressToString + "/" + $($this.MaskLength) + ", "
        $text = $text + "forwardZone: " + $this.ForwardZoneName + ", "
        $text = $text + "reverseZone: " + $this.ReverseZoneName + ", "
        $text = $text + "Member Count: " + $($this.Members.Length) + " ]"

        return $text

    } # <--- close toString


	#------------------ Helper Functions -------------------#
    [ipAddress] netID ([ipaddress] $ipAddress) {

        [string] $dottedNetMaskBits = [string]::Empty
        [string] $networkBits = [string]::Empty
        [string] $addressBits = [string]::Empty
        [string] $id = [string]::Empty
        [string] $bits = [string]::Empty
    
        [string []] $parts = @()
        [string] $rawNetMaskbits = ('1' * $this.MaskLength).PadRight(32, '0')
    
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
            $id = $id + $decimal + "."
        } 
        #"`nnetworkID: " + $networkID
        $id = $id.TrimEnd(".").Trim()
    
        return ([ipaddress] $id)
    
    } # <--- close networkID
    

    [string] fileName ([DNSZoneType] $zoneType) {
        [string] $fileName = [string]::Empty

        switch ($zoneType.ToString()) {
            "Forward" { $fileName = $this.ForwardZoneName + ".dns" }
            "Reverse" { $fileName = $this.ReverseZoneName + ".dns" }
        }
        return $fileName

    } # <--- close fileName
	
	
    [string] reverseNetworkID () {
        [string] $reverseID = [string]::Empty
        [string] $id = $this.NetworkID.IPAddressToString
        
        [string []] $octets = $id.split(".")
        [array]::Reverse($octets)

        for ([int] $index = 1; $index -lt $octets.Length; $index++) {
            $reverseID = $reverseID + $octets[$index] + "."
        }

        $reverseID = $reverseID.Trim(".")
        return $reverseID

    } # <--- close reverseNetworkID


    [ipaddress] hostAddress () {
        [string] $dottedDecimal = [string]::Empty
        [string] $dottedBits = [string]::Empty
        [int] $maxCapacity = ( [Math]::Pow(2,(32 - $this.MaskLength)) - 2 )	
    
        [ipaddress] $hostAddress = $null

        [int] $counter = Get-Random -Minimum 20 -Maximum 245
    
        if ( $counter -lt 1 -or $counter -gt $maxCapacity ) {
            throw $($Counter) + " is outside the range of possible hosts in the " + $this.Name + " network"
        }
    
        $octets = $this.NetworkID.GetAddressBytes()
    
        if ([Bitconverter]::IsLittleEndian) {
            [Array]::Reverse($octets) 
        } 
        $hostNumber = [BitConverter]::ToUInt32($octets, 0)
        $hostNumber += $counter
    
        $hexValue = [Convert]::ToString($hostNumber, 16)
    
        for ( [int] $index = 0; $index -lt 7; $index +=2) { 
            $dottedBits = $dottedBits + $hexValue.ToString().Substring($index, 2) + "." 
        }
        $dottedBits = $dottedBits.TrimEnd('.').Trim()
    
        $dottedBits.Split('.') | ForEach-Object { 
            $dottedDecimal = $dottedDecimal + $([Convert]::ToInt32($_, 16)).ToString() + "." 
        }
        $hostAddress = [ipaddress] $dottedDecimal.trim(".").Trim()
    
        return $hostAddress
    
    } # <--- close hostAddress


    [string] memberList () {
        [string] $list = $this.Domain + " Members:"

        foreach ($member in $this.Members) {
            $list = $list + "`n`t" + $member.toString()
        }
        return $list

    } # <--- close memberList


    hidden [string] cidr () {
        [string] $text = $this.NetworkID.IPAddressToString + "/" + $($this.MaskLength)
        return $text

    } # <--- close setPrefix


    hidden [bool] nameExists ([string] $name) {
        [bool] $nameInUse = $false

        if ($this.Members.HostName -contains $name) {
            $nameInUse = $true
        }
        return $nameInUse

    } # <--- close hostnameExists


    hidden [bool] ipInUse ([ipaddress] $targetIP) {
        [bool] $addressInUse = $false

        if ($this.Members.IPAddress.IPAddressToString -contains $targetIP) {
            $addressInUse = $true
        }
        return $addressInUse

    } # <--- close ipaddressExists


   hidden [bool] inNetwork ([ipaddress] $targetIP) {
        [bool] $inNetwork = $false
        [string] $targetNetworkID = $this.NetworkID($targetIP).IPAddressToString

        if ($this.NetworkID.IPAddressToString -eq $targetNetworkID) {
            $inNetwork = $true
        }
        return $inNetwork

    } # <--- close outsideNetwork

    hidden [bool] validClientList ([ServiceClient []] $clientList) {
        [bool] $isValid = $true
        [int] $counter = 0

        while ($counter -lt $clientList.Length -and $isValid -eq $true) {
            [string] $name = $clientList[$counter].Hostname
            [ipaddress] $ip = $clientList[$counter].ipAddress

            if ( ($this.nameExists($name) -eq $true) -or ($this.ipInUse($ip) -eq $true) ) {
                $isValid  = $false
            }
            $counter++   
        }
        return $isValid

    } # <--- close validClientList
  
 
	#------------------ Static Methods -------------------#
 

} # <--- end class DNSRealm

<#
    [string] $domainName = Get-Content "C:\Dropbox\scripts\datasets\single_word_cities.txt" | Get-Random
    [ipaddress] $ipAddress = Random-IPAddress

    $dnsRealm = [DNSRealm]::new($domainName, $ipAddress)
    $dnsRealm
    $dnsRealm.addClients()
    $dnsRealm.clientReport()
    $dnsRealm.ToString()
    $dnsRealm
#>


#############################------- Define the NameServer CLASS -------#############################
class NameServer : Service {

  	#------------------ Properties  -------------------#
    #[string] $ServerName
    [DNSRealm []] $NameSpaces
    [ipaddress] $ListenAddress
    [ipaddress []] $Forwarders
    [ipaddress []] $Peers
    [ipaddress []] $Children


  	#------------------ Constructors  -------------------#
    NameServer () : base ([ServiceRole]::DNS) {}

    NameServer ([DNSRealm []] $dnsRealms) : base([ServiceRole]::DNS) { $this.init($dnsRealms) }
    NameServer ([string] $serverName, [DNSRealm []] $dnsRealms) : base($serverName, [ServiceRole]::DNS) { $this.init($dnsRealms) }

    hidden init ([DNSRealm] $dnsRealms) {

        $this.install()
        $this.ListenAddress = $this.addressHandler()
        $this.setNameSpaces($dnsRealms)
        $this.configure()

    } # <--- close init


    #------------------ Getters  -------------------# 
    [DNSRealm []] allRealms () {
        [DNSRealm []] $realms = @()


        return $realms

    } # <--- close dnsRealms


    #------------------ Setters  -------------------# 
    [void] setNameSpaces ([DNSRealm []] $dnsRealms) {
        $this.NameSpaces = $this.NameSpaces + $dnsRealms

    } # <--- close setNameSpaces


    [ipaddress] addressHandler () {
        [string] $adapterName = ([Service] $this).AdapterName
        [ipaddress] $ip = [ipaddress]::new()
        
        $ip = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4
        dnscmd /ResetListenaddresses $ip
        return $ip

    } # <--- close addressHandler


	#------------------ Methods -------------------#
    [void] install () {

        if ( ([Service] $this).roleMissing() -eq $true ) {
            ([Service] $this).setRoleState([Action]::Install)
        }

    } # <--- close install


    [void] configure () {

        $this.createZones() 

    } # <--- close configure

    hidden [void] createZone ([DNSRealm] $dnsRealm) {
        $this.NameSpaces += $dnsRealm

        Add-DnsServerPrimaryZone -Name $dnsRealm.ForwardZoneName -ZoneFile $( $dnsRealm.fileName([DNSZoneType]::Forward) )
        Add-DnsServerPrimaryZone -NetworkID $dnsRealm.Prefix -ZoneFile $( $dnsRealm.fileName([DNSZoneType]::Reverse) )

        foreach ($member in $dnsRealm.Members) {
            [string] $fqdn = $member.HostName + "." + $dnsRealm.ForwardZoneName
            [string] $ptr = $member.hostID($dnsRealm.MaskLength)

            Add-DnsServerResourceRecord -ZoneName $dnsRealm.ForwardZoneName -Name $member.HostName -A -IPv4Address $member.IPAddress -Confirm:$false
            Add-DnsServerResourceRecord -ZoneName $dnsRealm.ReverseZoneName -Name $ptr -Ptr -PtrDomainName $fqdn -Confirm:$false
        }

    } # <--- close createZone


    hidden [void] createZones () {

        foreach ($nameSpace in $this.NameSpaces) { 
            $this.createZone($nameSpace) 
        }

    } # <--- close createZonee


	#------------------ Helper Functions -------------------# 
    [hashtable] mapZones ([DNSZoneType] $zoneType) {
        [hashtable] $zoneMaps = @{}

        switch ($zoneType.ToString()) {
            "Forward" { 
                $zones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $false -and $_.ZoneType -eq "Primary" -and $_.ZoneName -notlike "TrustAnchors" } 

                foreach ($zone in $zones) {
                    [hashtable] $recordMaps = @{}

                    Get-DnsServerResourceRecord -ZoneName $zone.ZoneName |  Where-Object {$_.HostName -notlike "*@*"} | ForEach-Object {
                        $recordMaps.Add($_.HostName, $_.RecordData.$record.RecordData.IPv4Address)
                    }
                    $zoneMaps.Add($zone.ZoneName, $recordMaps)
                }
            }

            "Reverse" { 
                $zones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true -and $_.ZoneType -eq "Primary" -and $_.ZoneName -notmatch "(0|127|255).in*"} 

                foreach ($zone in $zones) {
                    [hashtable] $recordMaps = @{}

                    Get-DnsServerResourceRecord -ZoneName $zone.ZoneName |  Where-Object {$_.HostName -notlike "*@*"} | ForEach-Object {
                        $recordMaps.Add($_.HostName, $_.RecordData.PtrDomainName)
                    }
                    $zoneMaps.Add($zone.ZoneName, $recordMaps)
                }
            }
        }
       return $zoneMaps


    } # <--- close mapZones


    [DNSRealm] namespaceToRealm ([string] $domainRoot) {
        [string] $flzName = [string]::Empty
        [string] $rlzName = [string]::Empty
        [string] $recordName = [string]::Empty
        [string] $fqdn = [string]::Empty

        [string] $expr = "*" + $domainRoot + "*"

        [DNSRealm] $dnsRealm = [DNSRealm]::new()


        [hashtable] $flzMaps = $this.mapZones([DNSZoneType]::Forward)
        [int] $index = 0
        [bool] $found = $false

        while ( ($index -lt $flzMaps.Count) -and ($found -eq $false) ) {
            if ($flzMaps[$index].Keys -like $expr) {
                $flzName = $flzMaps[$index].Key

                $records = $flzMaps[$index].Values
                $recordName = $records[0].Keys

                $fqdn = $recordName + "." + $flzName
                $found = $true
            } 
            $index++
        }

        $rlzMaps = $this.mapZones([DNSZoneType]::Reverse)
        $outerIndex = 0
        $found = $false

        while ( ($outerIndex -lt $rlzMaps.Count) -and ($found -eq $false) ) {
            $records = $rlzMaps[$outerIndex].Values
            [int] $innerIndex = 0

            while ( ($innerIndex ) -and ($found -eq $false) ) {
                $ptrDomain = $records[$innerIndex].Values.TrimEnd(".")

                if ($ptrDomain -eq $fqdn) {
                    $rlzName = $rlzMaps[$outerIndex]
                    $found = $true
                }
                $innerIndex++
            }
            $outerIndex++
        }

        if ( ($null -ne $rlzName) -and ($null -ne $flzName) ) {
            [ServiceClient []] $members = @()

            foreach ($record in (Get-DnsServerResourceRecord -ZoneName $flzName) ) {
                [string] $hostName = $record.HostName
                [ipaddress] $ipAddress = $record.RecordData.IPv4Address
                [ServiceClient] $member = [ServiceClient]::new($hostName, $ipAddress)
                $members += $member
            }
            $dnsRealm.Domain = $domainRoot
            $dnsRealm.ForwardZoneName = $flzName
            $dnsRealm.ReverseZoneName = $rlzName
            $dnsRealm.MaskLength = 24
            $dnsRealm.addMember($members)
        }
        return $dnsRealm

    } # <--- close namespaceToRealm


    [string []] zoneNames ([string] $realmName) {
        [string] $reverseZoneName = [string]::Empty
        [string] $forwardZoneName = [string]::Empty

        [string []] $zoneNames = @()
        [hashtable] $hash = @{}

        [bool] $found = $false
        [int] $hashRowNumber = 0

        $forward = Get-DnsServerZone | Where-Object {$_.ZoneName -like ($realmName + "*")}
        $forwardZoneName = $forward.ZoneName

        $reverseZones = Get-DnsServerZone | Where-Object {$_.IsReverseLookupZone -eq $true -and $_.ZoneType -eq "Primary" -and $_.ZoneName -notmatch "(0|127|255).in*"}
        $record = Get-DnsServerResourceRecord -ZoneName $forwardZoneName | Where-Object {$_.HostName -notlike "*@*" }  | Get-Random

        foreach ($zone in $reverseZones) {
            [string []] $data = @()
       
            Get-DnsServerResourceRecord -ZoneName $zone.ZoneName |  Where-Object {$_.HostName -notlike "*@*"} | ForEach-Object {
                $data += $_.RecordData.PtrDomainName
            }
            $hash.Add($zone.ZoneName, $data)
        }
       
        while ($hashRowNumber -lt $hash.Count -and $found -eq $false) {
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
           $hashRowNumber++ 
        }

        $zoneNames = @($forwardZoneName, $reverseZoneName)
        return $zoneNames

    } # <--- close zoneNames


	#------------------ Static Methods -------------------#


} # <--- end class NameServer

$nameServer = [NameServer]::new()

for ([int] $index = 0; $index -lt 2; $index++) {
    [string] $domainName = Get-Content "C:\Dropbox\scripts\datasets\single_word_cities.txt" | Get-Random
    [ipaddress] $ipAddress = Random-IPAddress

    $dnsRealm = [DNSRealm]::new($domainName, $ipAddress)
    $dnsRealm.addMembers()
    $dnsRealm.memberList()
    $dnsRealm.ToString()

    $nameServer.createZone($dnsRealm)
}

$nameServer


#############################------- Define the BinaryTree CLASS -------#############################
class BinaryTree {

    #------------------ Properties  -------------------#
    [string []] $Tree

    #------------------ Constructors  -------------------#
    BinaryTree () {}

    BinaryTree ([string []] $list) {
        $this.Tree = $list

    } # <--- close OUTree


    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 

    #------------------ Methods -------------------#
 
    #------------------ Helper Functions -------------------# 
    

    #------------------ Static Methods -------------------#


} # <--- end class OUTree


#############################------- Define the OUTree CLASS -------#############################
class OUTree {

    #------------------ Properties  -------------------#
	[string] $Name
    [string []] $Tree

    #------------------ Constructors  -------------------#
    OUTree () {}

    OUTree ([string] $name, [string []] $ouList) {
        $this.Name = $name
        $this.Tree = $ouList

    } # <--- close OUTree


    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 

    #------------------ Methods -------------------#
 
    #------------------ Helper Functions -------------------# 


    #------------------ Static Methods -------------------#


} # <--- end class OUTree


#############################------- Define the LDAPServer CLASS -------#############################
class LDAPServer : Service {

    #------------------ Properties  -------------------#
    [string] $DomainRoot
    [TLD] $TLD

    #------------------ Constructors  -------------------#
    LDAPServer () : Base ([ServiceRole]::LDAP) {}

    LDAPServer ([string] $rootName) : Base ([ServiceRole]::LDAP) { $this.init($rootName, [TLD]::org) }
    LDAPServer ([string] $rootName, [TLD] $tld) : Base ([ServiceRole]::LDAP) { $this.init($rootName, $tld) }
    LDAPServer ([string] $serverName, [string] $rootName) : Base ($serverName, [ServiceRole]::LDAP) { $this.init($rootName, [TLD]::org) }
    LDAPServer ([string] $serverName, [string] $rootName, [TLD] $tld) : Base ($serverName, [ServiceRole]::LDAP) { $this.init($rootName, $tld) }

    hidden init ([string] $rootName, [TLD] $tld) {
        $this.DomainRoot = $rootName
        $this.TLD = $tld
        $this.install()

    } # <--- close init
    #------------------ Getters  -------------------# 
    #------------------ Setters  -------------------# 
    #------------------ Methods -------------------#
    [void] install () {

        [hashtable] $params = @{
            DomainName = $this.DomainRoot + $this.TLD.ToString()
            DomainNetbiosName = $this.DomainRoot
            SafeModeAdministratorPassword = "password"
            SYSVOLPath = $global:SYSVOL_DATABASE_PATH
            DatabasePath = $global:DATA_LOGGING_PATH
            LogPath = $global:DATA_LOGGING_PATH
            ForestMode = $global:LDAP_FUNCTIONAL_LEVEL
            DomainMode = $global:LDAP_FUNCTIONAL_LEVEL
            NoRebootOnCompletion = $false
            InstallDns = $false
            Confirm = $false
            Force = $true
        }
        Install-ADDSForest @params

    } # <--- close install


    [void] defaultConfig() {
        [string []] $rootOUs = @("hosts", "departments", "servers", "workstations",  "appServers")
        [string []] $departments = @("human resources", "marketing", "finance", "research & development", "sales")
        $departmens = $departments + ("admin", "management", "it", "sysadmin", "support", "print", "web", "accounting", "invoices", "payable", "payroll")
        [string []] $ouTree = @("")
        
        foreach ($ou in $ouTree) {
            $this.addOU($parent, $ou)
        }

    } # <--- close defaultConfig

    [void] addOU ([string] $parent, [string] $child) {
        [string] $path = [string]::Empty
        $path += ",OU=" + $parent.trim().ToLower()

        New-ADOrganizationalUnit -Name $child -Path $path

    } # <--- close addOU


    #------------------ Helper Functions -------------------# 
    #------------------ Static Methods -------------------#


} # <--- end class LDAPServer


#############################------- Define the DHCPServer CLASS -------#############################
class DHCPServer : Service {

    #------------------ Properties  -------------------#
    [ipaddress] $ListenAddress
    [ipaddress []] $Forwarders
    [ipaddress []] $Peers
    [ipaddress []] $Children

    #------------------ Constructors  -------------------#

    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 

    #------------------ Methods -------------------#
 
    #------------------ Helper Functions -------------------# 

    #------------------ Static Methods -------------------#


} # <--- end class DHCPServer
