# Palworld Server Tools
PowerShell based tool for administering dedicated Palworld servers.

Readme and instructions IN PROGRESS

**Note:**
This is an early version of this script and will likely have some bugs.<br>
If you notice anything funky or would like additional functionality, please raise an issue.<br>
Please also see the [Planned Changes](#planned-changes) section below.<br>

## Usage:
Script is designed to be used with Task Scheduler (for updating/launching server)<br>
Can also be used with HASS.Agent (or other tools) to issue and capture the results of RCON commands.<br>
To use, call the script with launch parameters eg "& '.\PalworldServerTools.ps1' -save"<br>
<br>
Note: It's early days, I'll look at developing a front end, auto refreshing CLI so you can server status (players online, version, update status etc).<br>
You can also review the log file for what's happening when you're running commands that don't have a lot of CLI output.<br>

## Features:
**RCON Calls**<br>
Section TBC, but you can run RCON commands to retrieve data or initiate server actions.<br>
<br>
Note: Kick and Ban not implemented yet.<br>

**Daily Settings Switcher**<br>
Run daily events on your server! That's right you can have different settings for each day of the week.<br>
Simply create the custom config (.ini) files and specify which day should load them. See [Setup Information](#setup-information) for more details.<br>

**Server Admin**<br>
You can check for updates, initiate updates, start and stop the server.<br>

Note: Auto Update feature not implemented yet but planned.

**Backups**<br>
Not available yet, coming soon<br>

**Useful for those with Home Assistant**<br>
For Home Assistant users, Using HASS.Agent on your windows PC you can setup PowerShell based sensors/commands to retrieve/send data to the server.<br>
You can setup a card like this and share it with your players/mods for basic remote control functions without needing to give them the RCON password.<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/6c331e8c-e8a2-4fbb-a685-b7bff4a3b313)<br>

# Setup Information #
**Download Script Release, ARRCON.exe and SteamCMD**
1. Download ARRCON from https://github.com/radj307/ARRCON and place the .exe somewhere on your PC (anywhere is fine).
2. Download Latest PalworldServerTools Release from my Github [here](https://github.com/shupershuff/PalworldServerTools/releases/latest).
3. Extract PalworldServerTools to any folder you want, I would recommend putting the files in the same folder as palserver.exe
4. TBC SteamCMD steps

**Optional - Configure your .ini files**<br>
Section TBC but basically the script will be able to load any files ending with .ini in this folder "<SERVERPATH>\Pal\Saved\Config\WindowsServer\CustomSettings".<br>
You can then mention the names of these in the config.xml file for them to load on a given day. Using this script means that PalWorldSettings.ini will be overwritten each time you launch the server, so any edits to game settings should be run out of this folder.<br>
Configuring the ini files themselves is essentially just a case of specifying the available game config parameters which you can see on Palworlds site [here](https://tech.palworldgame.com/optimize-game-balance).<br>
If you don't want to use this feature then set each day in config.xml to the same value as NormalSettingsName
1. TBC

**Configure the XML file**
Section TBC but the config.xml file should mostly be self explanatory with the descriptions above each config option.<br>
- HostIP - 
- GamePort - 
- CommunityServer - 
- RCONPort - 
- RCONPass - 
- SteamCMDPath - 
- ARRCONPath - 
- ServerPath - 
- ThemeSettingsPath - 
- NormalSettingsName - 
- AutoShutdownTimer - 
- AutoShutdownMessage - 
- Monday..Sunday - 
Currently there is some basic validation to check if *some* of the info in the config file is valid.<br>

**Test Script**<br>
Section TBC but recommend opening a PowerShell instance and running script with the various parameters you intend to use to test that everything works before you setup scheduled tasks or sensors.

You'll want to test the functions first and ensure there aren't any errors due to misconfiguration.
1. TBC

**Configure Task Scheduler**<br>
1. TBC

**Launch Parameters available:**<br>
At this stage this script is mostly a backend tool so these Parameters are the main means of performing tasks.<br>
Parameters utilizing RCON:
- -Info - RCON request to return server Info.
- -Version - Used to specifically return server version text provided by -info
- -ServerName - Used to specifically return server name text provided by -info
- -ShowPlayers - Show the names of all logged in players.
- -ShowPlayerCount - Number of players online
- -Shutdown - Used to initiate a planned shutdown. Can be used in conjunction with -shutdowntimer and -shutdownmessage. The script will also initiate a broadcast message notifying of shutdown when it's imminent.
- -ShutdownTimer - Optional parameter. Used to specify how many seconds until shutdown should occur. If not specified it will use the value from the config file.
- -ShutdownMessage - To use this use -broadcast "message". Used to customise the shutdown message.
- -Broadcast - To use this use -broadcast "message". Sends a message to all players. Note that as of the time of writing, it's not possible to send messages with spaces in them (game limitation).
- -DoExit - Schedule an immediate shutdown of the server.
- -Save - Force server to save data.

Server Launch and misc Parameters:
- -StartNoTheme - Will check for updates and start the server using your "Normal" settings
- -StartThemed - Will check for updates and start the server using the 'themed' settings for whatever day it is
- -NoUpdate - To be used in conjuntion with -StartNoTheme or -StartThemed so that server starts immediately without checking for updates.
- -UpdateOnly - Will launch the script
- -UpdateCheck - Used to check if there's updates available (but not update) and return either "Version Up to date" or "Update Available"
- -TodaysTheme - This will display the name of the settings (.ini) that has been loaded
- -NoLogging - This disables entries being written to the log file. Useful if you want to prevent sensors from writing to the log file every minute.

Parameters you'll likely not need, but they're here if you need them:
- -ServerPath - Used to specify server path. Parameter only useful if you're hosting more than one server.
- -ThemeSettingsPath - Used to specify where custom ini files live. Parameter only useful if you're hosting more than one server and can be left blank to assume the default location.
- -LaunchParameters - Used to specify custom launch parameters if they differ from the default. Can be left blank.
- -HostIP - Used to specify server address/domain. Parameter only useful if you're hosting more than one server.
- -RCONPort - Used to specify RCON Port. Parameter only useful if you're hosting more than one server.
- -RCONPass - Used to specify RCON Password. Parameter only useful if you're hosting more than one server.

**Home Assistant Nerds**<br>
TBC - explain setup<br>

# FAQ #
- TBC
- Not seeing something here? Go to [GitHub issues](https://github.com/shupershuff/PalworldServerTools/issues) and log a request, issue or question.

# Planned Changes/Features/Fixes #
- Automate Local Backups (hourlies for 1 day, dailies, weekly) for both level data and characters.
- Automated Server update checks
- Add a means of checking whether there's a script update available from GitHub.
- Front End CLI or better yet a proper GUI (would love help if you're any good with this sort of thing).
- Fix stuff that doesn't work :)
- Not seeing something here? Go to [GitHub issues](https://github.com/shupershuff/PalworldServerTools/issues) and log a request, issue or question.

**Known Issues**<br>
- Unable to broadcast any messages with spaces in them for broadcast or shutdownmessage. Appears to be a game bug.

# Usage and Limitations #
Happy for you to make any modifications this script for your own needs providing:
 - Any variants of this script are never sold.
 - Any variants of this script published online should always be open source.
 - Any variants of this script are never modifed to enable or assist in any malicious behaviour including (but not limited to): Bannable Mods, Cheats, Exploits, Phishing, Botting.

# Thanks and Credit for things I stole #
- ARRCON - This tool makes use of another tool someone else on the internet made: https://github.com/radj307/ARRCON
- ChatGPT for helping with regex patterns.
- Google.com
- Thanks to Nintendo for releasing this game.
  <br>
  <br>
Tags for Google SEO (maybe): PalworldServerTools, Shuper, whyareyoureadingthesetags, Pal World, Server Administration, admin, RCON, stillreadingthesetags, palworld dedicated server, palworld server, didyouspotthespellingerrorinoneofthetags, powershell, therearenospellingerrorsorarethere, pocketable-monsters
