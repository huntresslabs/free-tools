### Powershell script for finding and removing Emotet and Trickbot footholds

This Powershell script is designed to find and remove "common" Emotet and Trickbot footholds (services, scheduled tasks, etc.).

By default, the script will display the service and tasks it finds.

```
C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1
Service: 12345678 (12345678) - c:\12345678.bat
Service: yxyxzeea (NewService1) - c:\NewService1.bat
Task: msnEtcs - c:\task2.bat
Task: msntcs - c:\task1.bat
```

Run with the "remove" argument to remove the services/tasks/files.

```
C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1 delete
Service: 12345678 (12345678) - c:\12345678.bat
VERBOSE: Performing operation "Stop-Service" on Target "12345678 (12345678)".
Attempting to stop c:\12345678.bat...
Removing c:\12345678.bat...
VERBOSE: Performing operation "Remove File" on Target "C:\12345678.bat".
[SC] DeleteService SUCCESS
...
Task: msntcs - c:\task1.bat
Removing c:\task1.bat...
VERBOSE: Performing operation "Remove File" on Target "C:\task1.bat".
SUCCESS: The scheduled task "msntcs" was successfully deleted.
```