[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({If(Test-Path $_) {$true} Else { Throw "'$_' does not exist."}})]
    [String] $Path,

    [Parameter(Mandatory=$false, Position=2)]
    [ValidateScript({ 
        [ref]$dt = Get-Date;
        [String[]]$dateTimeFormats = @(
            "dd.MM.yyyy HH:mm",
            "dd.MM.yyyy h:mm",
            "dd.MM.yyyy")
        $result = [DateTime]::TryParseExact(
            $_, 
            $dateTimeFormats, 
            [System.Globalization.CultureInfo]::InvariantCulture, 
            [System.Globalization.DateTimeStyles]::None, 
            $dt);
        write-Host $_
        If($result) { 
            $true
        } 
        else {
            throw "`n'$_' can't be converted to date time.`nknown formats: '$dateTimeFormats'"
        }
    })]
    [string] $FallbackDateTime,

    [Parameter(Mandatory=$false, Position=3)]
    [switch]$UseCreatedDateTime
)

BEGIN {

    . $PSScriptRoot\Get-DateTimeTaken.ps1
}

PROCESS {

    $items = Get-ChildItem -Path $Path -File -Recurse
    $errorHash = @{}
    foreach($item in $items) {
        $path = $item | select -ExpandProperty FullName
        Write-Host " "
        Write-Host "FILE: " $Path
        try {
                                
            $receiver = [DateTimeReceiver]::new($FallbackDateTime, $UseCreatedDateTime.IsPresent);
            
            $dateTime = $receiver.GetDateTimeTaken($Path);
            $item.CreationTime = $dateTime
            $item.LastWriteTime = $dateTime
            $item.LastAccessTime  = $dateTime

            Write-Host "DONE dateTime:  " $dateTime
        } catch {
            $errorHash += @{($Path) = $_.Exception.Message }
        }    
    }
    Write-Host "Errors count: " $errorHash.Count
    $errorHash.GetEnumerator() | select -ExpandProperty Name
    
}
