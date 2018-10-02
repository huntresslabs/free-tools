# Powershell script to remove Emotet and Trickbot services and scheduled
# tasks.

# If you have an active Emotet/Trickbot infection you'll want to stop
# the spread before running this script.


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

# C:\Users\admin> powershell -executionpolicy bypass -f emotet_trickbot_finder.ps1 delete
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

# various files to remove
$filesToRemove = @(
    'c:\stsvc.exe'
)

# Run Key values to remove, string matching
$valueNameMatches = @(
    'mttvca'
)

# service to remove
$badSvcs = @()

# Add Emotet numbered services
$badSvcs += Get-Service | ? { $_.name -match '^[0-9]{6,20}$' }

# Add Trickbot services, match the display name
$badSvcs += Get-Service | ? { $_.DisplayName -match '^NewService' }
$badSvcs += Get-Service | ? { $_.DisplayName -match '^Service-Log' }

# Trickbot tasks regex
$badTasks = 'msnetcs|msntcs'

##############################################################################
## helper functions

function deleteFile ($file) {
    if (Test-Path $file) {
        Write-Output "Removing $file..."
        Remove-Item $file -Force -Confirm:$false -Verbose -ErrorAction SilentlyContinue
    }
}

# terminate the process associated with the specified file
function terminateProcess ($file) {
    if ($file -ne $null) {
        Write-Output "Attempting to terminate process based on file path: '$file'..."
        Get-Process | ? { $_.Path -eq $file } | Stop-Process -Force -Confirm:$false -Verbose
    }
}

function removeRegistryValues() {
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
    foreach ($v in $valueNameMatches) {
        $value = (Get-item HKU:\S-1-5-18\software\microsoft\windows\currentversion\run).property | ? { $_ -match $v }
        if ($value -ne $null) {
            Write-Output "Found registry value: $value"
            if ($remove -eq "remove") {
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
    # Iterate over the services we found
    foreach ($bSvc in $badSvcs) {
        if ($bSvc -eq $null) { continue }

        $svcWmiObj = gwmi Win32_Service | ? { $_.name -eq $bSvc.name }
        if ($svcWmiObj -ne $null ) { $svcPath = $svcWmiObj | select -expand pathname -ErrorAction SilentlyContinue }

        Write-Output "Service: $($bSvc.Name) ($($bSvc.DisplayName)) - $svcPath"

        if ($remove -eq "remove") {
            $bSvc | Stop-Service -Force -Verbose -ErrorAction SilentlyContinue
            Start-Sleep 1

            terminateProcess $svcPath

            Start-Sleep -Seconds 2

            deleteFile $svcPath

            cmd.exe /C sc.exe delete $bSvc.name

            remove-variable svcWmiObj,svcPath
        }
    }
}

function removeTasks() {
    $AllSchedTasks = schtasks.exe /QUERY /V /FO CSV | ConvertFrom-CSV | ? { $_.TaskName -match $badTasks }
    foreach ($stask in $allSchedTasks) {
        if ($stask -eq $null) { continue }

        $binToDel = $stask.'Task To Run'.Trim()

        Write-Output "Task: $($stask.taskname.split('\')[-1]) - $binToDel"

        if ($remove -eq "remove") {
            terminateProcess $binToDel

            deleteFile $binToDel

            schtasks.exe /DELETE /TN $stask.taskname.split('\')[-1] /F
        }
    }
}

##############################################################################
## MAIN

Get-Process | ? { $_.Path -match '\\mttvca\.exe' } | Stop-Process -Force -Verbose
Get-Process | ? { $_.Path -match '\\mssvca\.exe' } | Stop-Process -Force -Verbose
Get-Process | ? { $_.Path -match '\\stsvc\.exe' } | Stop-Process -Force -Verbose

removeRegistryValues
removeFiles
removeServices
removeTasks
