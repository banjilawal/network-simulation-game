using namespace Microsoft.HyperV.*
using namespace Microsoft.Hyper-V.*
using assembly 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.HyperV.PowerShell.Objects\v4.0_10.0.0.0__31bf3856ad364e35\Microsoft.HyperV.PowerShell.Objects.dll'
using assembly 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.HyperV.PowerShell.Cmdlets\v4.0_10.0.0.0__31bf3856ad364e35\Microsoft.HyperV.PowerShell.Cmdlets.dll'
using assembly 'C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.Virtualization.Client.Common.Types\v4.0_10.0.0.0__31bf3856ad364e35\Microsoft.Virtualization.Client.Common.Types.dll'

Set-PSDebug -Strict
Set-StrictMode -Version Latest	

### ------------------> Global Variables and constants <------------------ 
[string] $global:BASE_NETWORK_PATH = "C:\Users\Public\Documents\Hyper-V\Networks\"

$global:SERVER_2016_ISO_PATH = "C:\Users\griot\Downloads\Windows_Server_2016_2021-07-19.ISO"
$global:SERVER_2019_ISO_PATH = "C:\Users\griot\Downloads\Windows_Server_2019_2021-07-20.ISO"
$global:SERVER_2022_ISO_PATH = "C:\Users\griot\Downloads\Windows_Server_2022_2021-08-06.ISO"

$global:WINDOWS_10_ISO_PATH = "C:\Users\griot\Downloads\Windows_10_2020_04_14.ISO"

[String []] $global:destinations= ("servers", "workstations")
[string []] $global:leafCategories = ("servers", "workstations", "all")
[string []] $global:nodeSuffixes = ("terminator", "root", "servers", "workstations")

[int64] $global:BYTES_PER_MEGABYTE = 1048576
[int64] $global:BYTES_PER_GIGABYTE = 1073741824


### ------------------> Enums <------------------
enum TraversalDestination {
	Servers = 1; Workstations = 2
}

enum LeafCategory {
	Servers = 1; Workstations = 2; All = 3
}

enum searchType {
    Fuzzy = 1; Exact = 2
}

enum NodeType {
    Servers = 1; Workstations = 2; Root = 3; Terminator = 4
}

enum UserInterface {
	Core = 1; GUI = 2; Nano = 3
}

enum ServerOSVersion {
	Server2016 = 1; Server2019 = 2; Server2022 = 3; Azure = 4
}

[Flags()] enum ServerRoles {
	None = 0; FileServer = 1; DNS = 2; DHCP = 3; LDAP = 4; DFS = 5;
	WDS = 6; CA = 7; HTTP = 8; SQL = 9; SharePoint = 10; Router = 11
}

enum WorkstationOSVersion {
	Windows10 = 1; Linux = 2; MacOSX = 3; Windows7 = 4
}


#############################------- Define the VTREE CLASS -------#############################
class VTree {
	<#
	.SYNOPSIS
		This class adds some enhancements to the VMGroup class to make it easier to manage in a virtual network.

	.DESCRIPTION
		VTree class automatically creates a tree of VMGroups to make it easier to configure hosts and inside a VMGroup.
		Also can remove a VMGroups cleanly.

	.FUNCTIONALITY 
		This does not work as well as it should because I have not figured out how to use inheritance to invoke methods and parameters from 
		VMGroup.
	#>

  	#------------------ Properties  -------------------#
    [string] $Name

	[Microsoft.HyperV.PowerShell.VMGroup] $Terminator
    [Microsoft.HyperV.PowerShell.VMGroup] $Root
    [Microsoft.HyperV.PowerShell.VMGroup] $Servers
    [Microsoft.HyperV.PowerShell.VMGroup] $Workstations


  	#------------------ Constructors  -------------------#
	VTree () { }

    VTree ([string] $baseName) {
        $baseName = $baseName.ToLower().Trim()
        [string] $terminatorName = $baseName + "_terminator"

       if ( $this.exsists($terminatorName) -eq $false ) {
           throw "There is already a " + $this.getType() + " named " + $terminatorName
        }

        $this.Name = $baseName

		$this.Terminator = New-VMGroup -Name $terminatorName -GroupType "ManagementCollectionType"

        $this.Root = New-VMGroup -Name ($baseName + "_root") -GroupType "ManagementCollectionType"
        Add-VMGroupMember -VMGroup $this.Terminator -VMGroupMember $this.Root -Confirm:$false

        $this.Servers = New-VMGroup -Name ($baseName + "_servers") -GroupType "VMCollectionType" 
        Add-VMGroupMember -VMGroup $this.Root -VMGroupMember $this.Servers -Confirm:$false

        $this.Workstations = New-VMGroup -Name ($baseName + "_workstations") -GroupType "VMCollectionType"
        Add-VMGroupMember -VMGroup $this.Root -VMGroupMember $this.Workstations -Confirm:$false 


	} # <--- close VTree


  	#------------------ Getters  -------------------#
    [Microsoft.HyperV.PowerShell.VMGroup []] branches () {
		[Microsoft.HyperV.PowerShell.VMGroup []] $branches = @()
        
        $this.Root.VMGroupMembers | ForEach-Object {
            $branches += $_
        }

		return $branches
        
	} # <--- close branches


	[Microsoft.HyperV.PowerShell.VMGroup] traverse ([TraversalDestination] $destination) {
        [Microsoft.HyperV.PowerShell.VMGroup] $branch = $null

        [string] $branchName = $this.Name + "_" + $destination.toString()
        $branch = $this.branches() | Where-Object { $_.Name -eq $branchName }

		return $branch

	} # <--- close traverse


