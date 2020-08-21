Import-Module WebAdministration
Push-Location
Set-Location IIS:
Set-Location 'Sites\Default Web Site'
Get-ChildItem | Where-Object {$_.NodeType –eq “application”} | ForEach-Object {Remove-WebApplication $_.Name}
Pop-Location