<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK 
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$True)]
	[ValidateSet('Install','Uninstall')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}
	
	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'Microsoft'
	[string]$appName = 'Visio'
	[string]$appVersion = '[ALL]'
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '29/06/2016'
	[string]$appScriptAuthor = 'Aldin T.'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = 'Microsoft Visio Uninstall'
	[string]$installTitle = 'Microsoft Visio Uninstall'
	
	##* Do not modify section below
	#region DoNotModify
	
	## Variables: Exit Code
	[int32]$mainExitCode = 0
	
	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.6.8'
	[string]$deployAppScriptDate = '02/06/2016'
	[hashtable]$deployAppScriptParameters = $psBoundParameters
	
	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent
	
	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}
	
	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================
		
	If ($deploymentType -ine 'Uninstall') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
		
		## Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
		
		## Show Progress Message (with the default message)
		Show-InstallationProgress
		
		## <Perform Pre-Installation tasks here>
		
		
		##*===============================================
		##* INSTALLATION 
		##*===============================================
		[string]$installPhase = 'Installation'
		
		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}
		
		## <Perform Installation tasks here>
		
		
		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
		
		## <Perform Post-Installation tasks here>
		
		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
		## Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'WINPROJ' -Silent
		
<#
VisStd
VisPro
Visio
#>


        #Check installed version
        $VisPro2016 = Get-InstalledApplication -Name "Visio"
        Write-Host $VisPro2016
        $VisStd2003 = (Get-InstalledApplication -Name "Microsoft Office Visio Standard 2003" -Exact).ProductCode
        $VisPro2003 = (Get-InstalledApplication -Name "Microsoft Office Visio Professional 2003" -Exact).ProductCode
        $VisStd2007 = Get-InstalledApplication -Name "Microsoft Office Visio Standard 2007" -Exact | where {$_.UninstallSubkey -eq "VISSTD"}
        $VisPro2007 = Get-InstalledApplication -Name "Microsoft Office Visio Professional 2007" -Exact | where {$_.UninstallSubkey -eq "VISPRO"}
        $VisStd2010 = Get-InstalledApplication -Name "Microsoft Visio Standard 2010" -Exact | where {$_.UninstallSubkey -eq "Office14.VISIO"}
        $VisPro2010 = Get-InstalledApplication -Name "Microsoft Visio Professional 2010" -Exact | where {$_.UninstallSubkey -eq "Office14.VISIO"}
        $VisPrem2010 = Get-InstalledApplication -Name "Microsoft Visio Premium 2010" -Exact | where {$_.UninstallSubkey -eq "Office14.VISIO"}
        $VisStd2013 = Get-InstalledApplication -Name "Microsoft Visio Standard 2013" -Exact | where {$_.UninstallSubkey -eq "Office15.VISSTD"}
        $VisPro2013 = Get-InstalledApplication -Name "Microsoft Visio Professional 2013" -Exact | where {$_.UninstallSubkey -eq "Office15.VISPRO"}
        $VisStd2016 = Get-InstalledApplication -Name "Microsoft Visio Standard 2016" -Exact | where {$_.UninstallSubkey -eq "Office16.VISSTD"}
        $VisPro2016 = Get-InstalledApplication -Name "Microsoft Visio Professional 2016" -Exact | where {$_.UninstallSubkey -eq "Office16.VISPRO"}
        
        
        

        #Create XML file depending on installed version
        If ($VisStd2007 -or $VisStd2013 -or $VisStd2016) {

        #Create XML file for Project Standard:
        New-Item -Path "$env:TEMP\" -Name VisStdSilentUninstallConfig.xml -ItemType "file" -Force -Value `
'<Configuration Product="VisStd">
    <Logging Type="standard" Path="C:\LogFiles" Template="Microsoft Office Visio Uninstal.txt" />
    <Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
    <Setting Id="SETUP_REBOOT" Value="NEVER" />
</Configuration>
'
        #Construct config XML path
        $ConfigXML_Std = '"' + "$env:TEMP" + "\VisStdSilentUninstallConfig.xml" + '"'
        }

        If ($VisPro2007 -or $VisPro2013 -or $VisPro2016) {

        #Create XML file for Project Professional:
        New-Item -Path "$env:TEMP\" -Name VisProSilentUninstallConfig.xml -ItemType "file" -Force -Value `
'<Configuration Product="VisPro">
    <Logging Type="standard" Path="C:\LogFiles" Template="Microsoft Office Visio Uninstal.txt" />
    <Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
    <Setting Id="SETUP_REBOOT" Value="NEVER" />
</Configuration>
'
        #Construct config XML path
        $ConfigXML_Pro = '"' + "$env:TEMP" + "\VisProSilentUninstallConfig.xml" + '"'
        }

        If ($VisPro2010 -or $VisStd2010 -or $VisPrem2010) {

        #Create XML file for Project Professional:
        New-Item -Path "$env:TEMP\" -Name Visio2010SilentUninstallConfig.xml -ItemType "file" -Force -Value `
'<Configuration Product="Visio">
    <Logging Type="standard" Path="C:\LogFiles" Template="Microsoft Office Visio Uninstal.txt" />
    <Display Level="none" CompletionNotice="no" SuppressModal="yes" AcceptEula="yes" />
    <Setting Id="SETUP_REBOOT" Value="NEVER" />
</Configuration>
'

        #Construct config XML path
        $ConfigXML_2010 = '"' + "$env:TEMP" + "\Visio2010SilentUninstallConfig.xml" + '"'
        }

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'
		
		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		
        #Visio 2003
        If ($VisStd2003){
            $PrKey = $VisStd2003.trim()
            Execute-MSI -Action 'Uninstall' -Path $PrKey
            }
        If ($VisPro2003){
            $PrKey = $VisPro2003.trim()
            Execute-MSI -Action 'Uninstall' -Path $PrKey
            }

        #Visio 2007
        If ($VisStd2007){
            $setup_exe = ($VisStd2007.UninstallString -split ('"'))[1]
            $params = (($VisStd2007.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Std"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        If ($VisPro2007){
            $setup_exe = ($VisPro2007.UninstallString -split ('"'))[1]
            $params = (($VisPro2007.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Pro"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        #Visio 2010
        If ($VisStd2010){
            $setup_exe = ($VisStd2010.UninstallString -split ('"'))[1]
            $params = (($VisStd2010.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_2010"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        If ($VisPro2010){
            $setup_exe = ($VisPro2010.UninstallString -split ('"'))[1]
            $params = (($VisPro2010.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_2010"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        If ($VisPrem2010){
            $setup_exe = ($VisPrem2010.UninstallString -split ('"'))[1]
            $params = (($VisPrem2010.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_2010"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        #Visio 2013
        If ($VisStd2013){
            $setup_exe = ($VisStd2013.UninstallString -split ('"'))[1]
            $params = (($VisStd2013.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Std"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        If ($VisPro2013){
            $setup_exe = ($VisPro2013.UninstallString -split ('"'))[1]
            $params = (($VisPro2013.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Pro"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        #Visio 2016
        If ($VisStd2016){
            $setup_exe = ($VisStd2016.UninstallString -split ('"'))[1]
            $params = (($VisStd2016.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Std"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

        If ($VisPro2016){
            $setup_exe = ($VisPro2016.UninstallString -split ('"'))[1]
            $params = (($VisPro2016.UninstallString -split ('"'))[2]).trim() + " /config $ConfigXML_Pro"

            Execute-Process -Path "$setup_exe" -Parameters "$params"
        }

		
		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'
		
        # remove temp files for goor housekeeping
		if ((Test-Path -Path "$env:TEMP\Visio2010SilentUninstallConfig.xml") -eq $True ){Remove-File -Path "$env:TEMP\Visio2010SilentUninstallConfig.xml"}
        if ((Test-Path -Path "$env:TEMP\VisProSilentUninstallConfig.xml") -eq $True ){Remove-File -Path "$env:TEMP\VisProSilentUninstallConfig.xml"}
        if ((Test-Path -Path "$env:TEMP\VisStdSilentUninstallConfig.xml") -eq $True ){Remove-File -Path "$env:TEMP\VisStdSilentUninstallConfig.xml"}
		
	}
	
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================
	
	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}