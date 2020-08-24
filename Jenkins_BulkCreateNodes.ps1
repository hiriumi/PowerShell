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
    [int]$NodeCount = 5,
    [Parameter(Mandatory=$False)]
    [string]$NodeNamePattern = "winnode-###",
    [Parameter(Mandatory=$False)]
    [string]$Description = "Bulk gen'ed node",
    [Parameter(Mandatory=$False)]
    [string]$RemoteRootDir = "C:\slave",
    [Parameter(Mandatory=$False)]
    [string]$Mode = "NORMAL",
    [Parameter(Mandatory=$False)]
    [int]$NumExecutors = 1,
    [Parameter(Mandatory=$False)]
    [string]$Labels = "",
    [Parameter(Mandatory=$False)]
    [string]$JenkinsCliJarFilePath = "$env:HOMEPATH\Downloads\jenkins-cli.jar",
    [Parameter(Mandatory=$False)]
    [bool]$OverwriteNodeIfExists = $False,
    [Parameter(Mandatory=$False)]
    [string]$JsonDataPath = "$env:TMP"
)

$digitCount = ($NodeNamePattern.ToCharArray() | Where-Object {$_ -eq '#'} | Measure-Object).Count

ForEach ($index In 1..$NodeCount)
{
    $number = "{0:D$digitCount}" -f $index
    $nodeName = $NodeNamePattern -replace "#{$digitCount}", $number 
    $xmlSettings = New-Object System.Xml.XmlWriterSettings
    $xmlSettings.Indent = $true
    $xmlSettings.Encoding = [System.Text.Encoding]::UTF8
    $xmlSettings.OmitXmlDeclaration = $True
    $xmlSettings.ConformanceLevel = "Document"

    $sw = New-Object System.IO.StringWriter
    $xw = [System.Xml.XmlWriter]::Create($sw, $xmlSettings)
    
    try 
    {
        $xw.WriteStartElement("slave")

        $xw.WriteElementString("name", $nodeName)
        $xw.WriteElementString("description", $Description)
        $xw.WriteElementString("remoteFS", $RemoteRootDir)
        $xw.WriteElementString("numExecutors", $NumExecutors)
        $xw.WriteElementString("mode", $Mode)

        $xw.WriteStartElement("retentionStrategy")
        $xw.WriteAttributeString("class", 'hudson.slaves.RetentionStrategy$Always')
        $xw.WriteEndElement() # retentionStrategy

        $xw.WriteStartElement("launcher")
        $xw.WriteAttributeString("class", "hudson.slaves.JNLPLauncher")

        $xw.WriteStartElement("workDirSettings")
        $xw.WriteElementString("disabled", "false")
        $xw.WriteElementString("internalDir", "remoting")
        $xw.WriteElementString("failIfWorkDirIsMissing", "false")
        $xw.WriteEndElement() # workDirSettings
        $xw.WriteElementString("websocket", "false")
        $xw.WriteEndElement() # launcher

        $xw.WriteElementString("label", $Labels)
        $xw.WriteElementString("nodeProperties", "")
        $xw.WriteEndElement() #slave
        $xw.WriteEndDocument()
        $xw.Flush()
    }
    catch [System.Exception]
    {
        Write-Host $_
        exit 1
    }
    finally 
    {
        $xw.Close()
    }

    # Write out the node XML to file to be used for standard input below.
    Set-Content -Path "$nodeName.xml" -Value $sw.ToString()

    # Check the existence of the node.

    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "java"
    $processInfo.RedirectStandardError = $True
    $processInfo.RedirectStandardOutput = $True
    $processInfo.RedirectStandardInput = $True
    $processInfo.Arguments = "-jar $JenkinsCliJarFilePath -s $JenkinsServerUrl -auth $Username`:$ApiToken get-node $nodeName"
    $processInfo.UseShellExecute = $False

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    $si = $process.StandardInput
    $si.WriteLine($sw.ToString())
    $si.Close()
    $process.WaitForExit()
    $stdo = $process.StandardOutput
    $stde = $process.StandardError

    If ($process.ExitCode -ne 0)
    {
        Write-Host $stdo
        Start-Process -FilePath java -NoNewWindow -Wait -ArgumentList "-jar $JenkinsCliJarFilePath","-s $JenkinsServerUrl","-auth $Username`:$ApiToken","create-node" -RedirectStandardInput "$nodeName.xml"
    }
    else 
    {
        If ($OverwriteNodeIfExists)
        {
            Write-Host "Deleting $nodeName..."
            Start-Process -FilePath java -NoNewWindow -Wait -ArgumentList "-jar $JenkinsCliJarFilePath","-s $JenkinsServerUrl","-auth $Username`:$ApiToken","delete-node $nodeName"

            Write-Host "Recreating $nodeName..."
            Start-Process -FilePath java -NoNewWindow -Wait -ArgumentList "-jar $JenkinsCliJarFilePath","-s $JenkinsServerUrl","-auth $Username`:$ApiToken","create-node" -RedirectStandardInput "$nodeName.xml"
        }
        else 
        {
            Write-Host "Node $nodeName exists."   
        }
    }
}