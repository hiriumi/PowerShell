<#
    .SYNOPSIS
       Generates Jenkins nodes.
    .DESCRIPTION
       This script bulk generates Jenkins nodes on the master so that nodes will be ready for Jenkins slaves to talk to them. 
#>
[CmdletBinding()]
param 
(
    [Parameter(Mandatory=$True)] 
    [string]$JenkinsServerUrl,
    [Parameter(Mandatory=$True)]
    [string]$Username,
    [Parameter(Mandatory=$True)]
    [string]$ApiToken,
    [Parameter(Mandatory=$False)]
    [straing]$NodeNamePattern = "winnode-###",
    [Parameter(Mandatory=$False)]
    [int]$NodeCount = 10,
    [Parameter(Mandatory=$False)]
    [string]$Labels = "",
    [Parameter(Mandatory=$False)]
    [string]$Description = ""
    
)

process 
{
    
}