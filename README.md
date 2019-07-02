# PSLocalAdmin

Solution for maintaining a breakglass local admin account using Azure Functions and Key Vault.
The existing solution, [LAPS](https://www.microsoft.com/en-us/download/details.aspx?id=46899), only applies to Windows PC's that are attached to a traditional Active Directory domain. The functionality of LAPS can be replicated however, as is the case with this solution.

## Components

On each machine, a script is run periodically. This script checks for the existance of a commonly named admin account 'breakglassadmin'.
If the account doesn't exist, or it's password hasn't changed in a set period (30 days), then a HTTP request is sent to an Azure Function app.
The Azure Function app generates a new password, sends it to an Azure Key Vault for storage, then returns the password to the cilent machine.
The client machine script can then create the local admin account or reset the password.

## Setup

### Azure Function/Key Vault

1. Create new Azure Function app
   * App name should be globally unique
   * OS should be Windows
   * Hosting Plan should be consumption
   * Runtime Stack should be PowerShell Core
2. In the parent function app window, go to Platform features
3. Go to Networking --> Identity
4. In the System assigned tab, set the Status to On. This will create an identity in your Azure AD for the function app
5. In the left pane, create a new Function of type HTTP trigger
   * Name should be HttpTrigger
   * Authorization level should be Function
6. (Optional) I used VS Code with the Azure Function extension to deploy the Azure function code. The main file that needs uploading is run.ps1
7. Create new Azure Key Vault
   * App name should be globally unique
   * Pricing tier should be Standard
   * Access Policies should have no advanced policies checked
   * Access Policies should have a new policies configured
     * Principal should be the name of the Function app create above
     * The only permission required is Secret-->Set
   * Virtual Network Access can remain open

### Local Machine

#### Windows

1. Copy the [CheckLocalAdmin-Bootstrap](https://github.com/citadelgroup/PSLocalAdmin/tree/master/LocalScript/Windows/CheckLocalAdmin-Bootstrap.ps1) script to your PC
2. Edit the 4 variables at the top of the file
3. Deploy the script to every machine you want to manage and run

The bootstrap script will create relevant directories, copy the actual script from the repo top run, and schedule the script to run at logon.

## Versions

### 1.0.0

* Initial release.