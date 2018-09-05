$SourceBase = [System.IO.Path]::GetFullPath("$PSScriptRoot\..")

$source = [System.IO.Path]::Combine($SourceBase, "CustomModule\GetProcPSSnapIn01.cs")

$reference = [System.IO.Path]::Combine($SourceBase, "packages\Microsoft.PowerShell.5.ReferenceAssemblies.1.1.0\lib\net4\System.Management.Automation.dll")
$compiler = "$env:windir\Microsoft.NET\Framework\v4.0.30319\csc.exe"
# & $compiler /target:library /r:$reference $source
& $compiler /help