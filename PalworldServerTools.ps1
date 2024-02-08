<#
Author: Shupershuff
Version: See $ScriptVersion Variable below. See GitHub for latest version.
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

To Do:
- GUI Front end and/or CLI Front End with a menu
- Auto Update: Add option for this to be called via GUI (Requires GUI/background agent)
- Tidy up for PlayersOnline.txt so it doesn't get massive
- Investigate having most RCON features work when script is run from remote host.

Changes since 1.0.0 (next version edits):
- Implemented Backup feature. See Github readme for explanation.
- Implemented Server Setup feature. See Github readme for explanation.
- Implemented Kick & Ban with username validation (you can enter either playername or steam ID). Also able to ban offline players.
- Breaking Change: Changed Parameter "-StartNoTheme" to "-Start"
- Breaking Change: Changed ShowPlayers to "ShowPlayerNames". ShowPlayers now shows CSV output of online players (standard output by RCON).
- Added parameter for retrieving players in csv without the header (as it's needed by internal functions anyway).
- Improvements to Server Shutdown messaging.
- ARRCON now automatically installs if it's not found.
- SteamCMD now automatically installs if it's not found.
- Fixed various issues with logging and typos
- Fixed updates not working properly for paths with spaces in them.
- Fixed update function not working for directories with spaces in them.
- Fixed the filename outputting incorrectly for "todaystheme.txt" (was .todaystheme.txt"
- Code tidy ups and future proofing.
- Adjustments to config validation and checks.

#>
##########################################################################################################
# Startup Bits
##########################################################################################################
param(
	[switch]$Info,[switch]$Version,[switch]$ServerName,[switch]$ShowPlayers,[switch]$ShowPlayersNoHeader,[switch]$ShowPlayerNames,[switch]$ShowPlayerCount,[switch]$LogPlayers,[switch]$Shutdown,[int]$ShutdownTimer,$ShutdownMessage,[string]$Broadcast,[switch]$DoExit,[switch]$Save,
	[string]$KickPlayer,[string]$BanPlayer,$ServerPath,$ThemeSettingsPath,$LaunchParameters,$HostIP,$RCONPort,$RCONPass,[switch]$UpdateOnly,[switch]$UpdateCheck,[switch]$NoUpdate,[switch]$Start,[switch]$StartThemed,[switch]$TodaysTheme,[Switch]$NoLogging,[switch]$Setup,[Switch]$Backup,[switch]$debug
)
$ScriptVersion = "1.1.0"

if ($debug -eq $True){#courtesy of https://thesurlyadmin.com/2015/10/20/transcript-logging-why-you-should-do-it/
	$KeepLogsFor = 15
	$VerbosePreference = "Continue"
	$LogPath = Split-Path $MyInvocation.MyCommand.Path
	Get-ChildItem "$LogPath\*.log" | Where LastWriteTime -LT (Get-Date).AddDays(-$KeepLogsFor) | Remove-Item -Confirm:$false
	$LogPathName = Join-Path -Path $LogPath -ChildPath "$($MyInvocation.MyCommand.Name)-$(Get-Date -Format 'MM-dd-yyyy').log"
	Start-Transcript $LogPathName -Append
}
$ScriptFileName = Split-Path $MyInvocation.MyCommand.Path -Leaf
$WorkingDirectory = ((Get-ChildItem -Path $PSScriptRoot)[0].fullname).substring(0,((Get-ChildItem -Path $PSScriptRoot)[0].fullname).lastindexof('\')) #Set Current Directory path.
#Baseline of acceptable characters for ReadKey functions. Used to prevents receiving inputs from folk who are alt tabbing etc.
$Script:AllowedKeyList = @(48,49,50,51,52,53,54,55,56,57) #0 to 9
$Script:AllowedKeyList += @(96,97,98,99,100,101,102,103,104,105) #0 to 9 on numpad
$Script:AllowedKeyList += @(65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90) # A to Z
$EnterKey = 13
$Script:X = [char]0x1b #escape character for ANSI text colors
##########################################################################################################
# Script Functions
##########################################################################################################
Function Green {#Used for outputting green scucess text
    process { Write-Host $_ -ForegroundColor Green }
}
Function Yellow {#Used for outputting yellow warning text
    process { Write-Host $_ -ForegroundColor Yellow }
}
Function Red {#Used for outputting red error text
    process { Write-Host $_ -ForegroundColor Red }
}
Function WriteLog {
	#Determine what kind of text is being written and output to log and console.
	#Note: $NoLogging is a script parameter and if true will not output to standard log file. If CustomLogFile param is used, output will continue to be written.
	Param ( [string]$LogString,
			[switch]$Info, #Standard messages.
			[switch]$Verbose, #Only enters into log if $VerbosePreference is set to continue (Default is silentlycontinue). For Debug purposes only.
			[switch]$Errorlog, #Can't use $Error as this is a built in PowerShell variable to recall last error. #Red coloured output text in console and sets log message type to [ERROR]
			[switch]$Warning, #Cheese coloured output text in console and sets log message type to [WARNING]
			[switch]$Success, #Green output text in console and sets log message type to [SUCCESS]
			[switch]$NewLine, #used to enter in additional lines without redundantly entering in datetime and message type. Useful for longer messages.
			[switch]$NoNewLine, #used to enter in text without creating another line. Useful for text you want added succinctly to log but not outputted to console
			[switch]$NoConsole, #Write to log but not to Console
			[string]$CustomLogFile #Explicitly specify the output filename.
	)
	if ($CustomLogFile -eq ""){	
		$Script:LogFile = ($WorkingDirectory + "\" + $ScriptFileName.replace(".ps1","_")  + (("{0:yyyy/MM/dd}" -f (get-date)) -replace "/",".") +"log.txt")
	}
	Else {
		$Script:LogFile = ($WorkingDirectory + "\" + $CustomLogFile)
	} 
	if ((Test-Path $LogFile) -ne $true){
		Add-content $LogFile -value "" #Create empty Logfile
	}
	if (!(($Info,$Verbose,$Errorlog,$Warning,$Success) -eq $True)) {
		$Info = $True #If no parameter has been specified, Set the Default log entry to type: Info
	}
    $DateTime = "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
	If ($CheckedLogFile -ne $True){
		$fileContent = Get-Content -Path $Script:LogFile
		if  ($Null -ne $fileContent){
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
	if (($NoLogging -eq $False -or ($CustomLogFile -ne "" -and $ShowPlayers -eq $True)) -and $NoNewLine -eq $True ){#Overwrite $LogMessage to put text immediately after last line if -nonewline is enabled
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
	while ($Complete -ne $True -or $WriteAttempts -eq 3){
		try {
			if (($NoLogging -eq $False -or ($CustomLogFile -ne "" -and $ShowPlayers -eq $True)) -and $NoNewLine -eq $False ){ #if user has disabled logging, eg on sensors that check every minute or so, they may want logging disabled.
				Add-content $LogFile -value $LogMessage -ErrorAction Stop
				$Complete = $True
			}
			else {
				write-verbose "No Logging specified, didn't write to log."
				$Complete = $True
			}
		}
		Catch {#added this in case log file is being written to too fast and file is still locked when trying from previous write when trying to write new line to it.
			write-verbose "Unable write to $LogFile. Check permissions on this folder"
			$WriteAttempts ++
			start-sleep -milliseconds 5
		}
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
Function ReadKeyTimeout([string]$message=$Null, [int]$timeOutSeconds=0, [string]$Default=$Null) {#used to receive user input but times out after X amount of time
	$key = $Null
    $Host.UI.RawUI.FlushInputBuffer()
    if (![string]::IsNullOrEmpty($message)) {
        Write-Host -NoNewLine $message
    }
    $Counter = $timeOutSeconds * 1000 / 250
    while ($Null -eq $key -and ($timeOutSeconds -eq 0 -or $Counter-- -gt 0)) {
        if (($timeOutSeconds -eq 0) -or $Host.UI.RawUI.KeyAvailable) {
            $key_ = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown,IncludeKeyUp")
            if ($key_.KeyDown -and $key_.VirtualKeyCode -in $AllowedKeyList) {
                $key = $key_
            }
        }
		else {
            Start-Sleep -m 250  # Milliseconds
        }
    }	
    if ($key_.VirtualKeyCode -ne $EnterKey -and -not ($Null -eq $key)) {
        Write-Host -NoNewLine ("$X[38;2;255;165;000;22m" + "$($key.Character)" + "$X[0m")
    }
    if (![string]::IsNullOrEmpty($message)) {
        Write-Host "" # newline
    }
	Write-Host #prevent follow up text from ending up on the same line.
    return $(
        if ($Null -eq $key -or $key.VirtualKeyCode -eq $EnterKey) {
            $Default
        } else {
            $key.Character
        }
    )
}
Function PressTheAnyKeyToExit {#Used instead of Pause so folk can hit any key to exit
	write-host "  Press Any key to exit..." -nonewline
	readkey -NoOutput $True -AllowAllKeys $True | out-null
	WriteLog -info -noconsole "Script Exited"
	Exit
}
Function NoGUIExit {#Used to write to log prior to exit
	WriteLog -info -noconsole "Script Exited."
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
Function SetupServer {
	#Set Firewall Rules
	 #netstat -ano | findstr (get-process -name PalServer-Win64-Test-CMD).id # Using this tells me the query port is 27015. To my knowledge this can't be adjusted.
	 #I don't think 27015 actually uses tcp, it does for other game servers so left it in just in case. I also don't believe RCON uses UDP but again left it in just in case.	
	$ruleDisplayNames = @("Palworld Server TCP In","Palworld Server TCP Out","Palworld Server UDP In","Palworld Server UDP Out")
	foreach ($ruleDisplayName in $ruleDisplayNames) {
		$existingRule = Get-NetFirewallRule -DisplayName $ruleDisplayName -ErrorAction SilentlyContinue
		if ($existingRule -eq $null) {
			# Rule doesn't exist, so create it
			if ($ruleDisplayName -eq "Palworld Server TCP In"){New-NetFirewallRule -DisplayName "Palworld Server TCP In" -Direction Inbound -LocalPort $Config.RCONPort,27015 -Protocol TCP -Action Allow}
			if ($ruleDisplayName -eq "Palworld Server TCP Out"){New-NetFirewallRule -DisplayName "Palworld Server TCP Out" -Direction Outbound -LocalPort $Config.RCONPort,27015 -Protocol TCP -Action Allow}
			if ($ruleDisplayName -eq "Palworld Server UDP In"){New-NetFirewallRule -DisplayName "Palworld Server UDP In" -Direction Inbound -LocalPort $Config.GamePort,$Config.RCONPort,27015 -Protocol UDP -Action Allow}
			if ($ruleDisplayName -eq "Palworld Server UDP Out"){New-NetFirewallRule -DisplayName "Palworld Server UDP Out" -Direction Outbound -LocalPort $Config.GamePort,$Config.RCONPort,27015 -Protocol UDP -Action Allow}
			Writelog -info -noconsole "Setup: "
			Writelog -info -nonewline "Added firewall rule: $ruleDisplayName"
		}
		else {
			Writelog -info -noconsole "Setup: "
			Writelog -info -nonewline "Skipped adding firewall rule '$ruleDisplayName' as it already exists."
		}
	}
	
	#Check if server is already installed in the ServerPath specified in config.xml, if not install it.
	if (-not (Test-Path ($ServerPath + "\palserver.exe"))){
		if (-not (Test-Path $ServerPath)){
			WriteLog -info -noconsole "Setup: "
			WriteLog -info -nonewline "Creating Palworld Server folder in $ServerPath"
			New-Item -ItemType Directory -Path $ServerPath -ErrorAction stop | Out-Null 
		}
		WriteLog -info -noconsole "Setup: "
		WriteLog -info -nonewline "Downloading Palworld Server to $ServerPath"
		Update -install
	}
	WriteLog -success -noconsole "Setup: "
	WriteLog -success -nonewline "Setup Complete."
	pause
	exit
}
Function UpdateCheck {
	# Credit: Some logic pinched from https://superuser.com/questions/1727148/check-if-steam-game-requires-an-update-via-command-line
	$AppInfoFile = "$ServerPath\PalServerBuildID.txt"
	WriteLog -info -noconsole "Update Check: " 
	WriteLog -info -noconsole -nonewline "Checking Updates for App ID 2394010"
	try {
		$AppInfoNew = (Invoke-RestMethod -Uri "https://api.steamcmd.net/v1/info/2394010").data.'2394010'.depots.branches.public.buildid
	} 
	catch {
		WriteLog -errorlog -noconsole "Update Check: " 
		WriteLog -errorlog -noconsole -nonewline "Update Check: Error getting app info for game"
		Pause
		Exit 1
	}
	$NeedsUpdate = $true
	if (Test-Path $AppInfoFile) {
		WriteLog -verbose "Update Check: File PalServerBuildID.txt exists."
		$AppInfo = Get-Content $AppInfoFile
		$NeedsUpdate = $AppInfo -ne $AppInfoNew
	}	
	else {#if file doesn't exist, force update and export file.
		if ($Config.SteamCMDPath -ne ""){#skip update part if steamcmd is not being used.
			Update
		}
		$AppInfoNew | Out-File $AppInfoFile -Force
		$NeedsUpdate = $False
		return
	}
	if ($NeedsUpdate) {
		WriteLog -Info -noconsole "Update Check: "
		WriteLog -Info -nonewline "Update Available!"
		if ($False -eq $UpdateCheck -and $Config.SteamCMDPath -ne ""){
			if ($Running -eq $True){
				WriteLog -info -noconsole "UpdateCheck: Server is currently running"
				RCON_ShutdownRestartNotifier -Restart
			}
			Update -silent
			$AppInfoNew | Out-File $AppInfoFile -Force #overwrite file with build ID
			WriteLog -Success -noconsole "Update Check: "
			WriteLog -success -nonewline "Update Complete!"
		}
		elseif ($Config.SteamCMDPath -eq ""){
			WriteLog -warning -noconsole "Update Check: "
			WriteLog -warning -nonewline "Cannot update as steamcmd is not being used"
		}
	}	
	else {
		WriteLog -Success -noconsole "Update Check: "
		WriteLog -Success -nonewline "Version up-to-date"
	}
}
Function Update {
	param([switch]$Silent,[switch]$install)
	try {
		if ($Install -eq $True){
			WriteLog -info -noconsole "Update: "
			WriteLog -info -nonewline "Downloading..."
		}
		Else {
			WriteLog -info -noconsole "Update: "
			WriteLog -info -nonewline "Updating..."
		}
		if ($silent){
			Start-Process "$($Config.SteamCMDPath)\steamcmd.exe" -ArgumentList "+force_install_dir `"$ServerPath`" +login anonymous +app_update 2394010 validate +quit" -Wait | out-null
		}
		Else {
			Start-Process "$($Config.SteamCMDPath)\steamcmd.exe" -ArgumentList "+force_install_dir `"$ServerPath`" +login anonymous +app_update 2394010 validate +quit" -Wait
		}
		if ($Install -eq $True){
			WriteLog -success -noconsole "Update: "
			WriteLog -success -nonewline "Downloaded!"
		}
		Else {
			WriteLog -success -noconsole "Update: "
			WriteLog -success -nonewline "Updated!"
		}
	}
	Catch {
		WriteLog -errorlog -noconsole "Update: "
		WriteLog -errorlog -nonewline "Couldn't Update :("
	}
}
Function LaunchServer {
	if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){
		WriteLog -info -noconsole "LaunchServer: Server is currently running"
		RCON_ShutdownRestartNotifier -Restart
	}
	if ($False -eq $UpdateOnly) {
		if (-not $Config.NormalSettingsName.EndsWith(".ini")){#add .ini to value if it wasn't specified in config.
			$Config.NormalSettingsName = $Config.NormalSettingsName + ".ini"
		}
		$Config.NormalSettingsName = $Config.NormalSettingsName.tostring()
		if ((Test-Path -Path ($ThemeSettingsPath + $Config.NormalSettingsName)) -ne $true){#if file doesn't exist
				WriteLog -warning -noconsole "LaunchServer: "
				WriteLog -warning -nonewline ($Config.NormalSettingsName + " doesn't exist, copying current config to $ThemeSettingsPath" + $Config.NormalSettingsName)
				Copy-Item "$ServerPath\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini" "$ThemeSettingsPath$($Config.NormalSettingsName)" #$ServerPath\Pal\Saved\Config\WindowsServer\CustomSettings\
		}
		if ($True -ne $Start){
			WriteLog -info -noconsole "LaunchServer: "
			WriteLog -info -nonewline "Starting Palworld Server with Theme Config"
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
					WriteLog -success -noconsole "LaunchServer: "
					WriteLog -success -nonewline "The filename specified for $Day is correct: (`"$IniName.ini`")"
				}
				Else {
					WriteLog -errorlog -noconsole "LaunchServer: "
					WriteLog -errorlog -nonewline "The filename for $Day is incorrect as it doesn't match config in the xml." 
					WriteLog -errorlog -newline ("Either edit the config or ensure there's a file called " + $IniName + ".ini") 
					write-host
					$ErrorCount ++
				}
			}
			if ($ErrorCount -ge 1){
				$Plural = "these"
				if ($ErrorCount -eq 1){
					$Plural = "this"
				}
				WriteLog -errorlog -newline "Correct $Plural and rerun the script. Script will now exit."
				ExitCheck
			}
			$SettingsActual = ($ServerPath +"\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")
			$AllConfigOptionsObject = @()
			foreach ($key in $Script:AllConfigOptions.Keys) {# Adding key-value pairs to the variable
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
			WriteLog -success -noconsole "LaunchServer: "
			WriteLog -success -nonewline ("Copied `"" + $TodaysTheme + "`" Settings to PalWorldSettings.ini")
		}
		Else {
			Copy-Item ($ThemeSettingsPath + $Config.NormalSettingsName) ($Script:ServerPath + "\Pal\Saved\Config\WindowsServer\PalWorldSettings.ini")
			WriteLog -success -noconsole "LaunchServer: "
			WriteLog -success -nonewline "Copied $($Config.NormalSettingsName) to PalWorldSettings.ini"
		}
		If ($True -eq $Config.CommunityServer){
			WriteLog -verbose "LaunchServer: Community is enabled."
			$Community = "EpicApp=PalServer"
		}
		Else {
			$Community = ""
		}
		if ($Null -eq $LaunchParameters -or $LaunchParameters -eq ""){
			WriteLog -verbose "LaunchServer: Standard Launch Parameters used"
			$LaunchParameters = "$Community -log -publicip=$HostIP -publicport=$GamePort -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
		}
		Start-Process ($Script:ServerPath + "\PalServer.exe") $LaunchParameters
		Write-Host
		WriteLog -success "Server Started. Exiting..."
		ExitCheck
	}
}
Function ConfirmPlayer { #Validate if SteamID matches anything for kick/ban.
	param ($PlayerDetails,$reason)
	$Script:PlayersObject = ((RCON_ShowPlayers -ShowPlayers $True) | ConvertFrom-Csv) | Select-Object Name, SteamID
	if ($Script:PlayersObject -eq $null -and $reason -ne "ban"){
		WriteLog -verbose "ConfirmPlayer: There is no-one Online."
		return
	}
	$matches = $PlayersObject | Where-Object { $_.name -eq $PlayerDetails } # Check if the string partially is identical to any "name" value in the array. Checking name needs to come first because otherwise someone could rename themselves to someone elses steamID and get the wrong person kicked/banned
	if ($matches) {
		Writelog -verbose "ConfirmPlayer: Player Name found for $PlayerDetails"
		$Script:PlayerDetailsObject = $matches
		$Script:ProceedWithKickOrBan = $True
		return
	}
	$matches = $PlayersObject | Where-Object { $_.steamid -eq $PlayerDetails } # Check if the string partially is identical to any "name" value in the array
	if ($matches) {
		Writelog -verbose "ConfirmPlayer: Player SteamID found for $PlayerDetails"
		$Script:PlayerDetailsObject = $matches
		$Script:ProceedWithKickOrBan = $True
	}
	else {
		$matches = $PlayersObject | Where-Object { $_.name -like "*$PlayerDetails*" } # Check if the string partially matches any "name" value in the array
		if ($matches) {
			foreach ($match in $matches) {
				Writelog -verbose "ConfirmPlayer: Partial match found for '$PlayerDetails'. Matched name: $($match.name)"
				writelog -info -noconsole ("ConfirmPlayer: Checking if user meant player: " + $match.name + "...")
				while ($PlayerDetailsCheck -notin $YesValues -and $PlayerDetailsCheck -notin $NoValues){
					Write-Host ("Did you mean " + $match.name + "? (Y/N) ") -nonewline -foregroundcolor yellow
					$Script:PlayerDetailsActual = $match.name
					$PlayerDetailsCheck = ReadKeyTimeout "" 8 "n" #Cancel if no response in 8 seconds. Useful if called from external app to script doesn't stay running if name was typo'd. if no button is pressed, send "n" to decline.
				}
				writelog -info -noconsole "ConfirmPlayer: "
				writelog -info -nonewline -noconsole "User answered: $PlayerDetailsCheck"
				if ($PlayerDetailsCheck -eq "y" -or $PlayerDetailsCheck -eq "yes" -or $PlayerDetailsCheck -eq $True){
					$Script:PlayerDetailsObject = $match
					$Script:ProceedWithKickOrBan = $True
					return
				}
				else {
					$PlayerDetailsCheck = $null
					$Script:ProceedWithKickOrBan = $False
				}
			}
		}
		if ($Reason -eq "Ban" -and $Script:ProceedWithKickOrBan -ne $True){ #if ban command is used and player is offline, search playerdb.csv and manually ban
			writelog -warning -noconsole "Confirm Player: "
			writelog -warning -nonewline "$PlayerDetails is not online. Checking PlayerDB..."
			$Script:PlayerIsOffline = $True
			$PlayerDB = import-csv "$ServerPath\Pal\Saved\SaveGames\playerdb.csv"
			foreach ($Player in $PlayerDB){
				if ($Player.steamid -eq $PlayerDetails ){
					writelog -success -noconsole "Confirm Player: "
					writelog -success -nonewline "Matched SteamID to $($Player.Name) in PlayerDB."
					$Script:PlayerDetailsObject = $Player
					$Script:ProceedWithKickOrBan = $True
				}
				elseif ($Player.name -eq $PlayerDetails ){
					writelog -success -noconsole "Confirm Player: "
					writelog -success -nonewline "Matched Player Name to Steam ID:$($Player.SteamID) in PlayerDB."
					$Script:PlayerDetailsObject = $Player
					$Script:ProceedWithKickOrBan = $True
				}
				Elseif ($Player.name -like "*$PlayerDetails*"){
					Writelog -verbose "ConfirmPlayer: Partial match found for '$PlayerDetails'. Matched name: $($Player.name)"
					writelog -info -noconsole ("ConfirmPlayer: Checking if user meant player: " + $Player.name + "...")
					while ($PlayerDetailsCheck -notin $YesValues -and $PlayerDetailsCheck -notin $NoValues){
						Write-Host ("Did you mean " + $Player.name + "? (Y/N) ") -nonewline -foregroundcolor yellow
						$Script:PlayerDetailsActual = $Player.name
						$PlayerDetailsCheck = ReadKeyTimeout "" 8 "n" #Cancel if no response in 8 seconds. Useful if called from external app to script doesn't stay running if name was typo'd. if no button is pressed, send "n" to decline.
					}
					writelog -info -noconsole "ConfirmPlayer: "
					writelog -info -nonewline -noconsole "User answered: $PlayerDetailsCheck"
					if ($PlayerDetailsCheck -eq "y" -or $PlayerDetailsCheck -eq "yes" -or $PlayerDetailsCheck -eq $True){
						writelog -success -noconsole "Confirm Player: "
						writelog -success -nonewline "Matched $PlayerDetails to Steam ID:$($Player.Name) in PlayerDB."
						$Script:PlayerDetailsObject = $Player
						$Script:ProceedWithKickOrBan = $True
						return
					}
					else {
						$PlayerDetailsCheck = $null
						$Script:ProceedWithKickOrBan = $False
					}
				}
				Else {
					$Script:ProceedWithKickOrBan = $False
				}
			}
			if ($Script:ProceedWithKickOrBan -eq $False) {
				writelog -errorlog -noconsole "ConfirmPlayer: "
				writelog -errorlog -nonewline "Couldn't find player online or in PlayerDB."
			}
		}
		Elseif ($Reason -ne "Ban"){
			writelog -error -noconsole "Confirm Player: "
			writelog -error -nonewline "$PlayerDetails is not online to kick."
			$Script:PlayerDetailsActual = $PlayerDetails
			$Script:ProceedWithKickOrBan = $False
		}
	}
}
Function Backup {
	if ($Running -ne $True){
		Writelog -error -noconsole "Backup: "
		Writelog -error -nonewline "Server isn't running. No backup has been taken."
	}
	Else {
		if ($Config.BackupPath -eq ""){
			$backupRoot = ($ServerPath + "\Pal\Saved\SaveGames\Backup")#if no path specified in config, use default path.
		}
		Else {
			$backupRoot = $Config.BackupPath
		}
		$sourcePath = "$ServerPath\Pal\Saved\SaveGames\0\"
		# Get the current date and time
		$currentDateTime = Get-Date
		# Format the date and time components
		$year = $currentDateTime.Year
		$month = $currentDateTime.ToString("MMMM")
		$day = $currentDateTime.ToString("dd")
		$hour = $currentDateTime.ToString("HHmm")

		# Construct the destination path
		$destinationPath = Join-Path -Path $backupRoot -ChildPath "$year\$month\$day\$hour"
		# Create the destination directory if it doesn't exist
		if (-not (Test-Path $destinationPath)) {
			WriteLog -info -noconsole "Backup: Creating Backup Folder in $backupRoot"
			New-Item -ItemType Directory -Path $destinationPath -Force | out-null
		}
		# Save server if it's running. This is to ensure that all files match up before copying. Otherwise if timing is unlucky the server may be halfway through saving files when taking backup.
		if ($Running -eq $True){
			Try {
				RCON_Save
				Writelog -success -noconsole "Backup: "
				Writelog -success -nonewline "Saved Server prior to backup"
			}
			Catch {
				Writelog -error -noconsole "Backup: "
				Writelog -error -nonewline "Couldn't Save Server prior to taking backup. Perhaps you haven't setup RCON."
				Writelog -error -newline "Backing up server with files as is."
			}
		}
		# Copy the folder to the destination
		Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force | out-null
		Writelog -success -noconsole "Backup: "
		Writelog -success -nonewline "Backup completed. Save Data copied to: $destinationPath"
		#Start Cleanup Tasks
		Writelog -info -noconsole "Backup: "
		Writelog -info -nonewline "Checking for old backups that can be cleaned up..."
		$DirectoryArray = New-Object -TypeName System.Collections.ArrayList
		Get-ChildItem -Path "$backupRoot\" -Directory -recurse -Depth 3 | Where-Object {$_.FullName -match '\\\d{4}\\\w+\\\d+\\\d{4}$'} | ForEach-Object {
			$DirectoryObject = New-Object -TypeName PSObject
			$pathComponents = $_.FullName -split '\\'
			$year = $pathComponents[-4]
			$month = $pathComponents[-3]
			$month = [datetime]::ParseExact($month, 'MMMM', $null).Month # convert month from text to number. EG February to 02
			$day = $pathComponents[-2]
			$time = $pathComponents[-1]
			$hour = $time[0]+$time[1]
			$minute = $time[2]+$time[3]
			$dateInFolder = Get-Date -Year $year -Month $month -Day $day -Hour $hour -minute $minute -second 00 #$minute can be changed to 00 if we want all the folders to be nicely named.
			$ShortFolderDate = (Get-Date -Year $year -Month $month -Day $day).ToString("d")
			Add-Member -InputObject $DirectoryObject -MemberType NoteProperty -Name FullPath -Value $_.FullName
			Add-Member -InputObject $DirectoryObject -MemberType NoteProperty -Name FolderDate -Value $dateInFolder
			Add-Member -InputObject $DirectoryObject -MemberType NoteProperty -Name ShortDate -Value $ShortFolderDate
			[VOID]$DirectoryArray.Add($DirectoryObject)
		}
		$DirectoryArray = $DirectoryArray | Sort-Object {[datetime]$_.FolderDate} -Descending
		$HourliesToKeep = $DirectoryArray | Group-Object -Property ShortDate | Select-Object -First 7 | select -expandproperty group #hourlies isn't necessarily hourly, can be taken every few minutes if desired
		$DailiesToKeep = $DirectoryArray | Group-Object -Property ShortDate | ForEach-Object { $_.Group[0] } | Select-Object -skip 7 -First 24 #this is actually useful for capturing the last backup of each day
		$MonthliesToKeep = $DirectoryArray | Group-Object -Property { ($_.ShortDate -split '/')[1] } | ForEach-Object { $_.Group[0] }
		#Perform steps to remove any old backups that aren't needed anymore. Keep all backups within last 7 days (even if last 7 days aren't contiguous). For the last 30 days, keep only the last backup taken on that day (Note that again, 30 days aren't necessarily contiguous). For all older backups, only keep the last backup taken that month.
		foreach ($Folder in $DirectoryArray){
			if ($MonthliesToKeep.FullPath -notcontains $Folder.FullPath -and $DailiesToKeep.FullPath -notcontains $Folder.FullPath -and $HourliesToKeep.FullPath -notcontains $Folder.FullPath){
				$Folder | Add-Member -MemberType NoteProperty -Name KeepFolder -Value "Deleted"
				Remove-Item -Path $Folder.FullPath -Recurse -Force
				Writelog -warning -noconsole "Backup: "
				Writelog -warning -nonewline "Removed $($Folder.FullPath)"
				$Cleanup = $True
			}
			Else {
				$Folder | Add-Member -MemberType NoteProperty -Name KeepFolder -Value $True
			}
		}
		#Perform steps to Cleanup any empty directories.
		Function IsDirectoryEmpty($directory) { #Function to check each directory and subdirectory to determine if it's actually empty.
			$files = Get-ChildItem -Path $directory -File
			if ($files.Count -eq 0) { #directory has no files in it, checking subdirectories.
				$subdirectories = Get-ChildItem -Path $directory -Directory
				foreach ($subdirectory in $subdirectories) {
					if (-not (IsDirectoryEmpty $subdirectory.FullName)) {
						return $false #subdirectory has files in it
					}
				}
				return $true #directory is empty
			}
			return $false #directory has files in it.
		}
		$subdirectories = Get-ChildItem -Path $backupRoot -recurse -Directory
		foreach ($subdirectory in $subdirectories) {
			if (IsDirectoryEmpty $subdirectory.FullName) { # Check if the subdirectory is empty (no files)
				Remove-Item -Path $subdirectory.FullName -Force -Recurse # Remove the subdirectory
				Writelog -warning -noconsole "Backup: "
				Writelog -warning -nonewline "Deleted empty folder: $($subdirectory.FullName)"
				$Cleanup = $True
			}
		}
		Writelog -success -noconsole "Backup: "
		if ($Cleanup -eq $True){
			Writelog -success -nonewline "Backup cleanup complete."
		}
		Else {
			Writelog -success -nonewline "No cleanup required."
		}
	}
}
Function RCON_ShutdownRestartNotifier {
	param ([int]$ShutdownTimer,$ShutDownMessage,[switch]$Restart)
	if ($Restart -eq $True){$RestartOrShutDown = "restart"} Else {$RestartOrShutDown = "shutdown"}
	if ($Null -eq $ShutdownTimer -or $ShutdownTimer -eq ""){$ShutdownTimer = $Config.AutoShutdownTimer}
	if ($Null -eq $ShutdownMessage -or $ShutdownMessage -eq ""){$shutdownmessage = "Server_is_scheduled_to_$RestartOrShutDown..."}
	& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "Shutdown $ShutdownTimer $ShutdownMessage"
	$Script:TimeUntilServerReset = [int]$ShutdownTimer
	WriteLog -info -noconsole "RCON_ShutdownRestartNotifier: "
	WriteLog -info -nonewline ("Waiting " + ([int]$ShutdownTimer + [int]$Delay) + " seconds for server to $RestartOrShutDown...")
	$MinutePlural = "s"
	while ($script:TimeUntilServerReset -gt 0){
		if ((Get-Process | Where-Object {$_.processname -match "palserver"}) -and $script:TimeUntilServerReset -ge 10){ #if server process is still running	
			$script:MinutesRemaining = [math]::floor($Script:TimeUntilServerReset / 60) # Calc Minutes remaining
			$script:SecondsRemaining = $Script:TimeUntilServerReset % 60 # Calc Seconds remaining
			while ($script:MinutesRemaining -gt 60){#if time is over an hour (it bloody shouldn't be) then wait until a more reasonable time to start sending messages.
				start-sleep 60
				$script:MinutesRemaining = $script:MinutesRemaining -60
				$Script:TimeUntilServerReset = $Script:TimeUntilServerReset -60
			}
			if ($script:MinutesRemaining -ge 2 -and $script:SecondsRemaining -ne 0){#if there's a large amount of time left, make a nice even round time when broadcasting messages.
				start-sleep $script:SecondsRemaining
				$script:TimeUntilServerReset = $Script:TimeUntilServerReset - $script:SecondsRemaining
				$script:SecondsRemaining = 0
			}
			Else {
				while ($script:MinutesRemaining -eq 0 -and $script:SecondsRemaining -notin @("10","20","30","40","50")){#if time is within 60 seconds, wait until the time left is a nice round number.
					start-sleep 1
					$script:SecondsRemaining = $script:SecondsRemaining -1
					$Script:TimeUntilServerReset = $Script:TimeUntilServerReset -1
				}
				while ($script:MinutesRemaining -eq 1 -and ($script:SecondsRemaining -ne 0 -and $script:SecondsRemaining -ne 30)){#if time is within 60 seconds, wait until the time left is either 0 or 30
					start-sleep 1	
					$script:SecondsRemaining = $script:SecondsRemaining -1
					$Script:TimeUntilServerReset = $Script:TimeUntilServerReset -1
				} 
				$MinutePlural = ""
			}
			if ($Script:TimeUntilServerReset -ge 3600){#if there's more an hour send a reminder 15 minutes.
				WriteLog -verbose ("RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_in_$MinutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				RCON_Broadcast -BroadcastMessage ("Server_$($RestartOrShutdown)_in_$minutesRemaining" + "_minute$MinutePlural")
				Start-Sleep -Seconds 900 # Wait for 15 minutes
				$script:TimeUntilServerReset = $Script:TimeUntilServerReset -900 # Decrement the time remaining
			}
			elseif ($Script:TimeUntilServerReset -ge 900){#if there's between 15 and 60 mins left, send a reminder every 5 minutes
				WriteLog -verbose ("RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_in_$MinutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				RCON_Broadcast -BroadcastMessage ("Server_$($RestartOrShutdown)_in_$minutesRemaining" + "_minute$MinutePlural")
				Start-Sleep -Seconds 300 # Wait for 300 seconds
				$script:TimeUntilServerReset = $Script:TimeUntilServerReset -300 # Decrement the time remaining
			}
			elseif ($Script:TimeUntilServerReset -ge 300){#if there's between 5 and 15 mins left, send a reminder every minute
				WriteLog -verbose ("RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_in_$MinutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				RCON_Broadcast -BroadcastMessage ("Server_$($RestartOrShutdown)_in_$minutesRemaining" + "_minute$MinutePlural")
				Start-Sleep -Seconds 60 # Wait for 60 seconds
				$script:TimeUntilServerReset = $Script:TimeUntilServerReset -60 # Decrement the time remaining
			}
			Elseif ($Script:TimeUntilServerReset -ge 60){#if there's between 1 and 3 minutes left, send a reminder every 30 seconds.
				WriteLog -verbose ("RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_in_$MinutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				RCON_Broadcast -BroadcastMessage ("Server_$($RestartOrShutdown)_in_$minutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				Start-Sleep -Seconds 30 # Wait for 30 seconds
				$script:TimeUntilServerReset = $Script:TimeUntilServerReset -30 # Decrement the time remaining
			}
			Elseif ($Script:TimeUntilServerReset -ge 10){#if there's between 10 seconds and 1 min left, send a reminder every 10 seconds
				WriteLog -verbose ("RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_in_$MinutesRemaining" + "_minute$MinutePlural" + "_and_$SecondsRemaining" + "_seconds.")
				RCON_Broadcast -BroadcastMessage ("Server_$($RestartOrShutdown)_in_$SecondsRemaining" + "_seconds.")
				if ($Script:TimeUntilServerReset -le 10){#if server is about to restart
					Start-Sleep -Milliseconds 4750 # Only wait for 5 ish seconds so the 'shutting down now' warning can be seen and server can be saved.
					$script:timeUntilServerReset = 0 # Decrement the time remaining
				}
				Else {
					Start-Sleep -Seconds 10 # Wait for 10 seconds
					$script:timeUntilServerReset = $Script:TimeUntilServerReset -10 # Decrement the time remaining
				}
			}
		}
		Elseif ((Get-Process | Where-Object {$_.processname -match "palserver"}) -and $script:TimeUntilServerReset -le 10){
			$QuickShutdown = $True
		}
		Else {#if server was shutdown (eg by user manually), cancel messaging.
			$SkipRemaining = $True
			break
		}
		if (($script:TimeUntilServerReset -eq 0 -and $SkipRemaining -ne $True) -or $QuickShutdown -eq $True){#if there's less than 10 seconds left, announce immediate shutdown.
			if ($Restart -eq $True){$RestartOrShutDown = "restarting"} Else {$RestartOrShutDown = "shutting_down"}
			WriteLog -verbose "RCON_ShutdownRestartNotifier: Server_$($RestartOrShutdown)_now!"		
			if ($QuickShutdown -eq $True){
				if ($script:TimeUntilServerReset -ge 5){
					RCON_Save #Force save just prior to server shutdown
					RCON_Broadcast -BroadcastMessage "Server_$($RestartOrShutdown)_now!"
				}
				Else {
					Write-Host "Server_$($RestartOrShutdown)_now!"	
				}
				start-sleep ($script:TimeUntilServerReset + 5) #wait for remaining shutdown time plus 5 seconds for buffer
			}
			Else {
				RCON_Save #Force save just prior to server shutdown
				RCON_Broadcast -BroadcastMessage "Server_$($RestartOrShutdown)_now!"
				start-sleep (5 + 5) #5 seconds for remaining shutdown time and 5 seconds for buffer
			}
			WriteLog -verbose ("RCON_ShutdownRestartNotifier: Waited " + ([int]$ShutdownTimer + 5) + " seconds for server to shutdown.")
		}
	}
	if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){#if palserver is STILL running, force closure.
		WriteLog -warning -noconsole "LaunchServer: "
		WriteLog -warning -nonewline "Force killing server processes..."
		taskkill /F /IM PalServer.exe | out-null
		taskkill /F /IM PalServer-Win64-Test-Cmd.exe | out-null
	}
}
Function RCON_Broadcast {#RCON
	param ($BroadCastMessage)
	$BroadcastResponse = (& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "Broadcast $BroadcastMessage")[1]
	WriteLog -success -noconsole "RCON_Broadcast: "
	WriteLog -success -nonewline "$BroadcastResponse"
}
Function RCON_Save {#RCON
	WriteLog -success -noconsole "RCON_Save: "
	WriteLog -info -nonewline "Saving..."
	Do {
		$SaveAttempts ++
		$SaveStatus = & ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass Save
	} Until ($SaveStatus -eq "Complete Save" -or $SaveAttempts -eq 3)
	if ($SaveStatus -eq "Complete Save"){
		WriteLog -success -noconsole "RCON_Save: "
		WriteLog -success -nonewline "Saved!"
	}
}
Function RCON_Info {#RCON
	param ($Info,$Version,$ServerName)
	try {
		WriteLog -info -noconsole "RCON_Info: Getting Info data..."
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
				WriteLog -errorlog -noconsole "RCON_Info: "
				WriteLog -errorlog -nonewline "No version number found"
			}
		}	
		WriteLog -info -noconsole "RCON_Info: Info data retreived."
	}
	Catch {
		WriteLog -errorlog -noconsole "RCON_Info: Couldn't pull ServerName"
		write-output "Couldn't retrieve Server Name" | Red
	}
}
Function RCON_ShowPlayers {#RCON
	param ($ShowPlayers,$ShowPlayerCount,$ShowPlayerNames,$ShowPlayersNoHeader,$LogPlayers)
	Try {
		WriteLog -info -noconsole "RCON_ShowPlayers: Getting showplayers data..."
		$PlayersOnline = & ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass showplayers
		$PlayersOnlineObject = ($PlayersOnline  | Select-Object -First ($PlayersOnline.Count - 1)| Select-Object -Skip 1)
		$PlayersOnlineObject = $PlayersOnlineObject | convertfrom-csv	
		$PlayersOnlineCount = $PlayersOnline.count -3
		$PlayersOnlineNames = $PlayersOnline[2..($PlayersOnline.Count - 2)] -replace ',.*', ''
		$PlayerNamesCommaSeparated = ($PlayersOnlineNames -split "`n" | ForEach-Object { $_.Trim() }) -join ', '
		if ($True -eq $ShowPlayerCount){
			$PlayersOnlineCount
		}
		if ($True -eq $ShowPlayers -or $True -eq $ShowPlayersNoHeader -or $True -eq $LogPlayers){
			if ($PlayersOnlineCount -ne 0){
				Function UpdatePlayerDB {
					param([switch]$UpdateCSV,[switch]$addcsv)
					try {
						if ($UpdateCSV -eq $True){
							$PlayerDB | Export-Csv -Path $PlayerCSVFilePath -NoTypeInformation -Force -Encoding utf8 -erroraction stop
							Writelog -info -noconsole ("RCON_ShowPlayers: Player '$($PlayerToUpdate.Name)' updated in CSV." -f $OnlinePlayer.Name)
						}
						If ($AddCSV -eq $True){
							$OnlinePlayer | Export-Csv -Path $PlayerCSVFilePath -Append -NoTypeInformation -Force -Encoding utf8 -erroraction stop
							Writelog -info -noconsole ("RCON_ShowPlayers: Player '{0}' added to CSV." -f $OnlinePlayer.Name)
						}
						$Script:CSVLocked = $False
						start-sleep -milliseconds 10 # Probably not needed but added this to allow a tiny amount of time for writing to release file.
					}
					Catch { #if csv is locked, force closure
						$Script:CSVLocked = $True
					}
				}	
				$PlayerCSVFilePath = ("$ServerPath\Pal\Saved\SaveGames\PlayerDB.csv")
				if (-not (Test-Path $PlayerCSVFilePath)) {# Create CSV file with headers if it doesn't exist
					Writelog -info -noconsole "RCON_ShowPlayers: PlayerDB.csv didn't exist so created it."
					"Name,PlayerUID,SteamID,firstseen,lastseen,previousnames" | Out-File -FilePath $PlayerCSVFilePath -Encoding utf8
				}
				foreach ($OnlinePlayer in $PlayersOnlineObject){
					$PlayerDB = Import-Csv -Path $PlayerCSVFilePath
					$OnlinePlayerMatchesPlayerDB = $PlayerDB | Where-Object { $_.SteamID -eq $OnlinePlayer.SteamID } #check if player already exists in the csv
					if ($OnlinePlayerMatchesPlayerDB) {#if they ARE in the csv file.
						$PlayerToUpdate = $PlayerDB | Where-Object { $_.SteamID -eq $OnlinePlayer.SteamID }
						$PlayerToUpdate.lastseen = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
						if ($OnlinePlayer.name -ne $PlayerToUpdate.name){
							$PlayerToUpdate.PreviousNames = ($PlayerToUpdate.PreviousNames + ", " + $PlayerToUpdate.Name).Trimstart(', ')
							$PlayerToUpdate.Name = $OnlinePlayer.name
						}
						UpdatePlayerDB -UpdateCSV
					}
					else { #if they aren't in the csv file.
						$OnlinePlayer | Add-Member -MemberType NoteProperty -Name 'FirstSeen' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force #add time properties.
						$OnlinePlayer | Add-Member -MemberType NoteProperty -Name 'LastSeen' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force
						UpdatePlayerDB -AddCSV
					}
				}
				if ($Script:CSVLocked -eq $True){
						Writelog -errorlog -noconsole "RCON_ShowPlayers: "
						Writelog -errorlog -newline "Unable to update PlayerDB.csv."
						Writelog -errorlog -nonewline "File is likely locked, make sure to close it if it's open."
						Writelog -errorlog -nonewline "Alternatively perhaps the script doesn't have permissions to write to this location."
						start-sleep 3
				}
				$PlayersOnline = ($PlayersOnline | Select-Object -First ($PlayersOnline.Count - 1)| Select-Object -Skip 1) # skip blank last row. skip rcon command header.
				if ($LogPlayers -eq $True){
					WriteLog -info -noconsole "RCON_ShowPlayers: Players Online: $PlayerNamesCommaSeparated"
					WriteLog -info -noconsole "RCON_ShowPlayers: Writing to PlayersOnline.txt"
					WriteLog -info -noconsole -CustomLogFile "PlayersOnline.txt" "Players Online details: (PlayerName, PlayerUID, SteamID):"
					foreach ($Player in $PlayersOnlineObject){ #skip csv header
						WriteLog -newline -noconsole -CustomLogFile "PlayersOnline.txt" ($Player.Name + ", " + $Player.playeruid + ", " + $Player.Steamid)
						WriteLog -info -noconsole ("RCON_ShowPlayers: added " + $Player.Name + " to PlayersOnline.txt")
					}
					WriteLog -info -noconsole "RCON_ShowPlayers: Wrote to PlayersOnline.txt"
				}
				if ($ShowPlayers -eq $True){
					$PlayersOnline
				}
				Elseif ($ShowPlayersNoHeader -eq $True){
					$PlayersOnline = ($PlayersOnline | Select-Object -Skip 1) # skip blank last row. skip rcon command header.
					$PlayersOnline
				}
			}
			Else {
				WriteLog -info -noconsole "RCON_ShowPlayers: Currently no-one Online"
			}
		}	
		if ($True -eq $ShowPlayerNames -and $PlayersOnlineCount -ne 0){
			$PlayerNamesCommaSeparated
		}
		WriteLog -success -noconsole "RCON_ShowPlayers: Showplayers data retreived"
	}
	Catch {
		WriteLog -errorlog -noconsole "RCON_ShowPlayers: "
		WriteLog -errorlog -nonewline "Couldn't retrieve Player data"
	}	
}
Function RCON_DoExit {#RCON
	WriteLog -warning -noconsole "RCON: "
	WriteLog -warning -nonewline "Shutting down now..."
	& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass DoExit
	start-sleep -milliseconds 4850 #takes a short time for server to actually close
}
Function RCON_KickPlayer {#RCON
	param ($PlayerDetails)
	ConfirmPlayer -PlayerDetails $playerdetails
	if ($Script:PlayersObject -eq $null){
		WriteLog -error -noconsole "RCON_KickPlayer: "
		WriteLog -error -nonewline "There is no-one Online to kick!"
		break
	}
	if ($Script:ProceedWithKickOrBan -ne $False){
		WriteLog -warning -noconsole "RCON: "
		WriteLog -warning -nonewline "Attempting to Kick $($Script:PlayerDetailsObject.name)..."
		$KickResult = (& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "KickPlayer $($Script:PlayerDetailsObject.steamid)") | Select-Object -Skip 1
		$KickResult = $KickResult -replace '\x1B\[[0-9;]*[a-zA-Z]', '' #remove any ANSI codes sent back by ARRCON eg [39m[49m[22m[24m[27m
		if ($KickResult -match "failed to kick") {
			WriteLog -errorlog -noconsole "RCON_KickPlayer: "
			WriteLog -errorlog -nonewline $KickResult
		}
		Else {
			WriteLog -success -noconsole "RCON_KickPlayer: "
			WriteLog -success -nonewline "Kicked $($Script:PlayerDetailsObject.name), SteamID:$($Script:PlayerDetailsObject.steamid)"
		}
	}
	Else {
		writelog -errorlog -noconsole "RCON_KickPlayer: "
		if ($PlayerDetailsActual -ne $Null){
			writelog -errorlog -nonewline "$PlayerDetailsActual was not kicked."
		}
		Else {
			writelog -errorlog -nonewline "$PlayerDetails was not kicked."
		}
	}
}
Function RCON_BanPlayer {#RCON
	param ($PlayerDetails)
	ConfirmPlayer -PlayerDetails $playerdetails -reason "Ban"
	if ($Script:ProceedWithKickOrBan -ne $False){
		if ($Script:PlayerIsOffline -ne $True){ #ARRCON can only ban players who are online.
			WriteLog -warning -noconsole "RCON_BanPlayer: "
			WriteLog -warning -nonewline "Attempting to ban $($Script:PlayerDetailsObject.name)..."
			$BanResult = (& ($Config.ARRCONPath + "\ARRCON.exe") --host $HostIP --port $RCONPort --pass $RCONPass "BanPlayer $($Script:PlayerDetailsObject.steamid)") | Select-Object -Skip 1
			if ($BanResult -match "failed to ban") {
				WriteLog -warning -noconsole "RCON_BanPlayer: "
				WriteLog -warning -nonewline "Unable to ban player SteamID:$($Script:PlayerDetailsObject.steamid)"
			}
			Else {
				WriteLog -success -noconsole "RCON_BanPlayer: "
				WriteLog -success -nonewline "Banned $($Script:PlayerDetailsObject.name), SteamID:$($Script:PlayerDetailsObject.steamid)"
			}
		}
		Else { #if player is offline and a manual add is required, write directly to banlist.txt
			#Add-content "$ServerPath\Pal\Saved\SaveGames\banlist.txt" -value "steam_$($Script:PlayerDetailsObject.steamid)" -ErrorAction Stop
			# Open the file in append mode and specify the encoding
			$streamWriter = [System.IO.StreamWriter]::new("$ServerPath\Pal\Saved\SaveGames\banlist.txt", $true, [System.Text.Encoding]::UTF8)
			# Write the text without appending carriage return and line feed
			$streamWriter.Write("steam_$($Script:PlayerDetailsObject.steamid)`n")
			# Close the StreamWriter
			$streamWriter.Close()			
			
			WriteLog -success -noconsole "RCON_BanPlayer: "
			WriteLog -success -nonewline "Banned Player $($Script:PlayerDetailsObject.name), SteamID:$($Script:PlayerDetailsObject.steamid)"
		}
	}
	Else {
		writelog -errorlog -noconsole "RCON_BanPlayer: "
		if ($PlayerDetailsActual -ne $Null){
			writelog -errorlog -nonewline "$PlayerDetailsActual was not banned."
		}
		Else {
			writelog -errorlog -nonewline "$PlayerDetails was not banned."
		}
	}
}
Function RCON_Logic {#Pull server data or issue commands via the ARRCON client
	WriteLog -info -noconsole "RCON_Logic: Starting RCON Function"
	if ($Running -ne $True){
		WriteLog -errorlog -noconsole "RCON_Logic: Server is offline, RCON function cancelled."
		Write-Output "Server Offline" | Red
		return
	}
	If ($True -eq $Info -or $True -eq $Version -or $ServerName -eq $True){#not overly useful if you run one server, useful if you run multiple
		RCON_Info -Info $Info.ispresent -Version $Version.ispresent -Servername $ServerName.ispresent
	}
	If ($True -eq $ShowPlayers -or $True -eq $ShowPlayerCount -or $True -eq $ShowPlayerNames -or $True -eq $ShowPlayersNoHeader -or $LogPlayers -eq $True){
		RCON_ShowPlayers -ShowPlayers $ShowPlayers -ShowPlayerCount $ShowPlayerCount -ShowPlayerNames $ShowPlayerNames -ShowPlayersNoHeader $ShowPlayersNoHeader -LogPlayers $LogPlayers
	}
	If ($True -eq $Save){
		RCON_Save
	}
	If ($Shutdown -eq $True){
		#RCON_Shutdown -ShutdownTimer $ShutdownTimer -shutdownmessage $shutdownmessage
		RCON_ShutdownRestartNotifier -ShutdownTimer $ShutdownTimer -ShutdownMessage $ShutDownMessage
	}
	If ("" -ne $Broadcast){
		RCON_Broadcast -BroadcastMessage $Broadcast
	}
	If ($True -eq $DoExit){
		RCON_DoExit
	}
	If ($KickPlayer -ne "" -and $Null -ne $KickPlayer){
		RCON_KickPlayer -PlayerDetails $KickPlayer
	}
	If ($BanPlayer -ne "" -and $Null -ne $BanPlayer){
		RCON_BanPlayer -PlayerDetails $BanPlayer
	}
}
Function SteamCMDCheck {
	#Download and setup SteamCMD
	If ($Config.SteamCMDPath -match "steamcmd.exe"){$Config.SteamCMDPath = $Config.SteamCMDPath.replace("\steamcmd.exe","")}
	if ($Config.SteamCMDPath -eq ""){
		$Script:Config.SteamCMDPath = "C:\Program Files\SteamCMD"
		Write-Host
		WriteLog -info -noconsole "SteamCMDCheck: "
		WriteLog -info -nonewline "Updating SteamCMDPath in Config.xml"
		$XML = Get-Content "$Script:WorkingDirectory\Config.xml"
		$Pattern = "<SteamCMDPath></SteamCMDPath>"
		$Replacement = "<SteamCMDPath>$($Config.SteamCMDPath)</SteamCMDPath>"
		$NewXML = $XML -replace [regex]::Escape($Pattern), $Replacement
		$NewXML | Set-Content -Path "$Script:WorkingDirectory\Config.xml"
		WriteLog -success -noconsole "SteamCMDCheck: "
		WriteLog -success -nonewline "Updated SteamCMDPath to $($Config.SteamCMDPath) in config.xml"
		Start-Sleep -milliseconds 1500
	}
	if (-not (Test-Path ($Config.SteamCMDPath + "\steamcmd.exe"))){
		Writelog -info -noconsole "SteamCMDCheck: "
		Writelog -info -nonewline "Steam CMD not installed, Start download steamcmd.zip..."
		if (-not (Test-Path $Config.SteamCMDPath)){
			WriteLog -info -noconsole "SteamCMDCheck: "
			WriteLog -info -nonewline "Creating SteamCMD folder in $($Config.SteamCMDPath)"
			New-Item -ItemType Directory -Path $Config.SteamCMDPath -ErrorAction stop | Out-Null 
		}
		$SteamCMDZipURL = "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
		Invoke-RestMethod -Uri $SteamCMDZipURL -OutFile ($Config.SteamCMDPath + "\steamcmd.zip")
		Expand-Archive -Path ($Config.SteamCMDPath + "\steamcmd.zip") -DestinationPath ($Config.SteamCMDPath) -Force
		Remove-Item -Path ($Config.SteamCMDPath + "\steamcmd.zip")
		WriteLog -success -noconsole "SteamCMDCheck: "
		WriteLog -success -nonewline "SteamCMD installed to $($Config.SteamCMDPath)."
	}
}
Function ARRCONCheck {
	#Check if ARRCON is installed if not install it.
	if ($Config.ARRCONPath -eq ""){
		WriteLog -verbose ("ARRCONCheck: ARRCON not Specified in Config.xml. Setting this to 'C:\Program Files\ARRCON'")
		$Script:Config.ARRCONPath = "C:\Program Files\ARRCON\"
	}
	WriteLog -verbose ("ARRCONCheck: Checking if ARRCON.exe can be found in '" + $Config.ARRCONPath +"'")
	if (-not (Test-Path ($Config.ARRCONPath + "\ARRCON.exe"))){
		if (-not (Test-Path $Config.SteamCMDPath)){
			WriteLog -info -noconsole "ARRCONCheck: "
			WriteLog -info -nonewline "Creating ARRCON folder in $($Config.ARRCONPath)"
			New-Item -ItemType Directory -Path $Config.ARRCONPath -ErrorAction stop | Out-Null 
		}
		$ARRCONReleases = Invoke-RestMethod -Uri "https://api.github.com/repos/radj307/ARRCON/releases"
		$ARRCONReleaseInfo = ($ARRCONReleases | Sort-Object id -desc)[0] #find release with the highest ID.
		$ARRCONDownloadURL = $ARRCONReleaseinfo.assets.browser_download_url | where-object {$_ -like "*windows*"}
		Invoke-WebRequest -Uri $ARRCONDownloadURL -OutFile "$($Config.ARRCONPath)\ARRCON-$($ReleaseInfo.Tag_name)-Windows.zip"
		Expand-Archive -Path "$($Config.ARRCONPath)\ARRCON-$($ReleaseInfo.Tag_name)-Windows.zip" -DestinationPath $Config.ARRCONPath -Force
		start-sleep 5 #give a tiny bit of time to remove file lock from zip.
		Remove-Item -Path "$($Config.ARRCONPath)\ARRCON-$($ReleaseInfo.Tag_name)-Windows.zip"
		WriteLog -success -noconsole "ARRCONCheck: ARRCON installed"
	}
	Else {
		WriteLog -Success -noconsole "ARRCONCheck: ARRCON already installed"
	}
	if ((Test-Path -Path ($Config.ARRCONPath + "\ARRCON.exe")) -ne $true){
		WriteLog -errorlog -noconsole "ARRCONCheck: "
		WriteLog -errorlog -nonewline "ARRCON was not found in the specified path in config.xml."
		WriteLog -errorlog -noconsole "ARRCONCheck: "
		WriteLog -errorlog -nonewline "ERROR: Please ensure you have downloaded ARRCON.exe and specified the correct folder in config.xml."
		WriteLog -errorlog -nonewline "ARRCON.exe can be downloaded from https://github.com/radj307/ARRCON"
		Pause
		ExitCheck
	}
	Else {
		WriteLog -Success -noconsole "ARRCONCheck: ARRCON.exe was found in the specified path in config.xml."
	}
}
Function Menu {
	WriteLog -warning -noconsole "Menu: "
	WriteLog -warning -nonewline "No launch parameters provided."
	WriteLog -info -noconsole "Menu: "
	WriteLog -info -nonewline "A future version will have a CLI based Menu and/or a GUI for running basic tasks." 
	WriteLog -info -newline "Until then, this is primarily a tool to run in the backend and requires the use of parameters to run."
	WriteLog -info -newline "For example in PowerShell (in the script directory) you can use: & .\PalworldServerTools.ps1 -info"
	write-host
	WriteLog -info -newline "See Github for documentation on how to use this script."
	WriteLog -info -newline "https://github.com/shupershuff/PalworldServerTools"
	write-host
	pause
	PressTheAnyKeyToExit
}
##########################################################################################################
# Config Import, Validation and Variable Setup.
##########################################################################################################
Function ImportXML {
	try {
		WriteLog -info -noconsole "Initialisation: Attempting to import config.xml" 
		$Script:Config = ([xml](Get-Content "$Script:WorkingDirectory\Config.xml" -ErrorAction Stop)).PalworldServerToolsConfig
		WriteLog -info -noconsole "Initialisation: Config imported successfully."
	}
	Catch {
		Write-Host ""
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "Config.xml Was not able to be imported. This could be due to a typo or a special character such as `'&`' being incorrectly used."
		WriteLog -errorlog -newline "The error message below will show which line in the clientconfig.xml is invalid:"
		WriteLog -errorlog -newline (" " + $PSitem.exception.message)
		Write-Host ""
		ExitCheck
	}
}
foreach($boundparam in $PSBoundParameters.GetEnumerator()) {
	#WriteLog -info -noconsole ("Initialisation: Launch Parameter " + $boundparam.Key + " was used.")
	if ($boundparam.value -ne $True -and $boundparam.value -ne $False) {#if value isn't true or false
		$UsedParameters += $boundparam.Key
		$UsedParameters += " ('$($boundparam.value)')`n"
	}
	Else {
		$UsedParameters += $boundparam.Key + "`n"
	}
}
$usedParametersString = ($usedParameters -replace "`n", ", ").TrimEnd(', ')
$UsedParametersStringDashSeperated = (($usedParametersString -replace '^(.)', '-$1') -replace ',', ' ' -split '\s+') -join ' -'
$UsedParametersStringDashSeperated = $UsedParametersStringDashSeperated -replace ' -\([^)]+\)', ''
WriteLog -newline -noconsole #Add a linebreak in the log in between instances.
if ($usedParameters -eq "" -or $usedParameters -eq $null){
	WriteLog -info -noconsole "Script Started with no launch parameters."
}
Else {
	WriteLog -info -noconsole "Script Started with these launch parameters: $UsedParametersStringDashSeperated."
}
ImportXML
SteamCMDCheck
ARRCONCheck
if ($Null -ne $Kick -and $Kick -ne ""){$KickPlayer = $Kick} #allow users to use -kick to save keypresses.
if ($Null -ne $Ban -and $Ban -ne ""){$BanPlayer = $Ban} #allow users to use -ban to save keypresses.
if ($Null -ne $Config.AutoShutdownMessage){#remove this config option as arguments are now stored in accounts.csv so that different arguments can be set for each account
	Write-Host
	WriteLog -warning -noconsole "XML Validation: "
	WriteLog -warning -nonewline "Config option 'AutoShutdownMessage' is being removed."
	WriteLog -warning -newline "Config option is no longer used. See v1.1.0 release notes."
	$XML = Get-Content "$Script:WorkingDirectory\Config.xml"
	$Pattern = ";;\t<!-- What warning should users get. Note, as of 1.3.0, messages with spaces can't be sent :\( -->;;\t<AutoShutdownMessage>.*?</AutoShutdownMessage>"
	#$Pattern = ";;\t<!--Optionally add any command line arguments that you'd like the game to start with-->;;\t<CommandLineArguments>.*?</CommandLineArguments>;;"
	$NewXML = [string]::join(";;",($XML.Split("`r`n")))
	$NewXML = $NewXML -replace $Pattern, ""
	$NewXML = $NewXML -replace ";;","`r`n"
	$NewXML | Set-Content -Path "$Script:WorkingDirectory\Config.xml"
	Write-Host "AutoShutdownMessage has been removed from config.xml" -foregroundcolor green
	Start-Sleep -milliseconds 1500
}
if ($Null -eq $Script:Config.BackupPath){
	Write-Host
	WriteLog -warning -noconsole "XML Validation: "
	WriteLog -warning -nonewline "Config option 'BackupPath' missing from config.xml"
	WriteLog -warning -newline "This is due to config.xml recently being updated."
	WriteLog -warning -newline "This is an optional config option used to specify custom backup paths."
	WriteLog -warning -newline "See v1.1.0 release notes."
	Write-Host
	$XML = Get-Content "$Script:WorkingDirectory\Config.xml"
	$Pattern = "</ServerPath>"
	$Replacement = "</ServerPath>`n`t<!-- Path of where backups are stored. Leave blank for default backup path (<SERVER>\Pal\Saved\SaveGames\Backup) or specify your own. -->`n`t"
	$Replacement += "<BackupPath></BackupPath>" #add option to config file if it doesn't exist.
	$NewXML = $XML -replace [regex]::Escape($Pattern), $Replacement
	$NewXML | Set-Content -Path "$Script:WorkingDirectory\Config.xml"
	Write-Host "Added <BackupPath> into config.xml" -foregroundcolor green
	Start-Sleep -milliseconds 1500
}
$Script:YesValues = @(
	'Yes',
	'YES',
	'Y',
	'yes',
	'y',
	'true'
)
$Script:NoValues = @(
	'No',
	'NO',
	'N',
	'no',
	'n',
	'na',
	'false'
)
$RCONParameters = @("Info", "Version", "ServerName", "ShowPlayers", "ShowPlayersNoHeader", "ShowPlayerCount", "ShowPlayerNames", "LogPlayers", "Shutdown", "ShutdownTimer", "ShutdownMessage", "Broadcast", "DoExit", "Save", "RCONPort", "RCONPass", "KickPlayer", "BanPlayer")
foreach ($ParameterName in $RCONParameters) {
	$ParameterValue = Get-Variable -Name $ParameterName -ValueOnly
	if (($null -ne $ParameterValue -and $ParameterValue -ne "" -and $ParameterValue -ne $False) -or $ParameterValue -eq $True){
		$RCONParamsUsed = $True
		WriteLog -info -noconsole "Initialisation: RCON Parameter $ParameterName supplied with value: $ParameterValue"
	}
}
If ($Null -eq $HostIP){
	$HostIP = $Config.HostIP
	If ($Null -eq $HostIP -or $HostIP -eq ""){#Required value. If value is still empty throw an error and exit.
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "HostIP is not specified in config.xml"
		start-sleep 4
		ExitCheck
	}
}
If ($Null -eq $GamePort){#If Launch Parameter wasn't supplied
	$GamePort = $Config.GamePort #Use Value from config.xml
	If ($Null -eq $GamePort -or $GamePort -eq ""){#Required value. If value is still empty throw an error and exit.
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "GamePort is not specified in config.xml"
		start-sleep 4
		Exit 1
	}
}
If ($Null -eq $RCONPort){#If Launch Parameter wasn't supplied
	$RCONPort = $Config.RCONPort #Use Value from config.xml
	If ($Null -eq $RCONPort -or $RCONPort -eq ""){#Required value. If value is still empty throw an error and exit.
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "RCONPort is not specified in config.xml"
		start-sleep 4
		Exit 1
	}
}
If ($Null -eq $RCONPass){#If Launch Parameter wasn't supplied
	$RCONPass = $Config.RCONPass #Use Value from config.xml
	If ($Null -eq $RCONPass -or $RCONPass -eq ""){#Required value. If value is still empty throw an error and exit.
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "RCONPass is not specified in config.xml"
		start-sleep 4
		Exit 1
	}
}
If ($Null -eq $ServerPath){#If Launch Parameter wasn't supplied
	if ($Config.ServerPath -ne ""){
		$ServerPath = $Config.ServerPath #Use Value from config.xml
		if (-not (Test-Path $ServerPath)) { #If path doesn't exist
			New-Item -ItemType Directory -Path $ServerPath -ErrorAction stop | Out-Null  #create folder.
		}
		if ($setup -eq $True -and -not (Test-Path "$ServerPath\palserver.exe")){
			writelog -errorlog -noconsole "Initialisation: "
			writelog -errorlog -nonewline "Server Path is inaccurate or server files don't yet exist."
			writelog -errorlog -newline "If the server files don't exist yet, then please run the -setup parameter."
			writelog -errorlog -newline "Otherwise please ensure the server path is accurate in config.xml."
			start-sleep 4
			exit 1
		}
	}
	Else {
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "Cannot Proceed as ServerPath isn't defined."
		WriteLog -errorlog -newline "Please provide the Path to the server files in the config.xml or via parameter."
		start-sleep 4	
		Exit 1
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
	WriteLog -warning -noconsole "Initialisation: "
	WriteLog -warning -nonewline "Can't find folder for Custom settings."
	WriteLog -warning -newline "Creating Folder in $ThemeSettingsPath"
	New-Item -ItemType Directory -Path $ThemeSettingsPath -ErrorAction stop | Out-Null 
}
##########################################################################################################
# Script Logic
##########################################################################################################
if ($null -eq $usedParameters) {#if user runs this script without any parameters, load menu
	Menu
} 
else {
	if (($usedParameters -split "`n").trim.Length -gt 1){$UsedParamPlural = "s"}
    WriteLog -info -noconsole "Initialisation: Launch parameter$UsedParamPlural $usedParametersString provided."
}
if ($Setup -eq $True){
	#run script as admin
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Setup"  -Verb RunAs;exit
	}
	SetupServer
}
if ($null -ne (Get-Process | Where-Object {$_.processname -match "palserver"})){#if palserver is running
	$Running = $True
}
if ($true -eq $TodaysTheme){
	WriteLog -info -noconsole "Initialisation: Parameter supplied for TodaysTheme. Checking for Todays Theme..."
	Try {
		$TodaysThemeText = Get-content  "$WorkingDirectory\TodaysTheme.txt"
		WriteLog -info -noconsole "Initialisation: Todays Theme is $TodaysThemeText"
		$TodaysThemeText
	}
	Catch {
		WriteLog -errorlog -noconsole "Initialisation: "
		WriteLog -errorlog -nonewline "Couldn't obtain todays theme from '$WorkingDirectory\TodaysTheme.txt'."
		WriteLog -errorlog -newline "Check Config.xml is accurate or run the script with -startthemed once to generate TodaysTheme.text"
	}	
}
if ($true -eq $UpdateOnly -or $true -eq $UpdateCheck){#if updatecheck param supplied, this doesn't update and only returns a value. Useful for sensors.
	WriteLog -info -noconsole "Initialisation: Parameter supplied for either updateonly or updatecheck. Checking for updates."
	UpdateCheck
}
if ($Backup -eq $True){
	Backup
}
if ($true -eq $Start -or $true -eq $StartThemed){
	WriteLog -info -noconsole "Initialisation: Parameter supplied to start Server."
	if ($true -ne $noUpdate){#update server unless it was specified not to at launch
		WriteLog -info -noconsole "Initialisation: Checking for updates as part of launch process."
		UpdateCheck
	}
	LaunchServer
}
if ($True -eq $RCONParamsUsed){
	RCON_Logic
	ExitCheck
}
