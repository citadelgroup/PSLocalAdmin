$Name = "breakglassadmin"
$FunctionEndpoint = "https://exampleapp.azurewebsites.net/api/HttpTrigger"
$APIKey = "blahblahblah"
$ResetPeriod = 30

$dir = "C:\ProgramData\InTuneScripts"
New-Item -ItemType Directory -Path $dir

$acl = Get-Acl $dir
$acl.SetAccessRuleProtection($True, $True)
Set-Acl -Path $dir -AclObject $acl

$acl = Get-Acl $dir
$acl.PurgeAccessRules((New-Object System.Security.Principal.Ntaccount("CREATOR OWNER")))
$acl.PurgeAccessRules((New-Object System.Security.Principal.Ntaccount("BUILTIN\Users")))
Set-Acl -Path $dir -AclObject $acl

$text = @"
$dir\CheckLocalAdmin.ps1 -Name $Name -FunctionEndpoint $FunctionEndpoint -APIKey $APIKey -ResetPeriod $ResetPeriod
"@
Set-Content -Path "$dir\CheckLocalAdmin-wrapper.ps1" -Value $text

$url = "https://github.com/citadelgroup/PSLocalAdmin/blob/master/LocalScript/Windows/CheckLocalAdmin.ps1"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest $url -OutFile "$dir\CheckLocalAdmin.ps1"

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                  -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File ""$dir\CheckLocalAdmin-wrapper.ps1.ps1"""
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hour 1) `
                                         -MultipleInstances IgnoreNew
Register-ScheduledTask -Action $action `
                       -Trigger $trigger `
                       -Settings $settings `
                       -User 'NT AUTHORITY\SYSTEM' `
                       -TaskName "CheckLocalAdmin" `
                       -Description "Checks local admin accounts"