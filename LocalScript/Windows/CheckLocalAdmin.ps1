<#
.SYNOPSIS
    Checks for the existance of a specific local admin, and create if required.

.DESCRIPTION
    Checks for the existance of a specific local admin, and create if required.
    Will also change the password and ensure the account is a member of the local administrator group.

    See: https://github.com/citadelgroup/PSLocalAdmin

.PARAMETER Name
    String name of the account

.PARAMETER FunctionEndpoint
    String name of the Azure Function to return password

.PARAMETER APIKey
    String containing the APIKey for connecting to the Azure Function

.PARAMETER ResetPeriod
    Int32 containing the number of days before a password should be changed

.EXAMPLE
    CheckLocalAdmin.ps1 -Name "breakglassadmin" -FunctionEndpoint "https://exampleapp.azurewebsites.net/api/HttpTrigger" -APIKey "key" 

.NOTES
    AUTHOR: Daniel Snelling
    LASTEDIT: Jul 2, 2019
#>

param(
    [parameter(Mandatory=$False)]
    [string] $Name = "breakglassadmin",
    
    [parameter(Mandatory=$True)]
    [string] $FunctionEndpoint,
    
    [parameter(Mandatory=$True)]
    [string] $APIKey,
    
    [parameter(Mandatory=$False)]
    [Int32] $ResetPeriod = 30
)

$user = Get-LocalUser -Name $Name -ErrorAction $SilentlyContinue

if($user) {
    if($user.PasswordLastSet -and ($user.PasswordLastSet).AddDays($ResetPeriod) -lt (Get-Date)) {
        $ChangePassword = $true
    }

    if(((Get-LocalGroupMember -Name Administrators).Name.Where({$_ -eq "$($env:COMPUTERNAME)\$($Name)"})).Count -eq 0) {
        $MakeAdmin = $true
    }
}
else {
    $CreateUser = $true
}

if($CreateUser -or $ChangePassword) {
    # Build Headers and Body
    $headers = @{ "x-functions-key" = $APIKey }
    $body = @{
        Name = "$env:COMPUTERNAME"
    } | ConvertTo-Json

    # Use TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Trigger Azure Function
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
    }
    catch {
        Write-Error "Error calling Azure Function. StatusCode: $($_.Exception.Response.StatusCode.value__). StatusDescription: $($_.Exception.Response.StatusDescription)"
    }

    $password = ConvertTo-SecureString $response -AsPlainText -Force

    if($CreateUser) {
        New-LocalUser -Name $Name -Password $password -PasswordNeverExpires $true -AccountNeverExpires $true -ErrorAction Stop
    }
    elseif($ChangePassword) {
        Set-LocalUser -Name $Name -Password $password -PasswordNeverExpires $true -AccountNeverExpires $true
    }
}

if($CreateUser -or $MakeAdmin) {
    Add-LocalGroupMember -Group "Administrators" -Member $Name
}
