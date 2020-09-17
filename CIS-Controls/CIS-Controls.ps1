# Copyright (c) 2020 Huntress Labs, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the Huntress Labs nor the names of its contributors
#      may be used to endorse or promote products derived from this software
#      without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL HUNTRESS LABS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# This script will enable various controls from the CIS Top 20.

$ScriptVersion = "2020 September 17; beta 1"

# Find poorly written code faster with the most stringent setting.
Set-StrictMode -Version Latest

# log file for troubleshooting
$DebugLog = Join-Path $Env:TMP CIS_Controls.log

function Get-TimeStamp {
    return "[{0:yyyy/MM/dd} {0:HH:mm:ss}]" -f (Get-Date)
}

function LogMessage ($msg) {
    Add-Content $DebugLog "$(Get-TimeStamp) $msg"
    Write-Host "$(Get-TimeStamp) $msg"
}

function SetDWordValue ($regKey, $regValue, $valueData) {
    if ( !(New-ItemProperty -Path $regKey -Name $regValue -Value $valueData -PropertyType DWORD -Force) )
    {
        LogMessage($error[0])
    }
}

## Main
LogMessage "Log written to '$DebugLog'"
LogMessage "Script version: '$ScriptVersion'"

##############################################################################
## 6.1 - Network - Detect - Activate Audit Logging
LogMessage "Enabling logon/logoff event auditing"
Auditpol /set /category:"Account Logon" /Success:enable /Failure:enable
Auditpol /set /category:"Logon/Logoff" /Success:enable /Failure:enable

##############################################################################
## 8.6 - Devices - Protect - Configure Devices to Not Auto-Run Content
# Disable removable media autorun
# https://support.microsoft.com/en-us/help/967715/how-to-disable-the-autorun-functionality-in-windows
LogMessage "Disabling removable media autorun"
$PoliciesExplorerKey = "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
SetDWordValue $PoliciesExplorerKey "NoDriveTypeAutorun" 0xFF

##############################################################################
## 8.8 - Devices - Detect - Enable Command-Line Audit Logging
# Log the content of all PowserShell script blocks.
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_logging_windows?view=powershell-7
# LogMessage "Enabling PowerShell script block logging"
# $ScriptBlockLoggingKey = "HKLM:Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
# if ( ! (Test-Path $ScriptBlockLoggingKey) )
# {
#    New-Item -Path "HKLM:Software\Policies\Microsoft\Windows\PowerShell" -Name "ScriptBlockLogging"
# }
# SetDWordValue $ScriptBlockLoggingKey "EnableScriptBlockLogging" 1
# SetDWordValue $ScriptBlockLoggingKey "EnableScriptBlockInvocationLogging" 1

# Command line audit processing
# https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/manage/component-updates/command-line-process-auditing
LogMessage "Enabling command line audit processing"
$AuditKey = "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit"
SetDWordValue $AuditKey "ProcessCreationIncludeCmdLine_Enabled" 1

##############################################################################
## 16: Account Monitoring and Control
# https://support.microsoft.com/en-us/help/2871997/microsoft-security-advisory-update-to-improve-credentials-protection-a
# Clear any credentials of logged off users after delay
# $LsaKey = "HKLM:SYSTEM\CurrentControlSet\Control\Lsa"
# SetDWordValue $LsaKey "TokenLeakDetectDelaySecs" 30

# Prevent WDigest credentials from being stored in memory
# LogMessage "Preventing WDigest credentials from being stored in memory"
# $WDigestKey = "HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest"
# SetDWordValue $WDigestKey "UseLogonCredential" 0
