# Overview
TBC
## Hass.Agent Setup
TBC

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

**YAML**<br>
I will note that I'm not an expert with Home Assistant by any means, so there may be a more efficient way of creating these cards.<br>
Feel free to provide improvement suggestions or show me what you've setup!<br>
```
type: conditional
conditions: # Is computer checking in. If it's unavailable then it's turned off.
  - condition: state
    entity: sensor.pchostname_palworld_versionc_usernotificationstate
    state_not: unavailable
card:
  square: false
  type: grid
  cards:
    - type: entities
      entities:
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is not running.
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state_not: '1'
          row:
            type: text
            name: 'PalServer-Win64-Test-CMD:'
            text: Not Running :(
            icon: mdi:server
        - type: conditional
          conditions:
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            type: text
            name: 'PalServer-Win64-Test-CMD:'
            text: Running
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer.exe is not running.
            - entity: sensor.pchostname_processactive_palserver
              state_not: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Not Running :(
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer.exe is running.
            - entity: sensor.pchostname_processactive_palserver
              state: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Running
            icon: mdi:server
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running.
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_server_name
            icon: mdi:rename
            name: Server Name
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show todays theme sensor.
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_todays_theme
            icon: mdi:rename
            name: Todays Theme
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show version sensor
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_version
            icon: mdi:update
            name: Version
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show updatecheck status sensor
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_update_available
            icon: mdi:update
            name: Update Status
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, showplayers who online
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_players
            name: Players
            icon: mdi:bug-play-outline
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is running, show count of players who are online
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: sensor.pchostname_palworld_player_count
            name: Player Count
            icon: mdi:counter
      title: PalWorld Server Status
    - type: entities
      entities:
        - type: conditional
          conditions: # If PalServer-Win64-Test-CMD.exe is not running and steam CMD is not running (ie, not in the middle of an update), show the start server button, 
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state_not: '1'
            - entity: sensor.pchostname_processactive_steamcmd
              state_not: '1'
          row:
            entity: button.pchostname_palworldstartserver
            name: Start Server
            icon: mdi:controller
        - type: conditional
          conditions: # If there's an update available, server is online and not currently updating, show update button
            - entity: sensor.pchostname_palworld_update_available
              state: Update Available!
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
            - entity: sensor.pchostname_processactive_steamcmd
              state_not: '1'
          row:
            entity: button.pchostname_palworldupdateserver
            name: Update and Restart Server
            icon: mdi:update
        - type: conditional
          conditions: # If server is running, show this stop button
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.pchostname_palworldstopservergracefully30
            name: Stop Server Gracefully (30 Seconds)
            icon: mdi:hand-back-right
        - type: conditional
          conditions: # If server is running, show this stop button
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.pchostname_palworldstopservergracefully10
            name: Stop Server Gracefully (10 Seconds)
            icon: mdi:hand-back-right
        - type: conditional
          conditions: # If server is running, show this stop now button
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.pchostname_palworldstopservernow
            name: Stop Server NOW
            icon: mdi:octagon
        - type: conditional
          conditions: # If server is running, show this Save button
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            entity: button.pchostname_palworldsaveserver
            name: Save Server
            icon: mdi:content-save
        - type: conditional
          conditions: # if steamcmd process is active, server must be updating.
            - entity: sensor.pchostname_processactive_steamcmd
              state: '1'
          row:
            type: text
            name: 'PalServer:'
            text: Server Updating
            icon: mdi:update
        - type: conditional
          conditions: # I haven't figured out a way to send broadcasts yet, I'll probably investigate once Palworld devs resolve the bug with server messages not allowing space characters.
            - entity: sensor.pchostname_processactive_palserverwin64testcmd
              state: '1'
          row:
            type: text
            name: Broadcast message
            text: Feature coming soon!
            icon: mdi:bullhorn
      title: Palworld Server Controls
  columns: 1
```