    #------------------ Setters  -------------------#


	#------------------ Methods -------------------#
    [Bool] exsists ([string] $treeName) {
        [bool] $isNull = $null -eq ( Get-VMGroup | Where-Object {$_.Name -eq $treeName} )

        return $isNull

    } # <--- close exsists

    [Microsoft.HyperV.PowerShell.VirtualMachine []] leaves () { return $this.leaves([LeafCategory]::All) }

    [Microsoft.HyperV.PowerShell.VirtualMachine []] leaves ([LeafCategory] $leafCategory) {
        [Microsoft.HyperV.PowerShell.VirtualMachine []] $machines = @()

        if ( $leafCategory -eq [LeafCategory]::All ) {
            foreach ( $branch in $this.branches() ) {
                foreach ( $vm in $branch.VMMembers ) { $machines += $vm }
            }
        } 
        
        if ($leafCategory -eq [LeafCategory]::Servers -or $leafCategory -eq [LeafCategory]::Workstations) {
            foreach ( $vm in $this.traverse($leafCategory).VMMembers ) {
                $machines += $vm
            }
        }

        return $machines

    } # <--- close leaves


    [Microsoft.HyperV.PowerShell.VMGroup] branchOfLeaf ([string] $machineName) {
        [Microsoft.HyperV.PowerShell.VirtualMachine] $machine = $null
        [Microsoft.HyperV.PowerShell.VMGroup] $branch = $null

        $machine = Get-VM | Where-Object { $_.Name -eq $machineName }

        if ( $null -ne $machine ) {
            foreach ( $group in $machine.Groups ) {
                if ( $group.Name -in (Get-VMGroup | Where-Object { $_.Name -match  "_(workstations|servers)" } | Select-OBject Name).Name ) { #   $this.nodeNames() ) {
                    $branch = $group
                    break
                }
            }
        }
        return $branch

    } # <--- close branchOfLeaf


    [Microsoft.HyperV.PowerShell.VirtualMachine []] search ([string] $machineName, [searchType] $searchType = [searchType]::Fuzzy) {
        [Microsoft.HyperV.PowerShell.VirtualMachine []] $leaves = $this.leaves( [LeafCategory]::All ) 
        [Microsoft.HyperV.PowerShell.VirtualMachine []] $results = @()

        $results = $leaves | Where-Object { $_.Name -like "*$machineName*" }

        if ($searchType -eq [searchType]::Exact) {
            $results = $leaves | Where-Object { $_.Name -eq $machineName }
        }

        return $results

    } # <--- close search


    [Void] addLeaves ([TraversalDestination] $destination, [Microsoft.HyperV.PowerShell.VirtualMachine []] $leaves) {
        [Microsoft.HyperV.PowerShell.VMGroup] $branch = $null
        [Microsoft.HyperV.PowerShell.VirtualMachine []] $currentLeaves = @()

        $branch = $this.traverse($destination)
        $currentLeaves = $this.leaves($destination)

        $leaves | ForEach-Object {
            if ( ($currentLeaves -contains $_) -or ($_.Groups.Count -ne 0) )  {
                [string] $message = "`n`tCannot add VM < " + $_.Name + " > to " + $this.getType() + " branch [ " + $branch.Name + " ]. The machine is already in a group`n"
                Write-Error $message
                exit 1576
            }
            Add-VMGroupMember -VMGroup $branch -VM $_ -Confirm:$false -ErrorAction:Stop
        }

    } # <--- close addLeaves


    [void] removeLeaves ( [Microsoft.HyperV.PowerShell.VirtualMachine []] $leaves ) {
        [Microsoft.HyperV.PowerShell.VMGroup] $serverBranch = $this.traverse([TraversalDestination]::Servers)
        [Microsoft.HyperV.PowerShell.VMGroup] $workstationBranch = $this.traverse([TraversalDestination]::Workstations)
        [Microsoft.HyperV.PowerShell.VMGroup] $node = $null

        foreach ($leaf in $leaves) {
            [Microsoft.HyperV.PowerShell.VMGroup []] $groups = $leaf.Groups

            if (($groups -contains $serverBranch) -or ($groups -contains $workstationBranch)) {
                $node = $this.Servers

                if ($serverBranch -notin $groups) { $node = $this.Workstations }
                Remove-VMGroupMember -VMGroup $node -VM $leaf -Confirm:$false
            }
        }

    } # <--- close removeLeaves


    [void] empty() { $this.empty([LeafCategory]::All) }

    [Void] empty([LeafCategory] $leafCategory) {
        [Microsoft.HyperV.PowerShell.VMGroup] $node = $null

        if ( $leafCategory -eq [LeafCategory]::All ) {
            $node = Get-VMGRoup -Name $this.Root.Name

            foreach ($group in $node.VMGroupMembers) {
                foreach ($vm in $group.VMMembers) { Remove-VMGroupMember -VMGroup $group -VM $vm -Confirm:$false }
            }
        }

        if ( $leafCategory -in ([LeafCategory]::Servers, [LeafCategory]::Workstations) ) {
            $node = $this.traverse($leafCategory)
            $node.VMMembers | ForEach-Object { Remove-VMGroupMember -VMGroup $node -VM $_ -Confirm:$false }
        }

    } # <--- close empty


