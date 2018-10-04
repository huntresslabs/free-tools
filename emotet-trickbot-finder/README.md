### Powershell script for finding and removing Emotet and Trickbot footholds

This Powershell script is designed to find and remove "common" Emotet and Trickbot footholds (services, scheduled tasks, etc.).

By default, the script will display the service and tasks it finds.

```
C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1
[*] Looking for process by name: mssvca
[*] Process: mssvca.exe (mssvca) - c:\windows\mssvca.exe

Name       Used (GB)     Free (GB) Provider      Root                                CurrentLocation
----       ---------     --------- --------      ----                                ---------------
HKU                                Registry      HKEY_USERS
[*] Found registry value: mttvca
[*] Service: 12345678 (12345678) - c:\12345678.exe
[*] Service: yxyxzeea (NewService1) - c:\NewService1.bat
[*] Task: msnEtcs - c:\task2.bat
[*] Task: msntcs - c:\task1.bat
```

Run with the "remove" argument to remove the services/tasks/files.

```
C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1 remove
[*] Looking for process by name: mssvca
[*] Process: mssvca.exe (mssvca) - c:\windows\mssvca.exe
VERBOSE: Performing operation "Stop-Process" on Target "mssvca (3320)".
[!] Removing c:\windows\mssvca.exe...
VERBOSE: Performing operation "Remove File" on Target "C:\windows\mssvca.exe".

Name       Used (GB)     Free (GB) Provider      Root                                 CurrentLocation
----       ---------     --------- --------      ----                                 ---------------
HKU                                Registry      HKEY_USERS
[*] Found registry value: mttvca
[!] Removing registry value: mttvca
VERBOSE: Performing operation "Remove Property" on Target "Item:
HKEY_USERS\S-1-5-18\software\Microsoft\Windows\CurrentVersion\Run Property: mttvca".
[*] Attempting to terminate process based on file path: 'c:\stsvc.exe'...
VERBOSE: Performing operation "Stop-Process" on Target "stsvc (892)".
[!] Removing c:\stsvc.exe...
VERBOSE: Performing operation "Remove File" on Target "C:\stsvc.exe".
[*] Service: 12345678 (12345678) - c:\12345678.exe
VERBOSE: Performing operation "Stop-Service" on Target "12345678 (12345678)".
[*] Attempting to terminate process based on file path: 'c:\12345678.exe'...
VERBOSE: Performing operation "Stop-Process" on Target "12345678 (3884)".
[!] Removing c:\12345678.exe...
VERBOSE: Performing operation "Remove File" on Target "C:\12345678.exe".
[!] Deleting service: 12345678
[SC] DeleteService SUCCESS
[*] Service: yxyxzeea (NewService1) - c:\NewService1.bat
VERBOSE: Performing operation "Stop-Service" on Target "NewService1 (yxyxzeea)".
[*] Attempting to terminate process based on file path: 'c:\NewService1.bat'...
[!] Removing c:\NewService1.bat...
VERBOSE: Performing operation "Remove File" on Target "C:\NewService1.bat".
[!] Deleting service: yxyxzeea
[SC] DeleteService SUCCESS
[*] Task: msnEtcs - c:\task2.bat
[*] Attempting to terminate process based on file path: 'c:\task2.bat'...
[!] Removing c:\task2.bat...
VERBOSE: Performing operation "Remove File" on Target "C:\task2.bat".
[!] Deleting scheduled task: msnEtcs
SUCCESS: The scheduled task "msnEtcs" was successfully deleted.
[*] Task: msntcs - c:\task1.bat
[*] Attempting to terminate process based on file path: 'c:\task1.bat'...
[!] Removing c:\task1.bat...
VERBOSE: Performing operation "Remove File" on Target "C:\task1.bat".
[!] Deleting scheduled task: msntcs
SUCCESS: The scheduled task "msntcs" was successfully deleted.
```
