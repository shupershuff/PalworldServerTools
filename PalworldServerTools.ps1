<#
Author: Shupershuff
Version: See Variable below. See GitHub for latest version.
Usage:
	Happy for you to make any modifications this script for your own needs providing:
	- Any variants of this script are never sold.
	- Any variants of this script published online should always be open source.
	- Any variants of this script are never modifed to enable or assist in any malicious behaviour including (but not limited to): Bannable Mods, Cheats, Exploits, Phishing
Purpose:
	Script will allow you to launch the server with parameters.
	Script Will allow you to Retrieve RCON data or send Server commands via RCON.
	See GitHub for full write up.
Instructions: See GitHub readme https://github.com/shupershuff/PalworldServerTools

Notes:

To Do:
- CLI Front End

Changes since 1.0.0 (next version edits):

#>
param(
	[switch]$Info,[switch]$Version,[switch]$ServerName,[switch]$ShowPlayers,[switch]$ShowPlayerCount,[switch]$Shutdown,[int]$ShutdownTimer,$ShutdownMessage,[string]$Broadcast,[switch]$DoExit,[switch]$Save,
	$ServerPath,$ThemeSettingsPath,$LaunchParameters,$HostIP,$RCONPort,$RCONPass,[switch]$UpdateOnly,[switch]$UpdateCheck,[switch]$NoUpdate,[switch]$Start,[switch]$StartThemed,[switch]$TodaysTheme,[Switch]$NoLogging
)
$ScriptVersion = "1.0.0"
##########################################################################################################
# Script Functions
##########################################################################################################
$ScriptFileName = Split-Path $MyInvocation.MyCommand.Path -Leaf
$WorkingDirectory = ((Get-ChildItem -Path $PSScriptRoot)[0].fullname).substring(0,((Get-ChildItem -Path $PSScriptRoot)[0].fullname).lastindexof('\')) #Set Current Directory path.
#Baseline of acceptable characters for ReadKey functions. Used to prevents receiving inputs from folk who are alt tabbing etc.
$Script:AllowedKeyList = @(48,49,50,51,52,53,54,55,56,57) #0 to 9
$Script:AllowedKeyList += @(48,49,50,51,52,53,54,55,56,57) #0 to 9 on numpad
$Script:AllowedKeyList += @(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90) # A to Z
$EnterKey = 13
$Script:X = [char]0x1b #escape character for ANSI text colors
Function Green {#Used for outputting green scucess text
    process { Write-Host $_ -ForegroundColor Green }
}
Function Yellow {#Used for outputting yellow warning text
    process { Write-Host $_ -ForegroundColor Yellow }
}
Function Red {#Used for outputting red error text
    process { Write-Host $_ -ForegroundColor Red }
}
Function Write-Log {
	#Determine what kind of text is being written and output to log and console.
	Param ([string]$LogString,
		   [switch]$Info, #Standard messages.
		   [switch]$Verbose, #Only enters into log if $VerbosePreference is set to continue (Default is silentlycontinue). For Debug purposes only.
		   [switch]$Errorlog, #Can't use $Error as this is a built in PowerShell variable to recall last error. #Red coloured output text in console and sets log message type to [ERROR]
		   [switch]$Warning, #Cheese coloured output text in console and sets log message type to [WARNING]
		   [switch]$Success, #Green output text in console and sets log message type to [SUCCESS]
		   [switch]$NewLine, #used to enter in additional lines without redundantly entering in datetime and message type. Useful for longer messages.
		   [switch]$NoNewLine, #used to enter in text without creating another line. Useful for text you want added succinctly to log but not outputted to console
		   [switch]$NoConsole) #Write to log but not to Console
	$Script:LogFile = ($WorkingDirectory + "\" + $ScriptFileName.replace(".ps1","_")  + (("{0:yyyy/MM/dd}" -f (get-date)) -replace "/",".") +"log.txt")
    #$Script:LogFile = "C:\Palworld Server\Log.txt" #For testing
	if ((Test-Path $LogFile) -ne $true){
		Add-content $LogFile -value "" #Create empty Logfile
	}
	if (!(($Info,$Verbose,$Errorlog,$Warning,$Success) -eq $True)) {
		$Info = $True #If no parameter has been specified, Set the Default log entry to type: Info
	}
    $DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
	If ($CheckedLogFile -ne $True){
		$fileContent = Get-Content -Path $Script:LogFile
		if ($fileContent[2] -match '\[(\d{2}/\d{2}/\d{2} \d{2}:\d{2}:\d{2})\]') {#look at 3rd line of log file and match the date patern.
			$firstDate = [datetime]::ParseExact($matches[1], 'dd/MM/yy HH:mm:ss', $null) #convert matched date string to variable
			$IsTodaysLogFile = ($firstDate.Date -eq (Get-Date).Date) #compare match against todays date
		}
		if ($IsTodaysLogFile -eq $False){
			Rename-Item $Script:LogFile ($WorkingDirectory + "\" + $ScriptFileName.replace(".ps1","_") + (("{0:yyyy/MM/dd}" -f $firstDate) -replace "/",".") + "_log.txt")
			Write-Verbose "Archived Log file."
		}
		#Check if there's more than 3 logfiles with a date and if so delete the oldest one
		$logFiles = Get-ChildItem -Path $WorkingDirectory -Filter "*.txt" | Where-Object { $_.Name -match '\d{2}\.\d{2}\.\d{2}_log.txt' }
		$logFilesToKeep = $logFiles | Sort-Object name -Descending | Select-Object -First 3 #sorting by Name rather than LastWriteTime in case someone looks back and edits it.
		$logFilesToDelete = $logFiles | Where-Object { $_ -notin $logFilesToKeep }
		foreach ($fileToDelete in $logFilesToDelete) {# Delete log files that exceed the latest three
			Remove-Item -Path $fileToDelete.FullName -Force
			Write-Verbose ("Deleted " + $fileToDelete.FullName)
		}
		$Script:CheckedLogFile = $True
	}
	if ($True -eq $Info) {
		$LogMessage = "$Datetime [INFO]    - $LogString"
		if ($False -eq $NoConsole){
			write-output $LogString
		}
	}
	if ($True -eq $Verbose) {
		if ($VerbosePreference -eq "Continue") {
			$LogMessage = "$Datetime [VERBOSE] - $LogString"
			if ($False -eq $NoConsole){
				write-output $LogString
			}
		}
	}
	if ($True -eq $Errorlog) {
		$LogMessage = "$Datetime [ERROR]   - $LogString"
		if ($False -eq $NoConsole){
			write-output $LogString | Red
		}
	}
	if ($True -eq $Warning) {
		$LogMessage = "$Datetime [WARNING] - $LogString"
		if ($False -eq $NoConsole){
			write-output $LogString | Yellow
		}
	}
	if ($True -eq $Success) {
		$LogMessage = "$Datetime [SUCCESS] - $LogString"
		if ($False -eq $NoConsole){
			write-output $LogString | Green
		}
	}
	if ($True -eq $NewLine){#Overwrite $LogMessage to remove headers if -newline is enabled
		$LogMessage = "                                $LogString"
	}
	if ($True -eq $NoNewLine -and $NoLogging -eq $False){#Overwrite $LogMessage to put text immediately after last line if -nonewline is enabled
		$LogContent = (Get-Content -Path $LogFile -Raw) # Read the content of the file
		if ($logcontent -match ' \r?\n\r?\n$' -or $logcontent -match ' \r?\n$' -or $logcontent -match ' \r?\n$' -or $logcontent[-1] -eq " "){#if the last characters in the file is a space a space with one or two line breaks
			$Space = " "
		}
		$LogContent = $LogContent.trim()
		$words = $LogContent -split '\s+' # Split the content into words
		$lastWord = $words[-1] # Get the last word
		$lastWordPosition = $LogContent.LastIndexOf($lastWord) # Find the last occurrence of the last word in the content
		$LogMessage = $lastWord + $Space + $LogString #"$lastLine$LogString"
		$newContent = $LogContent.Substring(0, $lastWordPosition) + $LogMessage + $LogContent.Substring($lastWordPosition + $lastWord.Length) # Replace the last occurrence of the last word in the content
		$newContent | Set-Content -Path $LogFile # Write the modified content back to the file
	}
	try {
		if ($NoLogging -eq $False -and $NoNewLine -eq $False){ #if user has disabled logging, eg on sensors that check every minute or so, they may want logging disabled.
			Add-content $LogFile -value $LogMessage -ErrorAction Stop
		}
	}
	Catch {
		write-output "Unable write to $LogFile. Check permissions on this folder" | Red
		pause
		exit 1
	}
}
Function ReadKey([string]$message=$Null,[bool]$NoOutput,[bool]$AllowAllKeys) {#used to receive user input
    $key = $Null
    $Host.UI.RawUI.FlushInputBuffer()
    if (![string]::IsNullOrEmpty($message)) {
        Write-Host -NoNewLine $message
    }
	$AllowedKeyList = $Script:AllowedKeyList + @(13,27) #Add Enter & Escape to the allowedkeylist as acceptable inputs.
    while ($Null -eq $key) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $key_ = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
            if ($True -ne $AllowAllKeys){
				if ($key_.KeyDown -and $key_.VirtualKeyCode -in $AllowedKeyList) {
					$key = $key_
				}
			}
			else {
				if ($key_.KeyDown) {
					$key = $key_
				}
			}
        }
		else {
            Start-Sleep -m 200  # Milliseconds
        }
    }
	if ($key_.VirtualKeyCode -ne $EnterKey -and -not ($Null -eq $key) -and [bool]$NoOutput -ne $true) {
        Write-Host ("$X[38;2;255;165;000;22m" + "$($key.Character)" + "$X[0m") -NoNewLine
    }
    if (![string]::IsNullOrEmpty($message)) {
        Write-Host "" # newline
    }
    return $(
        if ($Null -eq $key -or $key.VirtualKeyCode -eq $EnterKey) {
            ""
        } else {
            $key.Character
        }
    )
}
Function PressTheAnyKeyToExit {#Used instead of Pause so folk can hit any key to exit
	write-host "  Press Any key to exit..." -nonewline
	readkey -NoOutput $True -AllowAllKeys $True | out-null
	write-log -info -noconsole "Script Exited"
	Exit
}
Function NoGUIExit {#Used to write to log prior to exit
	write-log -info -noconsole "Script Exited."
	Exit
}
Function ExitCheck {
	if ($null -eq $usedParameters){
		PressTheAnyKeyToExit
	}
	Else {
		NoGUIExit
	}
}
Function UpdateCheck {
	# Credit: Some logic pinched from https://superuser.com/questions/1727148/check-if-steam-game-requires-an-update-via-command-line
	$AppInfoFile = "$WorkingDirectory\PalServerBuildID.txt"
	write-log -info -noconsole "Update Check: " 
	Write-log -info -noconsole -nonewline "Checking Updates for App ID 2394010"
	try {
		$AppInfoNew = (Invoke-RestMethod -Uri "https://api.steamcmd.net/v1/info/2394010").data.'2394010'.depots.branches.public.buildid
	} 
	catch {
		write-log -errorlog -noconsole "Update Check: " 
		Write-log -errorlog -noconsole -nonewline "Update Check: Error getting app info for game"
		Pause
		Exit 1
	}
	$NeedsUpdate = $true
	if (Test-Path $AppInfoFile) {
		write-log -verbose "Update Check: File PalServerBuildID.txt exists."
		$AppInfo = Get-Content $AppInfoFile
		$NeedsUpdate = $AppInfo -ne $AppInfoNew
	}	
	else {#if file doesn't exist, force update and export file.
		Update
		$AppInfoNew | Out-File $AppInfoFile -Force
		$NeedsUpdate = $False
		Write-Log -Success -noconsole "Update Check: "
		Write-Log -Success -nonewline "Updated!"
		return
	}
	if ($NeedsUpdate) {
		Write-Log -Info -noconsole "Update Check: "
		Write-Log -Info -nonewline "Update Available!"
		if ($False -eq $UpdateCheck){
			Update -silent
			$AppInfoNew | Out-File $AppInfoFile -Force #overwrite file with build ID
			Write-Log -Success -noconsole "Update Check: "
			Write-Log -success -nonewline "Update Complete!"
		}
	}	
	else {
		Write-Log -Success -noconsole "Update Check: "
		Write-Log -Success -nonewline "Version up-to-date"
	}
}

Function Update {
	param([switch]$Silent)
	try {
		Write-Log -info -noconsole "Update: "
		Write-Log -info -nonewline "Updating..."
		if ($silent){
			cmd /c "$($Config.SteamCMDPath)\steamcmd.exe +login anonymous +force_install_dir $ServerPath +app_update 2394010 validate +quit"
		}
		Else {
			cmd /c "$($Config.SteamCMDPath)\steamcmd.exe +login anonymous +force_install_dir $ServerPath +app_update 2394010 validate +quit" | out-null
		}
		Write-Log -success -noconsole "Update: "
		Write-Log -success -nonewline "Updated!"
	}
	Catch {
		Write-Log -errorlog -noconsole "Update: "
		Write-Log -errorlog -nonewline "Couldn't Update :("
	}
}
Function LaunchServer {
	if ($Running -eq $True){
		& ($Script:WorkingDirectory + "\" + $Script:ScriptFileName) -shutdown $Config.AutoShutdownTimer $Config.AutoShutdownMessage
		$Delay = 6 #add a few seconds as a buffer to allow server to shutdown.
		write-log -info -noconsole "LaunchServer: "
		write-log -info -nonewline ("Waiting " + ([int]$Config.AutoShutdownTimer + [int]$Delay) + " seconds for server to shutdown...")
		start-sleep ([int]$Config.AutoShutdownTimer + $Delay)
		write-log -verbose ("LaunchServer: Waited " + ([int]$Config.AutoShutdownTimer + [int]$Delay) + " seconds for server to shutdown.")
		if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){#if palserver is STILL running, force closure.
			Write-Log -warning -noconsole "LaunchServer: "
			write-log -warning -nonewline "Force killing server processes..."
			taskkill /F /IM PalServer.exe | out-null
			taskkill /F /IM PalServer-Win64-Test-Cmd.exe | out-null
		}	
	}
	if ($False -eq $UpdateOnly) {
		if (-not $Config.NormalSettingsName.EndsWith(".ini")){#add .ini to value if it wasn't specified in config.
			$Config.NormalSettingsName = $Config.NormalSettingsName + ".ini"
		}
		$Config.NormalSettingsName = $Config.NormalSettingsName.tostring()
		if ((Test-Path -Path ($ThemeSettingsPath + $Config.NormalSettingsName)) -ne $true){#if file doesn't exist
				Write-Log -warning -noconsole "LaunchServer: "
				write-log -warning -nonewline ($Config.NormalSettingsName + " doesn't exist, copying current config to $ThemeSettingsPath" + $Config.NormalSettingsName)
				Copy-Item "$ServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini" "$ThemeSettingsPath$($Config.NormalSettingsName)" #$ServerPath\Pal\Saved\Config\WindowsServer\CustomSettings\
		}
		if ($True -ne $Start){
			Write-Log -info -noconsole "LaunchServer: "
			write-log -info -nonewline "Starting Palworld Server with Theme Config"
			$iniFiles = Get-ChildItem -Path $ThemeSettingsPath -Filter *.ini
			$Script:AllConfigOptions = @{}
			foreach ($file in $iniFiles) {
				$Script:AllConfigOptions[($file.Name).replace(".txt","")] = $file.FullName
			}
			$currentDay = (Get-Date -Format "dddd") #;$currentday = (Get-Date).AddDays(-3).ToString("dddd") #for testing theme on previous days
			
			#Validation
			$daysOfWeek = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")
			foreach ($day in $daysOfWeek) {
				$IniName = $Config.$day
				if ($Script:AllConfigOptions.ContainsKey("$IniName.ini")) {
					write-log -success -noconsole "LaunchServer: "
					write-log -success -nonewline "The filename for $Day is correct."
				}
				Else {
					write-log -errorlog -noconsole "LaunchServer: "
					write-log -errorlog -nonewline "The filename for $Day is incorrect as it doesn't match config in the xml." 
					write-log -errorlog -newline ("Either edit the config or ensure there's a file called " + $IniName + ".ini") 
					write-host
					$ErrorCount ++
				}
			}
			if ($ErrorCount -ge 1){
				$Plural = "these"
				if ($ErrorCount -eq 1){
					$Plural = "this"
				}
				write-log -errorlog -newline "Correct $Plural and rerun the script. Script will now exit."
				ExitCheck
			}
			$SettingsActual = ($ServerPath +"\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")
			$AllConfigOptionsObject = @()
			# Adding key-value pairs to the variable
			foreach ($key in $Script:AllConfigOptions.Keys) {
				$value = $AllConfigOptions[$key]
				$entry = [PSCustomObject]@{
					Name  = $key
					Value = $value
				}
				$AllConfigOptionsObject += $entry
			}
			$GameSettings = $AllConfigOptionsObject | where-object {$_.Name -match $Config.$currentday}
			$TodaysTheme = $GameSettings.Name.replace("_"," ").replace(".ini","")
			$TodaysTheme | Out-File -FilePath "$WorkingDirectory\TodaysTheme.txt"
			Copy-Item $GameSettings.Value $SettingsActual
			Write-log -success -noconsole "LaunchServer: "
			Write-log -success -nonewline ("Copied `"" + $TodaysTheme + "`" Settings to PalWorldSettings.ini")
		}
		Else {
			Copy-Item ($ThemeSettingsPath + $Config.NormalSettingsName) ($Script:ServerPath + "\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")
			Write-log -success -noconsole "LaunchServer: "
			Write-log -success -nonewline "Copied $($Config.NormalSettingsName) to PalWorldSettings.ini"
		}
		If ($True -eq $Config.CommunityServer){
			Write-log -verbose "LaunchServer: Community is enabled."
			$Community = "EpicApp=PalServer"
		}
		Else {
			$Community = ""
		}

		if ($Null -eq $LaunchParameters -or $LaunchParameters -eq ""){
			Write-log -verbose "LaunchServer: Standard Launch Parameters used"
			$LaunchParameters = "$Community -log -publicip=$PublicIP -publicport=$GamePort -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
		}
		Start-Process ($Script:ServerPath + "\PalServer.exe") $LaunchParameters
		Write-Host
		Write-Log -success "Server Started. Exiting..."
		ExitCheck
	}
}

Function RCON {#Pull server data or issue commands via the ARRCON client
	Write-log -info -noconsole "RCON: Starting RCON Function"
	if ($Running -ne $True){
		Write-log -errorlog -noconsole "RCON: Server is offline, RCON function cancelled."
		Write-Output "Server Offline" | Red
		return
	}
	If ($True -eq $Info -or $True -eq $Version -or $ServerName -eq $True){#not overly useful if you run one server, useful if you run multiple
		try {
			write-log -info -noconsole "RCON: Getting info data..."
			$InfoText = & ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass info
			$InfoText = $InfoText[1]
			if ($True -eq $ServerName){
				$pattern = 'Pal Server\[v\d+\.\d+\.\d+\.\d+\] (.+)' #response is "Welcome to Pal Server[v0.1.2.0] SERVER NAME. Filter out the preamble so only SERVER NAME is returned.
				if ($InfoText -match $pattern) {
					$ServerNameText = $matches[1]
				}
				$ServerNameText
			}
			if ($Info -eq $True ){
				$InfoText
			}
			if ($True -eq $Version){
				$pattern = '\[v(\d+(\.\d+)+)\]' # Define the regular expression pattern to match the version number
				# Use the -match operator to find the match in the string
				if ($InfoText -match $pattern) {
					$versionNumber = "v" + $matches[1] # The matched version number will be in the $matches variable
					$versionNumber
				}
				else {
					write-log -errorlog -noconsole "RCON: "
					Write-Log -errorlog -nonewline "No version number found"
				}
			}	
			write-log -info -noconsole "RCON: Info data retreived."
		}
		Catch {
			write-log -errorlog -noconsole "RCON: Couldn't pull ServerName"
			write-output "Couldn't retrieve Server Name" | Red
		}
		start-sleep -milliseconds 125
	}
	If ($True -eq $ShowPlayers -or $True -eq $ShowPlayerCount){
		start-sleep -milliseconds 225
		Try {
			write-log -info -noconsole "RCON: Getting showplayers data..."
			$PlayersOnline = & ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass showplayers
			$PlayersOnlineCount = $PlayersOnline.count -3
			$PlayersOnlineNames = $PlayersOnline[2..($PlayersOnline.Count - 2)] -replace ',.*', ''
			if ($True -eq $ShowPlayerCount){
				$PlayersOnlineCount
			}
			if ($True -eq $ShowPlayers){
				if ($PlayersOnlineCount -eq 0){
					$PlayersOnlineNames = $null
					$PlayersOnlineNames
				}
				else {
					$PlayerNamesCommaSeparated = ($PlayersOnlineNames -split "`n" | ForEach-Object { $_.Trim() }) -join ', '
					$PlayerNamesCommaSeparated
				}
			}
			write-log -success -noconsole "RCON: Showplayers data retreived"
		}
		Catch {
			write-log "RCON: "
			write-log -errorlog -nonewline "Couldn't retrieve Player data"
		}	
	}
	If ($True -eq $Save){
		write-log -success -noconsole "RCON: "
		write-log -info -nonewling "Saving..."
		Do {
			$SaveAttempts ++
			$SaveStatus = & ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass Save
		} Until ($SaveStatus -eq "Complete Save" -or $SaveAttempts -eq 3)
		if ($SaveStatus -eq "Complete Save"){
			write-log -success -noconsole "RCON: Save Successful."
			write-log -success "Saved!"
		}
	}
	If ($Shutdown -eq $True){
		if ($ShutdownTimer -eq "" -or $Null -eq $ShutdownTimer -or $ShutdownTimer -lt 1){#if Shutdown timer isn't specified.
			$ShutdownTimer = $Config.AutoShutdownTimer
		}
		if ($Null -eq $ShutdownMessage){#if Shutdown message isn't specified.
			$ShutdownMessage = ("Admin_is_shutting_down_server_in_" + $ShutdownTimer + "_Seconds.")
		}
		write-log -warning -noconsole "RCON: "
		write-log -warning -nonewline "Shutting down in $ShutdownTimer seconds."
		& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "Shutdown $ShutdownTimer $ShutdownMessage"
		if ("" -eq $Broadcast -or $Null -eq $Broadcast){#if Broadcast hasn't already been specified as a launch parameter.
			$Broadcast = "Shutting_down_server_now"
		}
	}
	If ("" -ne $Broadcast){
		if ($Shutdown -eq $True){
			start-sleep ($ShutdownTimer -5)
			if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){#check if palserver is still running in case it was manually closed earlier than expected
				write-log -info -noconsole "RCON: "
				write-log -info -nonewline "Broadcasting shutdown message: $Broadcast"
				& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "Broadcast $Broadcast"
			}
		}
		Else {
			write-log -info -noconsole "RCON: "
			write-log -info -nonewline "Broadcasting: $Broadcast"
			& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "Broadcast $Broadcast"
		}
	}
	If ($True -eq $DoExit){
		write-log -warning -noconsole "RCON: "
		write-log -warning -nonewline "Shutting down now..." -foregroundcolor cyan
		& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass DoExit
	}
}

