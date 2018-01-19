[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$processName
)

function Get-ProcessTreeRecursively($process) {
    $result = @()
    $result += $process
    
    $filter = { $_.ParentProcessId -eq $process.ProcessId }
    Get-WmiObject Win32_Process | ? $filter | %{ $result += Get-ProcessTreeRecursively $_ }    
    return $result
}

$filter = { $_.Name -eq $processName}
Get-WmiObject Win32_Process | ? $filter | %{ Get-ProcessTreeRecursively $_ }