    [Void] delete() {
        $this.empty()
        
    <#    
        if ( $this.Servers.VMMembers.Count -gt 0 -and $this.Workstations.VMMembers.Count -gt 0 ) {
            Write-Error "Cannot delete " + $($this.getType()) + " " + $this.Name ".  It has hosts assigned to it"
            Exit 19000
        }
    #>

        if ( $this.Terminator.VMGroupMembers.Count -gt 1 ) {
            Write-Error $this.getType() + " " + $this.Name " is connected to another tree.  It cannot be deleted"
            Exit 22000
        }       

    [Microsoft.HyperV.PowerShell.VMGroup] $terminatorNode = $this.nullify()

    foreach ($rootNode in $terminatorNode.VMGroupMembers) {
       foreach ($branchNode in $rootNode.VMGroupMembers) {
            foreach ($vm in $branchNode.VMMembers) {
                Remove-VMGroupMember -VMGroup $branchNode -VM $vm -Confirm:$false
            }
            Remove-VMGroup -VMGroup $branchNode -Force:$true
        }
        Remove-VMGroup -VMGroup $rootNode -Force:$true
    } 
    Remove-VMGroup -VMGroup $terminatorNode -Force:$true
    $this.Name = [string]::Empty


    } # <--- close delete


    [int] size () { return $this.size([LeafCategory]::All) }


    [int] size ([LeafCategory] $leafCategory) {
        [int] $size = 0

        if ( $leafCategory -eq [LeafCategory]::All ) {
            $this.branches() | ForEach-Object {
                $size += $_.VMMembers.Count
            }
        }

        if ( $leafCategory -in ([LeafCategory]::Servers, [LeafCategory]::Workstations) ) {
            $size = $this.traverse($leafCategory).VMMembers.Count
        }

        return $size

    } # <--- close size


    [bool] isEmpty () {
        [bool] $isEmpty = $false

        [int] $machineCount = $this.Workstations.VMMembers.Count + $this.Servers.VMMembers.Count
        [int] $rootNodeCount = $this.Terminator.VMGroupMembers.Count

        if ( $machineCount -eq 0 -and $rootNodeCount -eq 1) {
            $isEmpty  = $true
        }
        return $isEmpty

    } # <--- close isEmpty


    [string] toString () {
        [string] $text = "{ " + $this.nodeString("workstations") 
        
        $text = $text + "<---" + $this.nodeString("root") + "--->" 
        $text = $text + $this.nodeString("servers") + " }"

        return $text

    } # <--- close toString


	#------------------ Helper Functions -------------------#
    [string] attachedLeaf ([Microsoft.HyperV.PowerShell.VirtualMachine] $leaf) {
        [string] $answer = "no"

        if ( $leaf.groups.count -gt 0 ) { $answer = "yes "}
        return $answer

    } # <--- close attachedLeaf 


    [Microsoft.HyperV.PowerShell.VMGroup] nullify () {
        [Microsoft.HyperV.PowerShell.VMGroup] $group = $this.Terminator
        $this.Terminator = $null
        return $group

    } # <--- close nullify


    hidden [void] removal ([Microsoft.HyperV.PowerShell.VMGroup] $group, [Microsoft.HyperV.PowerShell.VirtualMachine] $vm) {

        try {
            Remove-VMGroupMember -VMGroup $group -VM $vm -Confirm:$false -ErrorAction:Stop
       } catch {
           Write-Host "Removal of " + $vm.Name + " from $this.GetType() " + $this.Name + "'s " + $group.Name + " branch failed. Exitiing..."
           exit 5050
       }

    } # <--- close removal


    [string] branchString ([TraversalDestination] $destination) {
        [string] $text = [string]::Empty

        $text = "[" + $this.traverse($destination).Name + " (" + $( $this.size($destination) ) + ")]" 
        return $text
        
    } # <---  close nodeString


    [string] nodeString ([NodeType] $nodeType) {
        [string] $text = [string]::Empty

        if ( $nodeType -in ([NodeType] -in ([NodeType]::Servers, [NodeType]::Workstations)) ) { 
            $text = $this.branchString($nodeType) 
        }

        if ( $nodeType -eq [NodeType]::root ) { 
            $text = "[ VTree Name: " + $this.Name + " (size: " + $( $this.size("all") ) + ") ]" 
        }

        if ( $nodeType -eq [NodeType]::terminator ) { 
            $text = "" + $this.getType() + " " + (Create-PascalCaseString -Words $this.Name)
            $text = $text + " connections: "  + $this.Terminator.Name + " |---> " + $this.Root.Name
        }

        return $text
        
    } # <---  close nodeString

    hidden [string] vTreeName ([string] $nodeName) {
        [string] $vTreeName = [string]::Empty
        $vTreeName = $nodeName.Substring(0, $nodeName.Name.IndexOf('_') )

        return $vTreeName

    } # <--- close getBaseName

    hidden [string] makeNodeName ([string] $vTreeName, [string] $suffix) {
        if ( $suffix -notin $global:nodeSuffixes ) {
            throw $suffix + " is not a valid suffix for nodes in a " + $this.getType()
        }

        [string] $nodeName = [string]::Empty
        $nodeName = $vTreeName + "_" + $suffix

        return $nodeName

    } # <--- close getBaseName


