<#

https://superuser.com/questions/140899/ffmpeg-splitting-mp4-with-same-quality

If you want to just split the video without re-ecoding it, use the copy codec for audio and video. Try this:

ffmpeg -ss 00:00:00 -t 00:50:00 -i largefile.mp4 -acodec copy \
-vcodec copy smallfile.mp4
Note that this only creates the first split. The next one can be done with a command starting with ffmpeg -ss 00:50:00.

This can be done with a single command:

ffmpeg -i largefile.mp4 -t 00:50:00 -c copy smallfile1.mp4 -ss 00:50:00 -c copy smallfile2.mp4
This will create smallfile1.mp4, ending at 50 minutes into the video of largefile.mp4, and smallfile2.mp4, starting at 50 minutes in and ending at the end of largefile.mp4.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({If(Test-Path $_) {$true} Else { Throw "'$_' does not exist."}})]
    [String] $Path
)

BEGIN {
    $ffmpeg = "c:\Projects\media\convert\ffmpeg\ffmpeg-20180317-86c7d8d-win64-static\bin\ffmpeg.exe"
}

PROCESS {
    $items = Get-ChildItem -Path $Path -File -Filter "*.mov"
    foreach ($item in $items) {         
        $path = $item | select -ExpandProperty FullName
        $directory = $item.DirectoryName
        $fileName = $item.BaseName
        $extension = $item.Extension

        $fileName = "$fileName-01$extension"
        $dst = [System.IO.Path]::Combine($directory, $fileName)
        $expression = "$ffmpeg -i $path -acodec copy -vcodec copy -ss 00:00:00 $dst"
        # '-c copy' - is shorcut for '-acoded copy -vcodec copy'
        # $expression = "$ffmpeg -i $path -c copy -ss 00:00:00 $dst"
        Write-Host $expression
        Invoke-Expression $expression
    }
    
}