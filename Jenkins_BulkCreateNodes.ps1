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
    [string]$NodeNamePattern = "winnode-###",
    [Parameter(Mandatory=$False)]
    [int]$NodeCount = 10,
    [Parameter(Mandatory=$False)]
    [string]$Labels = "",
    [Parameter(Mandatory=$False)]
    [string]$Description = "",
    [Parameter(Mandatory=$False)]
    [bool]$GenerateNodeXmlFiles = $True,
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
    $xmlSettings.ConformanceLevel = "Document"

    $sw = New-Object System.IO.StringWriter
    $xw = [System.Xml.XmlWriter]::Create($sw, $xmlSettings)
    
    try 
    {
        $xw.WriteStartElement("slave")
        $xw.WriteElementString("name", $nodeName)

        $xw.WriteEndElement()
        $xw.WriteEndDocument()
        $xw.Flush()
    }
    catch 
    {
        
    }
    finally 
    {
        $xw.Close()
    }

    Write-Host $sw.ToString()

}

#java -version
#$nodeName = "{0:D4}" -f $NodeCount
#Write-HOst $nodeName
#Write-Host $JsonDataPath   
