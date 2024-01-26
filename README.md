# PalworldServerTools
PowerShell based tool for administering dedicated Palworld servers

Readme and instructions TBC

**PLEASE NOTE THAT THIS IS PRERELEASE**
I haven't had time to fully test yet, just making public now as I've had a few folk ask about it.

**Usage:**
Script is designed to be either used with Task Scheduler (for updating/launching server) or HASS.Agent where it runs RCON commands in the background and if applicable retrieve output data.
I'll add some more content into it so you can also actually run it from the CLI and see what it's doing

To use, call the script with launch parameters eg PalworldServerTools.ps1 -save

**Parameters available:**
TBC a write up on usage for all of these.
- $Info
- $ShowPlayers
- $ShowPlayerCount
- $Shutdown
- $ShutdownTimer
- $ShutdownMessage
- $Broadcast
- $BroadcastMessage
- $DoExit
- $Save
- $ServerPath
- $CustomSettingsPath
- $LaunchParameters
- $HostIP
- $RCONPort
- $RCONPass
- $UpdateOnly
- $NoUpdate
- $StartNoTheme
- $StartThemed
- $TodaysTheme

**Planned changes**
Moving config into a seperate xml file so folk aren't editing the ps1 file, this makes it tidier and causes less of a hassle if a new version of script is released.
Backups
Front End

**Known Issues**
- Unable to broadcast any messages with spaces in them for broadcast or shutdownmessage. Appears to be a game bug.