##########################################################################################################
# Config Import, Validation and Variable Setup.
##########################################################################################################
Function ImportXML {
	try {
		Write-log -info -noconsole "Initialisation: Attempting to import config.xml" 
		$Script:Config = ([xml](Get-Content "$Script:WorkingDirectory\Config.xml" -ErrorAction Stop)).PalworldServerToolsConfig
		Write-log -info -noconsole "Initialisation: Config imported successfully."
	}
	Catch {
		Write-Host ""
		Write-log -errorlog -noconsole "Initialisation: "
		Write-log -errorlog -nonewline "Config.xml Was not able to be imported. This could be due to a typo or a special character such as `'&`' being incorrectly used."
		Write-log -errorlog -newline "The error message below will show which line in the clientconfig.xml is invalid:"
		Write-log -errorlog -newline (" " + $PSitem.exception.message)
		Write-Host ""
		ExitCheck
	}
}
Write-log -newline -noconsole #Add a linebreak in the log in between instances.
Write-log -info -noconsole "Initialisation: Script Started."
ImportXML
foreach($boundparam in $PSBoundParameters.GetEnumerator()) {
	   write-log -info -noconsole ("Initialisation: Launch Parameter " + $boundparam.Key + " was used.")
	   $usedParameters += $boundparam.Key + "`n"
}
$usedParameters = $usedParameters -replace "`n$", ""
$usedParametersString = ($usedParameters -replace "`n", ", ").TrimEnd(', ')
$RCONParameters = @("Info", "Version", "ServerName", "ShowPlayers", "ShowPlayerCount", "Shutdown", "ShutdownTimer", "ShutdownMessage", "Broadcast", "DoExit", "Save", "RCONPort", "RCONPass")
foreach ($ParameterName in $RCONParameters) {
	$ParameterValue = Get-Variable -Name $ParameterName -ValueOnly
	if (($null -ne $ParameterValue -and $ParameterValue -ne "" -and $ParameterValue -ne $False) -or $ParameterValue -eq $True){
		$RCONParamsUsed = $True
		Write-Log -info -noconsole "Initialisation: RCON Parameter $ParameterName supplied with value: $ParameterValue"
	}
}