	#------------------ Static Methods -------------------#
    static [Microsoft.HyperV.PowerShell.VMGroup []] getTerminators() {
        [Microsoft.HyperV.PowerShell.VMGroup []] $terminators = Get-VMGroup | Where-Object { $_.GroupType -eq "ManagementCollectionType" -and $_.Name -like "*_terminator" }
        [Microsoft.HyperV.PowerShell.VMGroup []] $vtrees = @()
    
        foreach ($terminator in $terminators) {
            [string] $vTreeName = $terminator.Name.Substring(0, $terminator.Name.IndexOf('_'))
            [string []] $rootNames = @()

            $terminator.VMGroupMembers | ForEach-Object {
                $rootNames += $_.Name
            }

            [string] $rootNodeName = $vTreeName + "_root"
            [string] $serversNodeName = $vTreeName + "_servers"
            [string] $workstationsNodeName = $vTreeName + "_workstations"
    
            if ( $rootNames -contains $rootNodeName ) {
                [string []] $branchNames = @()
                [Microsoft.HyperV.PowerShell.VMGroup] $rootNode = Get-VMGroup -Name $rootNodeName

                $rootNode.VMGroupMembers | ForEach-Object {
                    $branchNames += $_.Name
                }

                [bool] $comparisonResult = $null -eq (Compare-Object $branchNames ($serversNodeName, $workstationsNodeName) )

                if ( $comparisonResult -eq $true ) {
                    $vtrees + $terminator
                }
            }  
        }
        return $vtrees

    } # <--- close getTerminators


    hidden static [Microsoft.HyperV.PowerShell.VMGroup] previousNode ([Microsoft.HyperV.PowerShell.VMGroup] $node) {
        [Microsoft.HyperV.PowerShell.VMGroup] $previousNode = $null
        [Microsoft.HyperV.PowerShell.VMGroup] $group = $null
        
        [string] $baseName = $node.Name.Substring(0, $node.Name.IndexOf('_'))
        [string] $suffix = $node.Name.Substring( $node.Name.IndexOf('_') + 1 )

        [string] $sisterName = [string]::Empty
        [string] $currentNodeName = $node.Name

        [string []] $memberNames = @()

        if ( $suffix -eq "root" ) { $targetName = $baseName + "_terminator" }

        if ( $suffix -match "(servers|workstations)" ) {
            $targetName = $baseName + "_root"
            $sisterName = $baseName + "_workstations"

            if ($suffix -eq "workstations") {
                $sisterName = $baseName + "_servers"
            } 
        }

        $group = Get-VMGroup | Where-Object { $_.Name -eq $targetName }
        
        if ($group.VMGroupMembers -contains $node) {
            $previousNode = $group
        }
        return $previousNode

    } # <--- close previousNode

    
    static [Microsoft.HyperV.PowerShell.VMGroup []] mapByBranch () {
        [Microsoft.HyperV.PowerShell.VMGroup []] $branches = Get-VMGroup | Where-Object { $_.GroupType -eq "VMCollectionType" -and $_.Name -like "*_servers" }
        [Microsoft.HyperV.PowerShell.VMGroup []] $rootNodes = @()
        [Microsoft.HyperV.PowerShell.VMGroup []] $vtrees = @()

        $branches | ForEach-Object {
            $rootNodes += [VTree]::previousNode($_)
        }
    
        $rootNodes | ForEach-Object {
            $vtrees += [VTree]::previousNode($_)
        }

        return $vtrees

    } # <--- close mapByBranch

} # <--- end class 


#############################------- Define the NETWORK CLASS -------#############################
class Network {
	<#
	.SYNOPSIS
		Network is a collection of a group of switches and groups of for centralizing the management and creation of virtualmachines

	.DESCRIPTION
		The class is part of a series of collections for managing and creating dynamic virtual networks of arbitraty size.  It servers
		as a mechanism for viewing and managing the network configuration of hyper-v guests.  The class also provides unified and 
		central management of TCP/IP settings for a virtual network asociated with a switch.

	.FUNCTIONALITY 
	#>

 	#------------------ Properties  -------------------#
	[ValidateNotNullOrEmpty()]
	[string] $Name
	[string] $Path
	[VTree] $Tree

	[ValidateNotNullOrEmpty()]
	[IPAddress] $ID

	[ValidateRange(1,31)]
	[Int] $MaskLength

	[Int] $Capacity
	[Microsoft.HyperV.PowerShell.VMSwitch] $Switch


  	#------------------ Constructors  -------------------#
	Network () { }

	Network ([string] $rootName) { $this.Init($rootName, ($this.randomIPAddress()), 25) }
	Network ([string] $rootName, [Int] $maskLength) { $this.Init($rootName, ($this.randomIPAddress()), $maskLength) }
	Network ([string] $rootName, [IPAddress] $seedAddress, [Int] $maskLength ) { $this.Init($rootName, $seedAddress, $maskLength) }


	hidden init ([string] $rootName, [IPAddress] $seedAddress, [Int] $maskLength) {
		$rootName = $rootName.Trim().ToLower()

		if ($this.exists($rootName) -eq  $true) {
			throw "Cannot create a network named " + $rootName + ".. That name is already in use"
		}

		$this.Name = Create-PascalCaseString -Words $rootName
		$this.Tree = [VTree]::new($rootName)

		$this.MaskLength = $maskLength
		$this.ID = $this.getPrefix($seedAddress)
		$this.Capacity = ( [Math]::Pow(2,(32 - $this.MaskLength)) - 2 )	
		$this.Path = $global:BASE_NETWORK_PATH + $rootName.ToUpper() + "\"	
		$this.Switch = $this.switchBuilder()

	} # <--- close init


	#------------------ Getters  -------------------#
	[string] getName () { return $this.NetworkName }
	[Microsoft.HyperV.PowerShell.VMSwitch] getSwitch () { return $this.Switch }


	#------------------ Setters  -------------------#

