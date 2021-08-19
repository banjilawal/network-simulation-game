. C:\Users\griot\workspace\network-simulation-game\NetworkPrototyper-0.1.0\NetworkPrototyper-0.1.0.ps1

$tree = [VTRee]::new( (Get-Content "C:\Users\griot\Dropbox\scripts\single_words.txt" | Get-Random) ) 
$tree | Export-Clixml tree.xml