If ($Config.SteamCMDPath -match "steamcmd.exe"){$Config.SteamCMDPath = $Config.SteamCMDPath.replace("\steamcmd.exe","")}
Write-log -info -noconsole "Initialisation: Checking if ARRCON.exe can be found."
if ((Test-Path -Path ($Config.ARRCONPath + "\ARRCON.exe")) -ne $true){
	Write-log -errorlog -noconsole "Initialisation: "
	Write-log -errorlog -nonewline "ERROR: Please ensure you have downloaded ARRCON.exe and specified where its folder is in config.xml."
	Write-log -errorlog -nonewline "ARRCON.exe can be downloaded from https://github.com/radj307/ARRCON"
	Pause
	ExitCheck
}
Else {
	Write-log -Success -noconsole "Initialisation: ARRCON was found in the specified path."
}
If ($Null -eq $HostIP){
	$HostIP = $Config.HostIP
	If ($Null -eq $HostIP -or $HostIP -eq ""){#Required value. If value is still empty throw an error and exit.
		Write-log -errorlog -noconsole "Initialisation: "
		write-log -errorlog -nonewline "HostIP is not specified in config.xml"
		Pause
		ExitCheck
	}
}
If ($Null -eq $GamePort){#If Launch Parameter wasn't supplied
	$GamePort = $Config.GamePort #Use Value from config.xml
	If ($Null -eq $GamePort -or $GamePort -eq ""){#Required value. If value is still empty throw an error and exit.
		Write-log -errorlog -noconsole "Initialisation: "
		write-log -errorlog -nonewline "GamePort is not specified in config.xml"
		Pause
		Exit 1
	}
}
If ($Null -eq $RCONPort){#If Launch Parameter wasn't supplied
	$RCONPort = $Config.RCONPort #Use Value from config.xml
	If ($Null -eq $RCONPort -or $RCONPort -eq ""){#Required value. If value is still empty throw an error and exit.
		Write-log -errorlog -noconsole "Initialisation: "
		write-log -errorlog -nonewline "RCONPort is not specified in config.xml"
		Pause
		Exit 1
	}
}
If ($Null -eq $RCONPass){#If Launch Parameter wasn't supplied
	$RCONPass = $Config.RCONPass #Use Value from config.xml
	If ($Null -eq $RCONPass -or $RCONPass -eq ""){#Required value. If value is still empty throw an error and exit.
		Write-log -errorlog -noconsole "Initialisation: "
		write-log -errorlog -nonewline "RCONPass is not specified in config.xml"
		Pause
		Exit 1
	}
}

