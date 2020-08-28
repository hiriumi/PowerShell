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
    [string]$ServiceRootDir = "C:\slave",
    [Parameter(Mandatory=$False)]
    [bool]$UseLocalSystemAccount = $True,
    [Parameter(Mandatory=$False)]
    [string]$RunServiceAsAccount = "",
    [Parameter(Mandatory=$False)]
    [SecureString]$RunServiceAsPassword,
    [Parameter(Mandatory=$False)]
    [string]$WinswVersion = "latest", # Enter the specified version if necessary.
    [Parameter(Mandatory=$False)]
    [string]$WindowsServiceName = "JenkinsSlave",
    [Parameter(Mandatory=$False)]
    [string]$ServiceDescription = "Jenkins Slave ($WinswVersion)"
    
)

Function ValidateParameters
{
    $Result = $True
    $Message = ""

    if (!$UseLocalSystemAccount)
    {
        if ([string]::IsNullOrEmpty($RunServiceAsAccount))
        {
            Return $False, "Please pass -RunServiceAsAccount parameter."
        }
    }

    
}


$paramValidated, $message = ValidateParameters
if (!$paramValidated)
{
    Write-Host $message
    exit 1
}