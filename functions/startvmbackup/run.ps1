using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$vmName = $Request.Query.vmName
if (-not $vmName) {
    $vmName = $Request.Body.vmName
}
$vaultName = $Request.Query.vaultName
if (-not $vaultName) {
    $vaultName = $Request.Body.vaultName
}

if ($vmName -and $vaultName) {
    
    # Check if we have an azure context
    try {
        $AzContext = Get-AzContext -ErrorAction SilentlyContinue
    }
    catch {}    
    if (-not $AzContext.Subscription.Id)
    {
         $body = "No azure context found. Check Permissions on subscription / Enable MSI or use a custom login credential"
         $status = [HttpStatusCode]::BadRequest     
    }
    
    #set the context to the correct recovery vault
    try {
        Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext
    }
    catch {
        $body = $_.Exception.Message
        $status = [HttpStatusCode]::BadRequest
    }
    
    try {    
        #get the backup container
        $backupcontainer = Get-AzRecoveryServicesBackupContainer `
            -ContainerType "AzureVM" `
            -FriendlyName $vmName
        
        #get the backup item
        $item = Get-AzRecoveryServicesBackupItem `
            -Container $backupcontainer `
            -WorkloadType "AzureVM"
        
        #initiate ad-hoc backup job
        $job = Backup-AzRecoveryServicesBackupItem -Item $item | convertto-json

        $status = [HttpStatusCode]::OK
        $body = $job
    }
    catch {
        $body = $_.Exception.Message
        $status = [HttpStatusCode]::BadRequest
    }
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass vmName and vaultName parameter values on the query string or in the request body."
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
