. C:\Users\griot\workspace\network-simulation-game\NetworkPrototyper-0.1.0\NetworkPrototyper-0.1.0.ps1

$memory = 2
$disk = 60
$network = [Network]::new("imaging")
foreach ($name in ("dc", "wds", "dns2", "dhcp")) {
    if  ($name -in ("dc", "wds")) { $disk = 100 }
    $server = [Server]::new($name, $memory, $disk, $network)
}