	[ipaddress] hostAddress ([Int32] $counter) {
		[string] $dottedDecimal = [string]::Empty
		[string] $lambda = [string]::Empty

		[ipaddress] $hostAddress = $null
	
		if ( $counter -lt 1 -or $counter -gt $this.Capacity ) {
			throw $($Counter) + " is outside the range of possible hosts in the " + $this.Name + " network"
		}

		$octets = $this.ID.GetAddressBytes()

		if ([Bitconverter]::IsLittleEndian) {
			[Array]::Reverse($octets) 
		} 
		$hostNumber = [BitConverter]::ToUInt32($octets, 0)
		$hostNUmber += $counter

		$hexValue = [Convert]::ToString($hostNumber, 16)

		for ( $index = 0; $index -lt 7; $index +=2) { 
			$lambda = $lambda + $hexValue.ToString().Substring($index, 2) + "." 
		}
		$lambda = $lambda.TrimEnd('.').Trim()

		$lambda.Split('.') | ForEach-Object { 
			$dottedDecimal = $dottedDecimal + $([Convert]::ToInt32($_, 16)).ToString() + "." 
		}
		$hostAddress = [ipaddress] $dottedDecimal.trim(".").Trim()

		return $hostAddress

	} # <--- close HostAddress


	#------------------ Methods -------------------#
	[Int] size () {

		return $this.Tree.size()

	} # <--- close size


	[Bool] exists ([string] $target) {
		[Bool] $answer = $false

		if ( [Network]::networks() -contains $target ) { $answer = $true }
		return $answer

	} # <--- close found
#<#

	[Bool] isEmpty () {
		[bool] $isEmpty = $false

        if ( $this.Tree.isEmpty() -eq $true ) {
			if ( $this.switchActive() -eq $false ) {
				$isempty = $true
			}
		}
		return $isEmpty

	} # <--- close isEmpty
#>

	[bool] pathExsists () {
		[bool] $pathExsists = $null -eq (Get-ChildItem -Path $global:BASE_NETWORK_PATH -Name $this.Name.ToUpper() -Directory:$true)
		return $pathExsists

	} # <--- close pathExists


    [Bool] switchActive () {
        [Bool] $isActive = $false
		[String []] $activeSwitches = (Get-VMNetworkAdapter -VMName * | Select-Object SwitchName -Unique).SwitchName

		if ($activeSwitches -contains $this.Switch.Name) { $isActive = $true }
        return $isActive

    } # <--- close activeSwitch


    [void] empty () {

        if ($this.switchActive() -eq $true) { 
			throw "Hosts are connected to " + $this.Switch.Name + ".  The switch cannot be deleted" 
			exit 4506
		}

        if ($this.Tree.isEmpty() -eq $false) {
           throw $this.Tree.Root.Name + " is not empty.  The " + $this.Name + " network cannot be deleted while hosts are present"
		   exit 7893
         }

		$this.Tree.empty()
        Remove-VMSwitch -Name $this.Switch.Name -Confirm:$false -Force:$true

    } # <--- close erase

	[void] delete () {

        if ($this.switchActive() -eq $true) { 
			throw "Deletion of <$($this.Name)> $($this.getType()) fsiled.  There are actve connections to $($this.Switch.getType()) to <$($this.Switch.Name)>"
			exit 7700
		}

        if ($this.Tree.isEmpty() -eq $false) {
            throw "Deletion of <$($this.Name)> $($this.getType()) fsiled.  " + $this.Tree.getType() + " " + $this.Tree.Root.Name + " is not empty"
			exit 7800
        }
		
		$this.Tree.delete()
        Remove-VMSwitch -Name $this.Switch.Name -Confirm:$false -Force:$true

		if ((Test-Path $this.Path) -eq $true) {
			Set-Location $global:BASE_NETWORK_PATH
			Remove-Item -Path $this.Name -Recurse -Force -Confirm:$false
		}
	
    } # <--- close delete

	
	[string] toString() {
		[string] $text= $this.networkString() + ", " + $this.switchString() + ", " + $this.treeString() + "}" 
		return $text

	} #<--- close toString


	#------------------ Helper Functions -------------------#
	hidden [IPAddress] getPrefix ([IPAddress] $seedAddress) {
		[string] $addressBits = [string]::Empty
		[string] $networkBits = [string]::Empty
	
		[string] $maskbits = ('1' * $this.MaskLength).PadRight(32, '0')
	
		$SeedAddress.IPAddressToString.split(".") | ForEach-Object { $addressBits = $addressBits + $( [Convert]::ToString($_, 2).PadLeft(8, "0") ) }
		$addressBits = $addressBits.Trim()
	
		for ( [Int] $index = 0; $index -lt 32; $index++ ) {
			[string] $addressBit = $addressBits.Substring($index, 1)
			[string] $maskBit = $maskBits.Substring($index, 1)
	
			if ($addressBit -eq "1" -and $maskBit -eq "1") {
				$networkBits= $networkBits  + "1"
			} else { 
				$networkBits = $networkBits + "0" 
			}
		}
		$networkBits = $networkBits.Trim()
	
		# Convert the binary netID into a dotted decimal string
		[string] $lambda = [string]::Empty
		for ( $index = 0; $index -lt 32; $index += 8 ) { 
			$lambda = $lambda + [Convert]::ToInt32( $networkBits.SubString( $index, 8 ), 2 ) + "." 
		}
		$lambda = $lambda.Trim('.')
		[IPAddress] $networkID = [IPAddress] $lambda.Trim()
	
		return $networkID

	} # <--- close getNetPrefix 

