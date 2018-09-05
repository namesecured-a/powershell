[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ProcessName
)

"{0:N2} GB" -f [float]((.\Get-ProcessTree.ps1 $ProcessName | Measure-Object -Property WorkingSetSize -Sum).Sum / 1GB)