Import-Module ActiveDirectory
Import-Module Microsoft.PowerShell.*

#Import Microsoft.Management.Infrastructure.CimInstance.*

Set-PSDebug -Strict
Set-StrictMode -Version Latest

### ------------------> Global Variables and constants <------------------ 
[string] $global:DHCP_STATUS = "disabled"
[string] $global:APIPA_ADDRESS = "169.*"

### ------------------> Enums <------------------
enum TestResult {
	Fail = 0; Pass = 2
}

enum ServiceRole {
    None = 0; DNS = 1; DHCP = 2; ActiveDirectory = 3; WDS = 4; IIS = 5; CA = 6
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
    [Microsoft.PowerShell.Commands.NetworkAdapter] $Adapter

  	#------------------ Constructors  -------------------#
    Service () {}
    Service ([ServiceRole] $serverRole) { $this.init($serverRole, $null) }
    Service ([ServiceRole] $serverRole, [ipaddress] $ipAddress) { $this.init($serverRole, $ipaddress) }

    hidden init ([ServiceRole] $serverRole, [ipaddress] $ipaddress) {
        $this.Role = $serverRole
        $this.Adapter = $this.adapterHandler($ipaddress)

    } # <--- close init


    #------------------ Setters  -------------------#


	#------------------ Methods -------------------#


	#------------------ Helper Functions -------------------#
    hidden [Microsoft.PowerShell.Commands.NetworkAdapter] adapterHandler ([ipAddress] $ipaddress) {
        [Microsoft.PowerShell.Commands.NetworkAdapter] $nic = $null

        [string] $adapterName = $this.Role.ToString().ToUpper() + "-NIC"  
        [int] $adapterCount = (Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "hyper-v*"}).count

        if ($adapterCount -le 1) {
            throw $env:COMPUTERNAME + " must have at least two NICs available  to provide " + $this.Role.ToString()
            exit 12000
        }

        if ($this.adapterExists() -eq $false) {
            $nic = Get-NetAdapter | Where-Object {$_.InterfaceAlias -notlike "*-NIC" -and $_.InterfaceDescription -like "hyper-V*"} | Get-Random
        }

        [string] $oldName = $nic.InterfaceAlias
        Rename-NetAdapter -Name $oldName -NewName $adapterName -Confirm:$false

        if ($nic.IPAddresses.ToString() -like "169.*") {
            if ($null -eq $ipaddress) { $ipaddress = $this.addressGenerator() }

            Set-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -IPAddress $ipaddress -Confirm:$false
        }

        return $nic

    } # <--- close adapterHandler


    hidden [bool] adapterExists ([string] $name) {
        [bool] $exists = $null -eq (Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq $name})
 
        return $exists

    } # <--- close activeExists

    hidden [ipaddress] addressGenerator() {
        [string] $netNumber = "192.168.44."
        [int] $hostNumber = 11..245 | Get-Random

        [string] $address = ($netNumber + $($hostNumber)).Trim()

        return ([ipaddress] $address)

    } # <--- close addressGenerator

	#------------------ Static Methods -------------------#
 

} # <--- end class Service



#############################------- Define the ServiceInstaller CLASS -------#############################
class ServiceInstaller {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#
    [string] $ServerName
    [Service] $Service

  	#------------------ Constructors  -------------------#
    ServiceInstaller ([string] $server, [Service] $service) {
        $this.ServerName = $server
        $this.Service = $service

    } # <--- close ServiceInstaller


	#------------------ Helper Functions -------------------#
    [void] installer () {
        [string] $feature = $this.Service.Role.ToString()
        [bool] $roleMissing = $null -eq ( Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $feature} )

        if ($roleMissing -eq $true) {
            Install-WindowsFeature -Name $feature -Confirm:$false
        }

    } # <--- close installer


} # <--- end class ServiceInstaller


#############################------- Define the DNSInstaller CLASS -------#############################
class DNSInstaller : ServiceInstaller {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#
    #------------------ Constructors  -------------------#
    DNSInstaller () : base() {}

    DNSInstaller ([string] $serverName) : base ( $serverName, [service]::new([ServiceRole]::DNS) ) {
        $this.installer()

    } # <--- close DNSInstaller

    #------------------ Setters  -------------------#
	#------------------ Methods -------------------#

	#------------------ Helper Functions -------------------#
    [void] installer () {
        [string []] $features = @($this.Service.Role.ToString())
        [bool] $dnsRoleMissing = $null -eq ( Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $this.Service.Role.ToString()} )

        if ($dnsRoleMissing -eq $true) {
            Install-WindowsFeature -Name $features -Confirm:$false
        }

    } # <--- close installer

} # <--- end class DNSInstaller


#############################------- Define the DHCPInstaller CLASS -------#############################
class DHCPInstaller : ServiceInstaller {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#

  	#------------------ Constructors  -------------------#
    DHCPInstaller () : base() {}  

    DHCPInstaller ([string] $serverName) : base ( $serverName, [service]::new([ServiceRole]::DHCP) ) {
        $this.installer()

    } # <--- close DHCPInstaller

    #------------------ Setters  -------------------#


	#------------------ Methods -------------------#


	#------------------ Helper Functions -------------------#
    [void] installer () {
        [string []] $features = @($this.Service.Role.ToString())
        [bool] $dnsRoleMissing = $null -eq ( Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $this.Service.Role.ToString()} )

        if ($dnsRoleMissing -eq $true) {
            Install-WindowsFeature -Name $features -Confirm:$false
        }

    } # <--- close installer



	#------------------ Static Methods -------------------#
 

} # <--- end class ServiceInstaller




$domain = [LDAPDomain]::new()
$domain

$domain = [LDAPDomain]