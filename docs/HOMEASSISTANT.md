# Overview
If you're a Home Assistant user and want to create a dashboard with server controls for yourself or even share with a friend... Well you can!<br>

## HASS.Agent Setup
HASS.Agent is a brilliant tool that can be used by Home Assistant to execute commands or retrieve data from sensors on your computer.<br>
<br>
**Installation**<br>
The agent can be found here: https://github.com/LAB02-Research/HASS.Agent<br>
Installation instructions can be seen here:<br>
https://hassagent.readthedocs.io/en/latest/installation-and-configuration-summary<br>

**Sensors Configuration**<br>
Note, if you've confirmed that your script is running successfully I would recommend adding the parameter -NoLogging so your log file doesn't get added too each time one of these sensors refresh.<br>
Command used that's obscured in the below screenshot is:<br>
```C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File 'C:\Palworld Server\.PalworldServerTools.ps1' -info -NoLogging```<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/2782b8a9-4e33-42cd-adfd-694494fa5cba)<br>
<br>
For sensors that read text files (eg TodaysTheme.txt) I used this basic command:<br>
```get-content 'C:\Palworld Server\TodaysTheme.txt'```

**Commands**<br>
Note: As we are issuing commands I would recommend NOT putting the -NoLogging parameter in.<br>
For starting scheduled tasks:<br>
```C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -command "Get-ScheduledTask -TaskName 'Start Palworld Server' | Start-ScheduledTask"```<br>
For Issuing RCON commands:<br>
```C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -File "C:\Palworld Server\.PalworldServerTools.ps1" -Save```<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/7f4e165d-582c-47a7-bbc3-e94a92924b51)<br>

## Lovelace Card ##
The yaml below is what I use on my Lovelace card.<br>
I've added comments to the YAML below but to summarise, the conditions perform the following:<br>
- If the serverhost itself is not powered on, don't show the card at all.
- If the serverhost is powered on but server isn't running only show relevant cards
  ![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/a185d98f-11fd-457d-9b96-b46fc628506f)<br>
- If serverhost is powered on and Server is running, show relevant cards.
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/b78396e1-20ac-4732-9679-c009a99a414a)
- If serverhost is powered on, Server is running but needs an udpate, show a an update and restart option.
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/f144645f-bbc8-45e9-9224-6b8b486766d3)<br>

**YAML to configure the card**<br>
I will note that I'm not an expert with Home Assistant by any means, so there may be a more efficient way of creating these cards.<br>
Feel free to provide improvement suggestions or show me what you've setup!<br>
```
type: conditional
conditions: # Is computer checking in. If it's unavailable then it's turned off.
  - condition: state
    entity: sensor.ExampleHostname_palworld_versionc_usernotificationstate
    state_not: unavailable
card:
  square: false
  type: grid
  cards:
    - type: entities
      entities:
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is not running.
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state_not: '1'
          row:
            type: text
            name: 'PalServer-Win64-Test-CMD:'
            text: Not Running :(
            icon: mdi:server
        - type: conditional
          conditions:
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            type: text
            name: 'PalServer-Win64-Test-CMD:'
            text: Running
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer.exe is not running.
            - entity: sensor.ExampleHostname_processactive_palserver
              state_not: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Not Running :(
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer.exe is running.
            - entity: sensor.ExampleHostname_processactive_palserver
              state: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Running
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running.
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_server_name
            icon: mdi:rename
            name: Server Name
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show todays theme sensor.
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_todays_theme
            icon: mdi:rename
            name: Todays Theme
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show version sensor
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_version
            icon: mdi:update
            name: Version
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show updatecheck status sensor
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_update_available
            icon: mdi:update
            name: Update Status
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, showplayers who online
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_players
            name: Players
            icon: mdi:bug-play-outline
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show count of players who are online
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.ExampleHostname_palworld_player_count
            name: Player Count
            icon: mdi:counter
      title: PalWorld Server Status
    - type: entities
      entities:
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is not running and steam CMD is not running (ie, not in the middle of an update), show the start server button, 
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state_not: '1'
            - entity: sensor.ExampleHostname_processactive_steamcmd
              state_not: '1'
          row:
            entity: button.ExampleHostname_palworldstartserver
            name: Start Server
            icon: mdi:controller
        - type: conditional
          conditions: # If there's an update available, server is online and not currently updating, show update button
            - entity: sensor.ExampleHostname_palworld_update_available
              state: Update Available!
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
            - entity: sensor.ExampleHostname_processactive_steamcmd
              state_not: '1'
          row:
            entity: button.ExampleHostname_palworldupdateserver
            name: Update and Restart Server
            icon: mdi:update
        - type: conditional
          conditions: # If server is running, show this stop button
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.ExampleHostname_palworldstopservergracefully30
            name: Stop Server Gracefully (30 Seconds)
            icon: mdi:hand-back-right
        - type: conditional
          conditions: # If server is running, show this stop button
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.ExampleHostname_palworldstopservergracefully10
            name: Stop Server Gracefully (10 Seconds)
            icon: mdi:hand-back-right
        - type: conditional
          conditions: # If server is running, show this stop now button
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.ExampleHostname_palworldstopservernow
            name: Stop Server NOW
            icon: mdi:octagon
        - type: conditional
          conditions: # If server is running, show this Save button
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.ExampleHostname_palworldsaveserver
            name: Save Server
            icon: mdi:content-save
        - type: conditional
          conditions: # if steamcmd process is active, server must be updating.
            - entity: sensor.ExampleHostname_processactive_steamcmd
              state: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Server Updating
            icon: mdi:update
        - type: conditional
          conditions: # I haven't figured out a way to send broadcasts yet, I'll probably investigate once Palworld devs resolve the bug with server messages not allowing space characters.
            - entity: sensor.ExampleHostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            type: text
            name: Broadcast message
            text: Feature coming soon!
            icon: mdi:bullhorn
      title: Palworld Server Controls
  columns: 1
```