	hidden [IPaddress] randomIPAddress () {
		[IPAddress] $ipAddress = $null

		[string] $octets = "192.168."
		[string] $thirdOctet = [string] $(Get-Random -Minimum 44 -Maximum 254)
		[string] $fourthOctet =[string] $(Get-Random -Minimum 1 -Maximum 254)
	
		$octets = $octets + $thirdOctet + "." + $fourthOctet
		$IPAddress = [IPAddress] $octets.Trim()

		return $IPAddress

	} # <--- close randomIPAddress


	hidden [Microsoft.HyperV.PowerShell.VMSwitch] switchBuilder () {
		[Microsoft.HyperV.PowerShell.VMSwitch] $sw = $null

		[string] $switchName = $this.Name.ToUpper() + "_Private"
		[string] $notes = $this.ID.ToString() + "/" + $($this.MaskLength)

		$sw = New-VMSwitch -Name $switchName -SwitchType "Private" -Notes $notes

		return $sw

	} # <--- close switchBuilder


	hidden [string] switchString () {
		[string] $text = "[ Switch: " + $this.Switch.Name + ", CIDR: " + $this.Switch.Notes + " ]"
		return $text

	} # <--- close switchString


	hidden [string] treeString () {
		[string] $text = "[ " + $($this.Tree.size()) + " hosts in " + $this.Tree.Root.Name + " ] "
		return $text

	} # <--- close treeString

	hidden [string] networkString () {
		[string] $text = "Network " + $this.Name + " = {ID: " + $this.ID.toString() + ", Host Capacity: " 
		$text = $text + $($this.Capacity) + ", Physical Location: " + $this.Path

		return $text

	} # <--- close networkString


	#------------------ Static Methods -------------------#
	static [String[]] networks () {
		[String []] $names = [String []] (Get-ChildItem -Path $global:BASE_NETWORK_PATH | Where-Object { $_.PSIsContainer -eq $true } | Select-Object Name)   

		return $names

	} # <--- close Networks

} # <-- End class Network


#############################------- Define the Automata CLASS -------#############################
class Automata {
	<#
	.SYNOPSIS
		The Server class creates a VM which inherits it's base configuration and phyiscal properties from the Network class.

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

 	#------------------ Properties  -------------------#
	 [string] $Hostname
	 [string] $Path
	 [string] $Notes
	 [Int] $DiskGigaBytes
	 [Int] $MemoryGigaBytes

	 [Network] $Network
	 [ipaddress] $Address
	 [Microsoft.HyperV.PowerShell.VirtualMachine] $Machine

	 
  	#------------------ Constructors  -------------------#
	Automata () {}

	Automata ([string] $name, [int] $memoryGigs, [int] $diskGigs, [Network] $network) {
		$this.Network = $network
		$this.Hostname = $this.hostNameHandler($name)
	#	$this.Path = $this.pathBuilder($name)
		$this.MemoryGigaBytes = $memoryGigs
		$this.DiskGigaBytes = $diskGigs

	} # <--- close Automata


	#------------------ Methods -------------------#
	[void] delete() {
		[bool] $vmExists = $null -ne  (Get-VM | Where-Object { $_.name -eq $this.Machine.Name } )

		if ( $vmExists -eq $false ) {
			throw $this.Machine.Name + " cannot be deleted because it does not exist"
		}

		Get-VMHardDiskDrive -VM $this.Machine | ForEach-Object { 
			Remove-Item -Path $_.Path -Confirm:$false 
		}

		Remove-VM -VM $this.Machine -Force:$true -Confirm:$false
		Remove-Item -Path $this.Path -Force:$true -Confirm:$false

		$this.Machine = $null
		$this.Address = $null
		$this.Hostname = $null
		$this.Path = $null
		$this.Network = $null

		$this.DiskGigaBytes = 0
		$this.MemoryGigaBytes = 0

	} # <--- close delete


#------------------ Helper Functions -------------------#
hidden [string] pathBuilder ([string] $name) {
	[string] $networkPath = $this.Network.Path
	[string] $machineDirectory = (Create-PascalCaseString -Words $name) + "\"

	return ($networkPath + $machineDirectory)

} # <--- close pathBuilder


hidden [string] hostNameHandler ([string] $name) {
	$name = $name.Trim().ToLower()
	
	[string] $target = $this.Network.Name.ToUpper() + "_" + (Create-PascalCaseString -Words $name)
	[bool] $nameInUse = $null -ne (Get-VM | Where-Object { $_.Name -eq $target })

	if ($nameInUse -eq $true) {
		throw "The name <" + $name + "> has been assigned to another virtual machine in the network.  Pick a different one"
	}
	return $name 

} # <--- close hostNameHandler


hidden [string] vmNameHandler () {
	[string] $vmName = $null
	$vmName = $this.Network.Name.ToUpper() + "_" + (Create-PascalCaseString -Words $this.Hostname)

	return $vmName

} # <-- close vmNameHandler


hidden [Microsoft.HyperV.PowerShell.VirtualMachine] machineBuilder () {
	[Microsoft.HyperV.PowerShell.VirtualMachine] $vm = $null

	[hashtable] $params = @{
		Generation = 2
		Name = $this.vmNameHandler()
		NewVHDPath = $this.Path + $this.Hostname + ".vhdx"
		NewVHDSizeBytes = ([int64] $this.DiskGigaBytes) * $global:BYTES_PER_GIGABYTE
		MemoryStartupBytes = ([int64] $this.MemoryGigaBytes) * $global:BYTES_PER_GIGABYTE
		SwitchName = $this.Network.Switch.Name
	}
	$vm = New-VM @params
	
	$this.Notes = $this.noteBuilder()
	Set-VM -VM $vm -Notes $this.Notes
	return $vm

} # <--- close machineBuilder


#------------------ Static Methods -------------------#


} # <--- End Automata Class


