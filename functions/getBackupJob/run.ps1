using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$jobId = $Request.Query.jobId
if (-not $jobId) {
    $jobId = $Request.Body.jobId
}
$vaultName = $Request.Query.vaultName
if (-not $vaultName) {
    $vaultName = $Request.Body.vaultName
}

if ($jobId -and $vaultName) {
    try {
        #check if we have an azure context
        $AzContext = Get-AzContext -ErrorAction SilentlyContinue
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

        #Get the recovery services backup job
        $result = Get-AzRecoveryServicesBackupJob -JobId $jobId | ConvertTo-Json
    }
    catch {
        $body = $_.Exception.Message
        $status = [HttpStatusCode]::BadRequest     
    }
    $status = [HttpStatusCode]::OK
    $body = $result
}
else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass jobId and vaultName on the query string or in the request body."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
