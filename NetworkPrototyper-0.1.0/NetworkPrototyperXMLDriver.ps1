. $PSScriptRoot\NetworkPrototyper-0.1.0.ps1

$dataSetsPath = "C:\Users\griot\Dropbox\scripts\datasets\"

$network = [Network]::new( (Get-Content ($dataSetsPath + "single_word_cities.txt") | Get-Random) )

[int] $workstationTotal = Get-Random -Minimum 1 -Maximum 4
[int] $serverTotal = Get-Random -Minimum 5 -Maximum 10

[string] $workStationFilePath = "xml\workstations\"
[string] $serverFilePath = "xml\servers\"
[string] $networkFilePath = "xml\networks\"
[string] $xmlPath = "xml\"

for ( [int] $index = 0; $index -lt $workstationTotal; $index++ ) {
    $name = Get-Content ($dataSetsPath + "single_words.txt") | Get-Random
    $workstation = [Workstation]::new($name, $network)
    $workstation | Export-Clixml ($workStationFilePath + $workstation.Hostname + ".xml")
}

for ( [int] $index = 0; $index -lt $serverTotal; $index++ ) {
    $name = Get-Content ($dataSetsPath + "complete_gods.txt") | Get-Random
    $server = [Server]::new($name, 1, 60, $network)
    $server | Export-Clixml ($serverFilePath + $server.Hostname + ".xml")
}

$network | Export-Clixml -Depth 4 ($networkFilePath + $network.Name + ".xml")