#############################------- Define the SERVER CLASS -------#############################
class Server : Automata {
	<#
	.SYNOPSIS
		The Server class creates a VM which inherits it's base configuration and phyiscal properties from the Network class.

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

 	#------------------ Properties  -------------------#
	[ServerOSVersion] $OperatingSystem
	[ServerRoles] $Roles
	[UserInterface] $UserInterface


	[ValidateRange(10,100)]
    [Int] $ExtraStorageSize

	[ValidateRange(2,12)]
    [Int] $ExtraDisks


	#------------------ Constructors  -------------------#
	Server () : base() {}

	Server ([string] $name, [int] $memoryGigs, [int] $diskGigs, $network) : base($name, $memoryGigs, $diskGigs, $network) { 
		$this.init([ServerOSVersion]::server2016, [ServerRoles]::None, [UserInterface]::Core, 0, 0)
	}

	hidden [void] init ([ServerOSVersion] $osVersion, [ServerRoles] $roles, [UserInterface] $interface, [int] $gigs, [int] $disks) {
		$this.OperatingSystem = $osVersion
		$this.Roles = $roles
		$this.UserInterface = $interface
		$this.Path = $this.pathBuilder()
		$this.Machine = $this.machineBuilder()
		$this.mediaLoader()

		$this.Network.Tree.addLeaves("servers", $this.Machine)
		$this.Address = $this.Network.hostAddress($this.Network.size())
		$this.Notes = $this.noteBuilder()

	} # <--- close init


	#------------------ Methods -------------------#
	[void] extraStorage([int] $rawGigs, [int] $diskCount) {
		<#
		[string []] $invalidRoles = "ca", "router"

		foreach ($role in $this.Roles) {
			if ($invalidRoles -contains $role) {
				throw "Cannot add storage array to " + $this.GetType() + " " + $this.HostName + " because its' roles include " + $role + " is not ideal for this configuration"
			}
		}
#>
		if ($this.UserInterface -eq [UserInterface]::Nano) {
            throw $this.GetType() + " <" + $this.HostName + "> configured with " + $this.UserInterface.ToString() + " shell is not compatible with a storage array"
        }

		$this.ExtraStorageSize = $rawGigs
		$this.ExtraDisks = $diskCount
		$this.buildNas()

	} # <--- close extraStorage


	[void] mediaLoader () {
		[string] $isoPath = [string]::Empty

		if ($this.OperatingSystem -eq [ServerOSVersion]::server2016) {
			$isoPath = $global:SERVER_2016_ISO_PATH
		}

		if ($this.OperatingSystem -eq [ServerOSVersion]::server2019) {
			$isoPath = $global:SERVER_2019_ISO_PATH
		}

		if ($this.OperatingSystem -eq [ServerOSVersion]::server2022) {
			$isoPath = $global:SERVER_2022_ISO_PATH
		}

		Add-VMDvdDrive -VM $this.Machine -Path $isoPath -Confirm:$false

		[hashtable] $params = @{
			VM = $this.Machine
			BootOrder = (Get-VMDvdDrive -VM $this.Machine), (Get-VMHardDiskDrive -VM $this.Machine), (Get-VMNetworkAdapter -VM $this.Machine)
		} 
		Set-VMFirmware @params 

	} # <--- close mediaLoader


	hidden [string] nasString () {
		[string] $text = [string]::Empty

		if ( $this.ExtraStorageSize -gt 0 -and $this.ExtraDisks -gt 0 ) {
			$text = "( NAS Raw Size: " + $($this.ExtraStorageSize) + " GB " + " Disk Count: " + $($this.ExtraDisks) + " )"
		}
		return $text

	} # <--- close nasString


	[string] toString () {
		[string] $text = "[ hostName: " + $this.HostName + " " + $this.noteBuilder() + " " + $this.nasString() + " ]"
		return $text

	} # <--- close toString

	#------------------ Helper Functions -------------------#
	hidden [string] pathBuilder () {
		[string] $networkPath = $this.Network.Path + "servers\"
		[string] $machineDirectory = (Create-PascalCaseString -Words $this.Hostname) + "\"
	
		return ($networkPath + $machineDirectory)
	
	} # <--- close pathBuilder


	hidden [void] buildNas (){
		[string] $number = [string]::Empty
		[string] $prefix = $this.Path + $this.hostName.ToLower() 

		[Int64] $bytes = ($this.ExtraStorageSize / $this.ExtraDisks) * $global:BYTES_PER_GIGABYTE

		for ( [int] $index = 1; $index -le $this.ExtraDisks; $index++ ) {
			if ($index -le 9) { $number = "0" + $index }
			else { $number = $index }

			[string] $diskPath = $prefix + "-disk-" + $number + ".vhdx"

			New-VHD -Path $diskPath -SizeBytes $bytes
			Add-VMHardDiskDrive -VM $this.Machine -Path $diskPath
		}

	} # <--- close buildNas


