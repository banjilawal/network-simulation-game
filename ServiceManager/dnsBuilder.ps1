Import-Module ActiveDirectory

Set-PSDebug -Strict
Set-StrictMode -Version Latest

### ------------------> Global Variables and constants <------------------ 
[string] $global:BASE_DNS_ROLE = "DNS"
[string] $global:DNS_NIC_NAME = "DNS-NIC"

[string] $global:DHCP_STATUS = "disabled"
[string] $global:APIPA_ADDRESS = "169.*"

### ------------------> Enums <------------------
enum TestResult {
	Fail = 0; Pass = 2
}

#############################------- Define the NameServer CLASS -------#############################
class NameServer {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#
    [string] $ServerName
    [string] $ForwardDomain
    [ipaddress] $ReverseDomain
    [ipaddress] $ServerAddress
    [ipaddress []] $Forwarders
    [ipaddress []] $Peers
    [ipaddress []] $Children


  	#------------------ Constructors  -------------------#
    NameServer () {}

    NameServer ([string] $serverName) { $this.init($serverName, $(), $())}
    NameServer ([string] $serverName, [string] $forwardDomain) { $this.init($serverName, $forwardDomain, $())}

    hidden init ([string] $serverName, [string] $forwardDomain,  [ipaddress] $reverseDomain) {

    } # <--- close init


    #------------------ Setters  -------------------#


	#------------------ Methods -------------------#


	#------------------ Helper Functions -------------------#
    hidden [void] adInstaller () {

        if ($this.nicTest($global:LDAP_NIC_NAME) -eq "fail") {
            [string] $message = $env:COMPUTERNAME + " does not have valid network interface"
            throw $message
            exit 99000
        }

        $this.installDNS()

        if ( $this.noLDAPRole() -eq $true ) {
            Install-WindowsFeature $global:BASE_LDAP_ROLE -Confirm:$false -IncludeManagementTools -IncludeAllSubFeature
        }

        [hashtable] $params = @{
            DomainName = $this.Name + $this.TLD.ToString()
            DomainNetbiosName = $this.Name
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

    } # <--- close adInstaller


    hidden [void] installDNS () {
        if ( $this.nicTest($global:DNS_NIC_NAME) -eq "fail" ) {
            [string] $message = $env:COMPUTERNAME + " does not have a dedicated DNS NIC"
            throw $message
            exit 999000
        }
        Install-WindowsFeature -Name "DNS" -Confirm:$false -IncludeManagementTools 

    } # <--- close dnsTest


    hidden [bool] foundServiceAdapter () {
        [bool] $found = $null -eq (Get-NetAdapter | Where-Object {$_.InterfaceAlias -eq $global:DNS_NIC_NAME})

        return $found

    } # <--- close foundServiceAdapter

    hidden [bool] activeServiceAdapter () {
        [bool] $active = $null -eq (Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq $adapterName -and $_.IPv4Address -like "169.*"})

        return $active

    } # <--- close activeServiceAdapter


    hidden [string] nicTest ([string] $adapterName) {
        [string] $result = "fail"
        [bool] $adapterFound = $this.foundServiceAdapter()
        [bool] $adapterConfigured = $this.activeServiceAdapter()

        
        if ($adapterFound -eq $false) {
            throw $env:COMPUTERNAME + " does not have a dedicated DNS NIC named " + $global:DNS_NIC_NAME
            exit 45000
        }

        if ($adapterConfigured -eq $false) {
            throw $((Get-NetAdapter -Name $global:DNS_NIC_NAME).InterfaceAlias) + " on " + $env:COMPUTERNAME + " has not been configured with an IP address"
            exit 45001
        }

        if ($adapterFound -eq $true -and $adapterConfigured -eq $true) {
            $result = "pass"
        }


        return $result

    } # <--- close noAdapter


    hidden [bool] missingDNSRole () {
        [bool] $hasDNSRole = $null -eq (Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $global:DNS_ROLE})


        return $hasDNSRole

    } # <--- close missingDNSRole


	#------------------ Static Methods -------------------#
 

} # <--- end class NameServer

$domain = [LDAPDomain]::new()
$domain

$domain = [LDAPDomain]