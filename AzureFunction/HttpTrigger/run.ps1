using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Script variables
$PWLength = 20
$VaultName = $env:KeyVault

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.name
if (-not $name) {
    $name = $Request.Body.name
}

if ($name) {

    #Create password
    $password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..20 | sort {Get-Random})[0..19] -join ''
    $secretvalue = ConvertTo-SecureString $password -AsPlainText -Force
    
    #Set secret
    $secret = Set-AzKeyVaultSecret -VaultName $VaultName -Name $name -SecretValue $secretvalue

    if($secret) {
        $status = [HttpStatusCode]::OK
        $body = $password
    }
    else {
        $status = [HttpStatusCode]::BadRequest
        $body = ""
    }
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = ""
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