If ($Null -eq $ServerPath){#If Launch Parameter wasn't supplied
	$ServerPath = $Config.ServerPath #Use Value from config.xml
	if (-not (Test-Path $ServerPath)) { #If path doesn't exist
		if (Test-Path $WorkingDirectory\palserver.exe){#if Server Path wasn't specified, see if palserver is in the same directory the script is running from.
			$ServerPath = $WorkingDirectory #set Current directory as server path.
		}
		Elseif ($RCONParamsUsed -ne $True) { #Unless user is only using this for RCON, shit the bed and close.
			Write-log -errorlog -noconsole "Initialisation: "
			Write-log -errorlog -nonewline "Please provide the Server Path in the config or via a parameter when launching."
			Pause
			Exit 1
		}
	}
}

If ($Null -eq $ThemeSettingsPath){#If Launch Parameter wasn't supplied
	$ThemeSettingsPath = $Config.ThemeSettingsPath #Use Value from config.xml
	If ($Null -eq $ThemeSettingsPath -or "" -eq $ThemeSettingsPath){#if config setting is left blank, use serverpath as the default value.
		$ThemeSettingsPath = "$ServerPath\Pal\Saved\Config\WindowsServer\CustomSettings\" 
	} 
}
if ($ThemeSettingsPath[-1] -ne '\') {$ThemeSettingsPath += "\"} #Append a slash \
if (-not (Test-Path $ThemeSettingsPath)) {#check if the folder has been created for the custom settings path and if not create it.
	Write-log -warning -noconsole "Initialisation: "
	write-log -warning -nonewline "Can't find folder for Custom settings."
	write-log -warning -newline "Creating Folder in $ThemeSettingsPath"
	New-Item -ItemType Directory -Path $ThemeSettingsPath -ErrorAction stop | Out-Null 
}
##########################################################################################################
# Script Logic
##########################################################################################################
if ($null -eq $usedParameters) {#if user runs this script without any parameters
    Write-log -warning -noconsole "Initialisation: "
	Write-log -info -nonewline "No launch parameters provided."
	Write-log -info -newline "A future version with have a CLI based Menu for running basic tasks." 
	Write-log -info -newline "Until then, this is primarily a tool to run in the backend."
	pause
	PressTheAnyKeyToExit
} 
else {
	if (($usedParameters -split "`n").trim.Length -gt 1){$UsedParamPlural = "s"}
    Write-log -info -noconsole "Initialisation: Launch parameter$UsedParamPlural $usedParametersString provided."
}
if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){#if palserver is running
	$Running = $True
}
if ($true -eq $TodaysTheme){
	write-log -info -noconsole "Initialisation: Parameter supplied for TodaysTheme. Checking for Todays Theme"
	Try {
		$TodaysThemeText = Get-content  "$WorkingDirectory\.TodaysTheme.txt"
		write-log -info -noconsole "Initialisation: Todays Theme is $TodaysThemeText"
		$TodaysThemeText
	}
	Catch {
		Write-log -errorlog -noconsole "Initialisation: "
		Write-log -errorlog -nonewline "Couldn't obtain todays theme from '$WorkingDirectory\.TodaysTheme.txt'."
		write-log -errorlog -newline "Check Config.xml is accurate or run the script with -startthemed once to generate .todaystheme.text"
	}	
}
if ($true -eq $UpdateOnly -or $true -eq $UpdateCheck){#if updatecheck param supplied, this doesn't update and only returns a value. Useful for sensors.
	write-log -info -noconsole "Parameter supplied for either updateonly or updatecheck. Checking for updates."
	UpdateCheck
}

if ($true -eq $Start -or $true -eq $StartThemed){
	write-log -info -noconsole "Initialisation: Parameter supplied to start Server."
	if ($true -ne $noUpdate){#update server unless it was specified not to at launch
		write-log -info -noconsole "Initialisation: Checking for updates as part of launch process."
		UpdateCheck
	}
	LaunchServer
}

if ($True -eq $RCONParamsUsed){
	RCON
	ExitCheck
}
