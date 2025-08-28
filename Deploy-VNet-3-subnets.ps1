<#
Usage example:
.\Deploy-VNet.ps1 -ResourceGroupName "rg-vnet-demo" -Location "eastus" -TemplateFile ".\vnet-three-subnets.json"
#>

param(
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$false)][string]$Location = "eastus",
    [Parameter(Mandatory=$false)][string]$TemplateFile = ".\vnet-three-subnets.json",
    [string]$VNetName = "myVNet",
    [string[]]$VNetAddressPrefixes = @("10.0.0.0/16"),
    [string]$Subnet1Name = "subnet-1",
    [string]$Subnet1Prefix = "10.0.1.0/24",
    [string]$Subnet2Name = "subnet-2",
    [string]$Subnet2Prefix = "10.0.2.0/24",
    [string]$Subnet3Name = "subnet-3",
    [string]$Subnet3Prefix = "10.0.3.0/24"
)

# Security note: Do NOT hardcode credentials. Use Connect-AzAccount or managed identity.
try {
    # Ensure Az module loaded
    if (-not (Get-Module -ListAvailable -Name Az)) {
        Write-Error "Az PowerShell module not found. Install-Module -Name Az -Scope CurrentUser"
        exit 1
    }

    # Authenticate if required
    if (-not (Get-AzContext)) {
        Connect-AzAccount -ErrorAction Stop
    }

    # Create resource group if it doesn't exist
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Output "Creating resource group '$ResourceGroupName' in '$Location'..."
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
    } else {
        Write-Output "Using existing resource group '$ResourceGroupName' (Location: $($rg.Location))"
    }

    # Build parameter hashtable for deployment
    $templateParams = @{
        vnetName = $VNetName;
        location = $Location;
        vnetAddressPrefixes = $VNetAddressPrefixes;
        subnet1Name = $Subnet1Name;
        subnet1Prefix = $Subnet1Prefix;
        subnet2Name = $Subnet2Name;
        subnet2Prefix = $Subnet2Prefix;
        subnet3Name = $Subnet3Name;
        subnet3Prefix = $Subnet3Prefix;
    }

    Write-Output "Starting template deployment..."
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterObject $templateParams `
        -Verbose -ErrorAction Stop

    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Output "Deployment succeeded."
        $outputs = $deployment.Outputs
        Write-Output "VNet Id: $($outputs.vnetId.value)"
        Write-Output "Subnet1 Id: $($outputs.subnet1Id.value)"
        Write-Output "Subnet2 Id: $($outputs.subnet2Id.value)"
        Write-Output "Subnet3 Id: $($outputs.subnet3Id.value)"
    } else {
        Write-Error "Deployment state: $($deployment.ProvisioningState)"
        exit 1
    }
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    throw
}