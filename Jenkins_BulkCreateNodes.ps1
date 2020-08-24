<#
    .SYNOPSIS
       Generates Jenkins nodes.
    .DESCRIPTION
        This script bulk generates Jenkins nodes on the master so that nodes will be ready for Jenkins slaves to talk to them. 
        It utilizes Jenkins CLI, so Java (https://java.com/en/download/) and downloaded jenkins-cli.jar file from Jenkins master is required.
    .PARAMETER JenkinsServerUrl
        Required. Base URL of the Jenkins master. e.g. https://myjenkins.com/
    .PARAMETER Username
        The username to use for this process.
    .PARAMETER ApiToken
        Generated API Token of the username.
    .PARAMETER NodeCount
        Specifies how many nodes to created.
    .PARAMETER NodeNamePattern
        Specify the pattern of node name here. If 20 nodes to be created and "foobar-###" is passed, foobar-001 to foobar-020 would be generated.
    .PARAMETER Description
        Optional. Specify the description of each node. Use this field to specify what kind of fleet you are creating.
    .PARAMETER RemoteRootDir
        Optional. Defaults to "C:\slave". Specify any directory where you expect slave bits to reside on each node.
    .PARAMETER Mode
        Optional. Defaults to NORMAL.
    .PARAMETER NumExecutors
        Optional. Defaults to 1.
    .PARAMETER Labels
        Optional. e.g. "WINDOWS 2019". Separate labels by space.
    .PARAMETER JenkinsCliJarFilePath
        Optional. When you download jenkins-cli.jar, the file is usually at ~/Download/jenkins-cli.jar. Downaload the file from https://your-jenkins-server/jnlpJars/jenkins-cli.jar
        There is a download link on https://your-jenkins-server/cli
    .PARAMETER OverwriteNodeIfExists
        Optional. If the node to be created already exists on the Jenkins master, it deletes it and recreates it if $True is passed. If $False, it is skipped.
    .PARAMETER KeepNodeXmlFiles
        Optional. Defaults to $False. If $True is passed, the XML files created for the nodes will be kept in the same directory as this script. This option could be used to reuse the XML files in different environments.
    
    
    
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
    [bool]$KeepNodeXmlFiles = $False
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
    Set-Content -Path "$nodeName.xml" -Value $sw.ToString() -Force

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
    $process.WaitForExit()
    $stdo = $process.StandardOutput

    If ($process.ExitCode -ne 0)
    {
        Start-Process -FilePath java -NoNewWindow -Wait -ArgumentList "-jar $JenkinsCliJarFilePath","-s $JenkinsServerUrl","-auth $Username`:$ApiToken","create-node" -RedirectStandardInput "$nodeName.xml"
        Write-Host "$nodeName created ($(Get-Date))"
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

        If (!$KeepNodeXmlFiles)
        {
            Remove-Item -Path "$nodeName.xml" -Force
        }
    }
}