# This script generates JSON data for Jenkins_CreateNode.ps1

$NodeData = [PSCustomObject]@{
    Version = "1.0"
    BaseJenkinsUrl = "https://jenkins.linux-mint.local/"
    NodeCount = 10
    NodeNamePattern = "winnode-"
    Labels = "WINDOWS2019 FLEET10"
}
 
$data3 | ConvertTo-Json | Set-Content -Path "data3.json"