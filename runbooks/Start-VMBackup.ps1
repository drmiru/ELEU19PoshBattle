param(
    [string]$vaultName,
    [string]$vmName
)

$errorActionPreference = 'stop'

# Get Azure Run As Connection Name
$connectionName = "AzureRunAsConnection"
# Get the Service Principal connection details for the Connection name
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

# Logging in to Azure AD with Service Principal
$null = Connect-AzAccount -TenantId $servicePrincipalConnection.TenantId -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint


# Check if we have an azure context
$AzContext = Get-AzContext -ErrorAction SilentlyContinue
if (-not $AzContext.Subscription.Id)
{
     Throw ("No azure context found. Check Permissions on subscription / Enable MSI or use a custom login credential")
}

#set the context to the correct recovery vault
Get-AzRecoveryServicesVault -Name $vaultName | Set-AzRecoveryServicesVaultContext

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
return $job