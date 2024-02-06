# Overview
Task scheduler is of course a very handy tool for automating actions when conditions are met.<br>
Here's some things you can achieve using Task Scheduler to launch PalworldServerTools.

## Launch Server on boot and restart at midnight
This tells the script to launch. The absence of the parameter "-noupdate" means it will also check for updates and install on launch (if there are any available).
Example setup below:
1. General<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/dd38b96f-0c47-451b-bd9e-023363cc5c52)<br>
2. Triggers<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/da21da3c-6e8f-42c0-88f6-f947f4cc8e06)<br>
3. Actions<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/1d743575-75b3-4502-8ca1-594893483225)<br>
4. Conditions<br>
Default settings.<br>
5. Settings<br>
![image](https://github.com/shupershuff/PalworldServerTools/assets/63577525/c43acf32-842d-4196-b12b-9f55b078d856)<br>

## Backup Server
Setup Task Scheduler with another task to run the script with the parameter -backup.
Recommend setting this up to run every hour.
