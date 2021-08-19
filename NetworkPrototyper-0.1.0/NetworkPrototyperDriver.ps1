$dataSetsPath = "C:\Users\griot\Dropbox\scripts\datasets"

$automataName = Get-Content "$dataSetsPath\firstnames.txt" | Get-Random
$serverName = Get-Content "$dataSetsPath\complete_gods.txt" | Get-Random
$workstationName = Get-Content "$dataSetsPath\single_words.txt" | Get-Random

$network = [Network]::new( (Get-Content "$dataSetsPath\single_word_cities.txt" | Get-Random) )
$server = [Server]::new($serverName, 1, 60, $network)
#$server.extraStorage(10, 2)

[int] $networkSize = Get-Random -Minimum 5 -Maximum 10
[int] $workStationCount = Get-Random -Minimum 2 -Maximum 4
[int] $serverCount = $networkSize - $workStationCount

for ( [int] $index; $index -lt $neworkSize; $index++ ) {
    if ( $index -lt $workStationCount ) {
        $name = Get-Content "$dataSetsPath\single_words.txt" | Get-Random
        $workstation = [Workstation]::new($name, $network)
    }

    else {
        $serverName = Get-Content "$dataSetsPath\complete_gods.txt" | Get-Random
        $server = [Server]::new($name, $network)
    }
}


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