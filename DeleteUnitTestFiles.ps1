$rootDir = "C:\UnitTestResults"
$dirs = Get-ChildItem -Path $rootDir | Where-Object {$_.PSIsContainer}

$count = 0
foreach($dir in $dirs)
{
    Write-Host "Directory " $dir.FullName " found"
    $itemsToDelete = Get-ChildItem -Path $dir.FullName
    foreach($item in $itemsToDelete)
    {
        if ($item.PSIsContainer)
        {
            $item.Delete($true)
        }
        else
        {
            $item.Delete()
        }
        
        $count++
    }
}

Write-Host $count " items were deleted."
