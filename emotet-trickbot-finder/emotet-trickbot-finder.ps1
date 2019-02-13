# Powershell script to remove Emotet and Trickbot services and scheduled
# tasks.

# If you have an active Emotet/Trickbot infection, you'll want to stop
# the spread before running this script.

# This script is based on the work of the Bytes Computer & Network Solutions team.

# This is free and unencumbered software released into the public domain.

# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.

# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# For more information, please refer to <http://unlicense.org/>

# By default, the script will display the service and tasks it finds.
# Run with the "remove" argument to remove the services/tasks/files.

# C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1
# Service: 12345678 (12345678) - c:\12345678.bat
# Service: yxyxzeea (NewService1) - c:\NewService1.bat
# Task: msnEtcs - c:\task2.bat
# Task: msntcs - c:\task1.bat

# C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1 remove
# Service: 12345678 (12345678) - c:\12345678.bat
# VERBOSE: Performing operation "Stop-Service" on Target "12345678 (12345678)".
# Attempting to stop c:\12345678.bat...
# Removing c:\12345678.bat...
# VERBOSE: Performing operation "Remove File" on Target "C:\12345678.bat".
# [SC] DeleteService SUCCESS
# ...
# Task: msntcs - c:\task1.bat
# Removing c:\task1.bat...
# VERBOSE: Performing operation "Remove File" on Target "C:\task1.bat".
# SUCCESS: The scheduled task "msntcs" was successfully deleted.

# command line argument for removing the services/tasks/files
Param([String]$remove)

# simplistic versioning
$revisionDate = '13 February 2019'

##############################################################################
## Add known Emotet/Trickbot files, services, scheduled tasks, etc. below

# Known Trickbot file names to remove
$filesToRemove = @(
    'c:\stsvc.exe',
    'c:\mswvc.exe',
    'c:\mtwvc.exe',
    'c:\smver.exe'
)

# Run Key values to remove, string matching
$valueNameMatches = @(
    'mttvca'
)

# services to remove, initialize array
$badServices = @()

# Add Emotet numbered services
$badServices += Get-Service | ? { $_.name -match '^[0-9]{6,20}$' }

# Add Trickbot services, match the display name
$badServices += Get-Service | ? { $_.DisplayName -match '^NewService' }
$badServices += Get-Service | ? { $_.DisplayName -match '^Service-Log' }
# **** Add the service commands we send here ****

# processes to terminate, initialize array
$badProcesses = @()

# add known Emotet/Trickbot processes
$badProcesses += Get-Process | ? { $_.Path -match '\\mttvca\.exe' }
$badProcesses += Get-Process | ? { $_.Path -match '\\mssvca\.exe' }
$badProcesses += Get-Process | ? { $_.Path -match '\\mswvc\.exe' }
$badProcesses += Get-Process | ? { $_.Path -match '\\mtwvc\.exe' }

# Trickbot scheduled task names regex
$badTasks = 'msnetcs|msntcs|sysnetsf|MsSystemWatcher|netsys|WinDotNet|CleanMemoryWinTask|DefragWinSysTask'



##############################################################################
## helper functions

function deleteFile ($file) {
    # only delete files
    if (Test-Path -PathType Leaf $file) {
        Write-Output "[!] Removing file '$file'..."
        Remove-Item $file -Force -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    }
}

# terminate the process associated with the specified file
function terminateProcess ($file) {
    if (($file -ne $null) -and (Test-Path -PathType Leaf $file)) {
        Write-Output "[*] Attempting to terminate process based on file path: '$file'..."
        Get-Process | ? { $_.Path -eq $file } | Stop-Process -Force -Confirm:$false -Verbose
    }
}

function removeRegistryValues() {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
    foreach ($v in $valueNameMatches) {
        $value = (Get-item HKU:\S-1-5-18\software\microsoft\windows\currentversion\run).property | ? { $_ -match $v }
        if ($value -ne $null) {
            Write-Output "[*] Found registry value: $value"
            if ($remove -eq "remove") {
                Write-Output "[!] Removing registry value: $value"
                Remove-ItemProperty HKU:\S-1-5-18\software\Microsoft\Windows\CurrentVersion\Run -Name $value -Verbose -Force -Confirm:$false
            }
        }
    }
}

function removeFiles(){
    foreach ($f in $filesToRemove) {
        if ($remove -eq "remove") {
            terminateProcess $f
            deleteFile $f
        }
    }
}

function removeServices() {
    foreach ($bSvc in $badServices) {
        if ($bSvc -eq $null) { continue }

        # get Win32_Service object matching on the service name
        $svcWmiObj = gwmi Win32_Service | ? { $_.name -eq $bSvc.name }

        if ($svcWmiObj -ne $null ) {
            $svcPath = $svcWmiObj | select -expand pathname -ErrorAction SilentlyContinue
            # $svcPath = $($svcWmiObj.PathName)

            Write-Output "[*] Service: $($bSvc.Name) ($($bSvc.DisplayName)) - file: '$svcPath'"

            if ($remove -eq "remove") {
                $bSvc | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue
                Start-Sleep 1

                if ($svcPath -ne $null) {
                    terminateProcess $svcPath

                    Start-Sleep -Seconds 2

                    deleteFile $svcPath
                    remove-variable svcPath
                }

                Write-Output "[!] Deleting service: $($bSvc.Name)"
                cmd.exe /C sc.exe delete $bSvc.name
            } # end "remove"

            remove-variable svcWmiObj
        }
    } # end foreach
}

function removeTasks() {
    $AllSchedTasks = schtasks.exe /QUERY /V /FO CSV | ConvertFrom-CSV | ? { $_.TaskName -match $badTasks }
    foreach ($stask in $AllSchedTasks) {
        if ($stask -eq $null) { continue }

        $binToDel = $stask.'Task To Run'.Trim()

        Write-Output "[*] Task: $($stask.taskname.split('\')[-1]) - $binToDel"

        if ($remove -eq "remove") {
            if ($binToDel -ne $null) {
                terminateProcess $binToDel

                deleteFile $binToDel
            }

            Write-Output "[!] Deleting scheduled task: $($stask.taskname.split('\')[-1])"
            schtasks.exe /DELETE /TN $stask.taskname.split('\')[-1] /F
        }
    }
}

function removeProcesses() {
    foreach($bProc in $badProcesses) {
        if ($bProc -eq $null) { continue }

        Write-Output "[*] Looking for process by name: $($bProc.ProcessName)"

        # get Win32_Process object matching on the process name
        $procWmiObj = gwmi Win32_Process | ? { $_.Name -match $bProc.ProcessName }
        if ($procWmiObj -ne $null ) {
            Write-Output "[*] Process: $($procWmiObj.Name) ($($bProc.ProcessName)) - $($procWmiObj.ExecutablePath)"

            if ($remove -eq "remove") {
                $bProc | Stop-Process -Force -Verbose -ErrorAction SilentlyContinue
                Start-Sleep 1

                if ($procWmiObj.ExecutablePath -ne $null) {
                    deleteFile $procWmiObj.ExecutablePath
                }

                remove-variable procWmiObj
            }
        }
    }
}

##############################################################################
## MAIN

Write-Output "Hostname: $env:computername"
Write-Output "Script revision: $revisionDate"

removeProcesses
removeRegistryValues
removeFiles
removeServices
removeTasks
