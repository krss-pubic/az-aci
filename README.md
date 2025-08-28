# az-aci
Use ARM templates and PowerShell to automate deployment of a secure configuration for ACI.

## Deployment Workflow Outline

1. Setup & Context Initialization
    * Use PowerShell Az module for connectivity.
    * Authenticate, and set subscription context.
    * Define all variables and parameters (prefix, location, resource group name, VNet/subnet address spaces, etc.)

2. Create Resource Group
    * Use ARM template
    * Name: ${prefix}-rg
    * Location: EastUS2

3. Create Virtual Network and Subnets
    * Use ARM template.
    * VNet: ${prefix}-vnet with address space, e.g., 10.0.0.0/16
    * Subnet: Deligated Application Gateway subnet: name ${prefix}-agw-subnet, small CIDR e.g., 10.0.0.0/24, with service endpoint for Key Vault
    * Subnet: Deligated Microsoft.ContainerInstance/containerGroups to ACI subnet: ${prefix}-aci-subnet, small CIDR e.g., 10.0.1.0/24
    * Subnet: Miscelaneous subnet for Key Vault Private Endpoint and future resources: ${prefix}-misc-subnet, small CIDR e.g., 10.0.2.0/24
    Note: ACI currently requires a delegated subnet to "Microsoft.ContainerInstance/containerGroups"
    * NAT Gateway: Associated to ACI Subnet (Azure retired default outbound access for Virtual Machines)

4. Create User Assigned Managed Identity (This identity will later be assigned to Application Gateway)
    * Name: ${prefix}-uami
    * Location: EastUS2

5. Prepare Key Vault / Certificate Permissions
    * Dependency on Vnet to create Private Endpoint in ${prefix}-aci-subnet, small CIDR e.g., 10.0.1.0/24
    * Generate Certificate
    * Assign get and list secret permissions for the UAMI on this Key Vault. This ensures the Application Gateway can retrieve the HTTPS certificate.

6. Deploy Application Gateway via ARM Template
    * Use an ARM template for flexibility:
    * Reference the existing UAMI (created previously). https://learn.microsoft.com/en-us/azure/application-gateway/key-vault-certs?WT.mc_id=Portal-Microsoft_Azure_HybridNetworking#key-vault-azure-role-based-access-control-permission-model
    * Integrate HTTPS listener that uses certificate from Key Vault (via UAMI permissions).
    * Deploy into the dedicated subnet (${prefix}-agw-subnet).
    * Set sizing to appropriate SKU (small or medium) since subnets are small.
    * Enable necessary SKU features for HTTPS and WAF if needed.

7. Deploy Azure Container Instance (ACI)
    * Deploy an ACI container group (${prefix}-container) into the subnet ${prefix}-aci-subnet.
    * Use Docker public image openeuler/open-webui.
    * Ensure container networking is set to private VNet.
    * Configure resources as needed – e.g., CPU, memory (small).

8. Configure NSG / Routing
    * Create Network Security Groups for minimum subnet restrictions.
    * Application Gateway subnet can comminicate with ACI subnet
    * ACI subnet can communicate with Application Gateway subnet
    * In production, restrict to IPs instead of CIDR
    * Configure any required user-defined routes.

9. Output and Verify
    * Output all resource IDs and important info to deployment documentation.
    * Verify container is running and accessible behind App Gateway.
    * Test for effect with a test URL and document results to deployment documentation.

