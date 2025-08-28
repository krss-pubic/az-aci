# Variables
$prefix = "test-aci" # Prefix for all created objects
$location = "EastUS2" # Target location for all deployed resources
$subscriptionId = "<subId>" # Subscription specific deployment
$resourceGroupName = "${prefix}-rg"

Connect-AzAccount -UseDeviceAuthentication
Set-AzContext -Subscription $subscriptionId

# Network details
$vnetName = "${prefix}-vnet"
$vnetAddressSpace = "10.0.0.0/16"
$agwSubnetName = "${prefix}-agw-subnet"
$agwSubnetPrefix = "10.0.0.0/24"
$aciSubnetName = "${prefix}-aci-subnet"
$aciSubnetPrefix = "10.0.1.0/24"
$miscSubnetName = "${prefix}-aci-subnet"
$miscSubnetPrefix = "10.0.2.0/24"

# User Assigned Managed Identity name
$uamiName = "${prefix}-uami"

# Preexisting Key Vault info
$keyVaultName = "${prefix}-kv"     
$keyVaultResourceGroup = $resourceGroupName 

