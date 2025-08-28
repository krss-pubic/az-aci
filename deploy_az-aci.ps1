# Variables
$prefix = "test-aci" # Prefix for all created objects
$location = "EastUS2" # Target location for all deployed resources
$subscriptionId = "89382f9a-deac-49be-a1af-9a3a8d7ceed3" # Subscription specific deployment
$resourceGroupName = "${prefix}-rg"

# Connect-AzAccount -UseDeviceAuthentication
Set-AzContext -Subscription $subscriptionId

$vnetName = "${prefix}-vnet" # Network details
$vnetAddressSpace = "10.0.0.0/16"
$agwSubnetName = "${prefix}-agw-subnet" # Required delegated AGW subnet
$agwSubnetPrefix = "10.0.0.0/24"
$aciSubnetName = "${prefix}-aci-subnet" # Required delegated ACI subnet
$aciSubnetPrefix = "10.0.1.0/24"
$miscSubnetName = "${prefix}-misc-subnet" # Used for Key Vault and other objects
$miscSubnetPrefix = "10.0.2.0/24"
$uamiName = "${prefix}-uami" # User Assigned Managed Identity name

# Preexisting Key Vault info
$keyVaultName = "${prefix}-kv"     
$keyVaultResourceGroup = $resourceGroupName 

# 1. Create Resource Group
Write-Host "Creating Resource Group: $resourceGroupName"
$rg = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    $rg = New-AzResourceGroup -Name $resourceGroupName -Location $location
} else {
    Write-Host "Resource Group $resourceGroupName already exists"
}

# 2. Create Virtual Network with Subnets and Delegation for ACI subnet
Write-Host "Creating Virtual Network and Subnets"

# Prepare subnet configurations including delegation for ACI subnet
$aciDelegation = New-Object -TypeName Microsoft.Azure.Commands.Network.Models.PSDelegation
$aciDelegation.Name = "aci-delegation"
$aciDelegation.ServiceName = "Microsoft.ContainerInstance/containerGroups"

$agwSubnet = New-AzVirtualNetworkSubnetConfig -Name $agwSubnetName -AddressPrefix $agwSubnetPrefix
$aciSubnet = New-AzVirtualNetworkSubnetConfig -Name $aciSubnetName -AddressPrefix $aciSubnetPrefix -Delegations $aciDelegation

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
if (-not $vnet) {
    $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressSpace -Subnet $agwSubnet, $aciSubnet
} else {
    Write-Host "Virtual Network $vnetName already exists"
}

# 3. Create User Assigned Managed Identity (UAMI)
Write-Host "Creating User Assigned Managed Identity: $uamiName"
$uami = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $uamiName -ErrorAction SilentlyContinue
if (-not $uami) {
    $uami = New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $uamiName -Location $location
} else {
    Write-Host "User Assigned Managed Identity $uamiName already exists"
}

# 4. Assign Key Vault Access Policies to UAMI
Write-Host "Assigning Key Vault Access Policies to UAMI"

$keyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $keyVaultResourceGroup
if (-not $keyVault) {
    throw "Key Vault $keyVaultName not found in resource group $keyVaultResourceGroup"
}

# Prepare permission properties - we want 'get' and 'list' for secrets (certificates are accessed as secrets)
$permToAdd = @("get", "list")

# Check if access policy already exists for our UAMI
$existingPolicy = $keyVault.AccessPolicies | Where-Object { $_.ObjectId -eq $uami.PrincipalId }
if (-not $existingPolicy) {
    # Add new access policy for UAMI principalId for secret permissions
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -ResourceGroupName $keyVaultResourceGroup -ObjectId $uami.PrincipalId `
        -PermissionsToSecrets $permToAdd -PassThru
    Write-Host "Access policy assigned to UAMI on Key Vault"
} else {
    Write-Host "Key Vault access policy already exists for UAMI"
}