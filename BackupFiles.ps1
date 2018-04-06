# Written by Hayato Iriumi for Pan Pacific Dentistry (4/2/2018)
# hiriumi@gmail.com

$DateTimeNow = Get-Date
$RetentionDays = 120

$BackupRootDir = "F:\test_backup"
$BackupTargetDir = Join-Path -Path $BackupRootDir -ChildPath $DateTimeNow.ToString("yyyy-MM-dd-HH-mm-ss")
$SourceDirs = "C:\test1","C:\test2"
$LogFilePath = Join-Path -Path $BackupTargetDir -ChildPath "log.txt"

Add-Content -Path $LogFilePath -Value "Backing up to $BackupTargetDir..."

If (!(Test-Path -Path $BackupTargetDir))
{
	Add-Content -Path $LogFilePath -Value "Creating a new directory $BackupTargetDir..."
	New-Item -ItemType Directory -Force -Path $BackupTargetDir
}

ForEach ($SourceDir In $SourceDirs)
{
	If (Test-Path -Path $SourceDir)
	{
		Add-Content -Path $LogFilePath -Value "Backing up $SourceDir to $BackupTargetDir..."
		Copy-Item -Path $SourceDir -Filter "*.*" -Recurse -Destination $BackupTargetDir -Container
		Add-Content -Path $LogFilePath -Value "Backed up $SourceDir successfully."
	}
	Else
	{
		Write-Warning "The source directory path `"$SourceDir`" does not exist."
		Add-Content -Path $LogFilePath -Value "The source directory path `"$SourceDir`" does not exist."
	}
}

#Purge the old backups
$AllDirs = Get-ChildItem -Path $BackupRootDir -Directory
ForEach ($Dir In $AllDirs)
{
	$span = [datetime]::Now - $Dir.CreationTime
	If ($span.Days -gt $RetentionDays)
	{
		$Dir.Delete($true)
	}
}

Add-Content -Path $LogFilePath -Value "Backup completed successfully at $([datetime]::Now)"