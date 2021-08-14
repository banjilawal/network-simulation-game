

$automataName = Get-Content "C:\Users\griot\Dropbox\scripts\firstnames.txt" | Get-Random
$serverName = Get-Content "C:\Users\griot\Dropbox\scripts\complete_gods.txt" | Get-Random
$workstationName = Get-Content "C:\Users\griot\Dropbox\scripts\single_words.txt" | Get-Random

$network = [Network]::new( (Get-Content "C:\Users\griot\Dropbox\scripts\single_word_cities.txt" | Get-Random) )
$server = [Server]::new($serverName, 1, 60, $network)
#$server.extraStorage(10, 2)


#"`nNetwork Informtion for " + $server.Hostname + ":"
#$server.Network
$a = $server
#$server.Network.Tree.branchOfLeaf($a)

$workstation = [Workstation]::new($workstationName, $network)

"Network Information:"
$server.Network.ToString()

"Server information:"
$server.ToString()


"`nWorkstation Information:"
$workstation.ToString()

Get-VMGroup | Where-Object {$_.VMMembers -contains $server.Machine}

<#
$automata = [Automata]::new($automataName, 1, 60, $network)
$automata

$automata.Machine.Notes
$automata.delete()
$network.delete()
#$automata.Network
#>