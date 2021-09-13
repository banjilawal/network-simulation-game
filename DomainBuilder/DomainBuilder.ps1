Import-Module ActiveDirectory

Set-PSDebug -Strict
Set-StrictMode -Version Latest

### ------------------> Global Variables and constants <------------------ 
[string] $global:BASE_LDAP_ROLE = "AD-Domain-Services"
[string] $global:POLICY_ROLE = "GPMC"
[string] $global:NAMING_ROLE = "DNS"

[string] $global:SYSVOL_DATABASE_PATH = "C:\Windows\SYSVOL"
[string] $global:DATA_LOGGING_PATH = "C:\Windows\NTDS"

[string] $global:LDAP_FUNCTIONAL_LEVEL = "WinThreshold"

[string] $global:LDAP_NIC_NAME = "LDAP-NIC"
[string] $global:DNS_NIC_NAME = "DNS-NIC"

[string] $global:DHCP_STATUS = "disabled"
[string] $global:APIPA_ADDRESS = "169.*"

[string] $global:PASSWORD = "Gerund45m"

### ------------------> Enums <------------------
enum TLD {
	priv = 1; net = 2; org = 3; com = 4
}

#############################------- Define the LDAPDomain CLASS -------#############################
class LDAPDomain {
	<#
	.SYNOPSIS

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

  	#------------------ Properties  -------------------#
    [string] $Name 
    [TLD] $TLD


  	#------------------ Constructors  -------------------#
    LDAPDomain () {}

    LDAPDomain ([string] $name) { $this.init($name, [TLD]::priv)}
    LDAPDomain ([string] $name, [TLD] $tld) { $this.init($name, $tld)}

    hidden init ([string] $name, [TLD] $tld) {
        $this.Name = $name
        $this.TLD = $tld

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


    hidden [void] schemaBuilder () {
        [string []] $peopleOU = @("people", "staff", "visitors")
        [string []] $hostsOU = @("servers", "workstations")

        [string []] $finance = @("finance", "accounting", "payroll", "billing")
        [string []] $production = @("production", "development", "test")
        [string []] $management = @("management", "human resources")
        [string []] $systems = @("systems", "admin", "support") 
        [string []] $marketing = @("marketing")
        [string []] $sales = @("sales")


    } # <--- close schemaBuilder


    hidden [void] installDNS () {
        if ( $this.nicTest($global:DNS_NIC_NAME) -eq "fail" ) {
            [string] $message = $env:COMPUTERNAME + " does not have a dedicated DNS NIC"
            throw $message
            exit 999000
        }
        Install-WindowsFeature -Name "DNS" -Confirm:$false -IncludeManagementTools 

    } # <--- close dnsTest


    hidden [string] nicTest ([string] $adapterName) {
        [string] $result = "fail"
        
        [bool] $validAddress = $null -eq (Get-NetIPAddress | Where-Object {$_.InterfaceAlias -eq $adapterName -and $_.IPv4Address -like "169.*"})
        [bool] $validAdapter = $null -ne (Get-NetIPInterface | Where-Object {$_.InterfaceAlias -eq $adapterName -and $_.Dhcp -eq "disabled" })

        if ($validAdapter -eq $true -and $validAddress -eq $true) {
            $result = "pass"
        }

        return $result

    } # <--- close noAdapter


    hidden [bool] noLDAPRole () {
        [bool] $noLDAPRole = $null -eq (Get-WindowsFeature | Where-Object {$_.installed -eq $true -and $_.name -eq $global:BASE_LDAP_ROLE})


        return $noLDAPRole

    } # <--- close noLDAPRole


	#------------------ Static Methods -------------------#
 

} # <--- end class LDAPDomain

$domain = [LDAPDomain]::new()
$domain

$domain = [LDAPDomain]