	hidden [string] makePropertyString ([string] $property) {
		[string] $propertyString = [string]::Empty
	
		switch ($property) {
			"hostName" { $propertyString = "Hostname: " + $this.Hostname + ",`n"}
			"category" { $propertyString = "automataType: " + $this.GetType() + ",`n"}
			"osVersion" { $propertyString = "osVersion: " + $this.OperatingSystem.ToString() + ",`n"}
			"userInterface" { $propertyString = "userInterface: " + $this.UserInterface.ToString() + ",`n"}
			"address" { $propertyString = "Address: " + $this.Address + ",`n" }
			"path" { $propertyString = "Path: " + $this.Path }
		}
		return $propertyString
	
	} # <--- close propertyString
	
	
	hidden [string] noteBuilder () {
		[string] $note = [string]::Empty
		[string []] $properties = @("hostname", "category", "osVersion", "userInterface", "address" ,"path")
	
		foreach ($property in $properties) {
			$note += $this.makePropertyString($property)
		}
		return $note
	
	} # <--- close noteBuilder


	#------------------ Static Methods -------------------#


} # <--- end Server class



#############################------- Define the WORKSTATION CLASS -------#############################
class Workstation : Automata {
	<#
	.SYNOPSIS
		The Server class creates a VM which inherits it's base configuration and phyiscal properties from the Network class.

	.DESCRIPTION

	.FUNCTIONALITY 
	#>

 	#------------------ Properties  -------------------#
	 [WorkstationOSVersion] $OperatingSystem


	#------------------ Constructors  -------------------#
	Workstation () : base() {}


	Workstation ([string] $name, $network) : base($name, 1, 60, $network) { 
		$this.init([WorkstationOSVersion]::Windows10)
	}

	Workstation ([string] $name, [int] $memoryGigs, [int] $diskGigs, $network) : base($name, $memoryGigs, $diskGigs, $network) { 
		$this.init([WorkstationOSVersion]::Windows10)
	}

	hidden [void] init ([WorkstationOSVersion] $operatingSystem) {
		$this.OperatingSystem = $operatingSystem

		$this.Path = $this.pathBuilder()
		$this.Machine = $this.builder()

	} # <--- close init


	#------------------ Methods -------------------#
	[Microsoft.HyperV.PowerShell.VirtualMachine] builder () {
		[Microsoft.HyperV.PowerShell.VirtualMachine] $vm = $null
		[string] $isoPath = $global:WINDOWS_10_ISO_PATH

		$vm = $this.machineBuilder()
		Add-VMDvdDrive -VM $vm -Path $isoPath -Confirm:$false
		Set-VMFirmware -VM $vm -BootOrder (Get-VMDvdDrive -VM $vm), (Get-VMHardDiskDrive -VM $vm), (Get-VMNetworkAdapter -VM $vm)

		$this.Network.Tree.addLeaves("workstations", $vm)
		$this.Address = $this.Network.hostAddress($this.Network.size())
		$this.Notes = $this.noteBuilder()

		Set-VM -VM $vm -Notes $this.Notes
		return $vm

	} # <--- close builder


	[string] toString () {
		[string] $text = "[ hostName: " + $this.HostName + " " + $this.noteBuilder() + " ]"
		return $text

	} # <--- close toString


	#------------------ Helper Functions -------------------#
	hidden [string] pathBuilder () {
		[string] $networkPath = $this.Network.Path + "workstations\"
		[string] $machineDirectory = (Create-PascalCaseString -Words $this.Hostname) + "\"
	
		return ($networkPath + $machineDirectory)
	
	} # <--- close pathBuilder


	hidden [string] makePropertyString ([string] $property) {
		[string] $propertyString = [string]::Empty
	
		switch ($property) {
			"hostName" { $propertyString = "Hostname: " + $this.Hostname + ",`n"}
			"category" { $propertyString = "automataType: " + $this.GetType() + ",`n"}
			"osVersion" { $propertyString = "osVersion: " + $this.OperatingSystem.ToString() + ",`n"}
			"address" { $propertyString = "Address: " + $this.Address + ",`n" }
			"path" { $propertyString = "Path: " + $this.Path }
		}
		return $propertyString
	
	} # <--- close propertyString
	
	
	hidden [string] noteBuilder () {
		[string] $note = [string]::Empty
		[string []] $properties = @("hostname", "category", "osVersion", "address" ,"path")
	
		foreach ($property in $properties) {
			$note += $this.makePropertyString($property)
		}
		return $note
	
	} # <--- close noteBuilder


	#------------------ Static Methods -------------------#
	
	
} # <--- end Workstations class


function Create-PascalCaseString ([String []] $Words) {
    [string] $pascalCase = [string]::Empty

    foreach ($Word in $Words) {
        $Word = $Word.Trim()

		if ($Word -contains "-" -or $word -contains "_") {
			$Word = (Get-ParentName -FullName $Word) + (Get-ChildName -FullName $word)
		} 
        $pascalCase = $pascalCase + $Word.Substring(0,1).ToUpper() + $Word.Substring(1)
    }
    return $pascalCase

} # <--- close Create-PascalCaseString


function Get-ParentName ([string] $FullName) {
	[string] $parentName = $fullName
	[string] $regex = '(\-|\_)'
	[string] $separator = "-"

	if ( ($fullName -match $regex) -eq $true) {
		if (($fullName.ToCharArray()) -contains '_') { 
			$separator = "_"
		}
		$parentName = $fullName.SubString(0, $fullName.IndexOf($separator))
	}

	return parentName

} # <--- close Get-ParentName

function Get-ChildName ([string] $FullName) {
	[string] $childName = $fullName
	[string] $regex = '(\-|\_)'
	[string] $separator = "-"

	if ( ($fullName -match $regex) -eq $true) {
		if (($fullName.ToCharArray()) -contains '_') { 
			$separator = "_"
		}
		$childName = $fullName.SubString($fullName.IndexOf($separator) + 1)
	}
	return $childName

} # <--- close Get-ChildName