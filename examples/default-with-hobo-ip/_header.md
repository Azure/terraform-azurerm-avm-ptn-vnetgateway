# ExpressRoute Virtual Network Gateway with Azure-Managed Public IP Example

This example demonstrates deploying an **ExpressRoute Virtual Network Gateway** using the **Hosted On Behalf Of (HOBO)** public IP feature, where Azure automatically manages the public IP address.

## 🚧 Regional Rollout Notice

> **⚠️ IMPORTANT - Regional Availability**: The HOBO (Hosted On Behalf Of) public IP feature for ExpressRoute Virtual Network Gateways is currently being **rolled out to Azure regions worldwide**. Not all regions have this feature enabled yet.
>
> **Deployment Considerations:**
> - **Regions with HOBO support**: When `hosted_on_behalf_of_public_ip_enabled = true`, Azure ignores any public IP configuration during initial gateway creation
> - **Regions without HOBO support**: You must set `hosted_on_behalf_of_public_ip_enabled = false` and provide explicit public IP resources
> - **Existing gateways**: Attempting to modify public IP configuration on existing ExpressRoute gateways in HOBO-enabled regions may result in "Internal Server Error" from Azure ARM
>
> **Workaround Implementation**: This module includes logic to conditionally exclude public IP assignment when HOBO is enabled, preventing configuration conflicts during subsequent Terraform runs.
>
> **Check regional availability** before deployment by consulting Azure documentation or testing in your target region.

## What is Hosted On Behalf Of Public IP?

The "Hosted On Behalf Of" (HOBO) public IP feature allows Azure to automatically provision and manage the public IP address for your **ExpressRoute Virtual Network Gateway**. This feature is **specifically available for ExpressRoute gateways only**, not VPN gateways.

**Key Benefits:**
- **Automatic IP Management**: Azure provisions the public IP automatically during ExpressRoute gateway creation
- **Simplified Configuration**: No need to pre-create or manage public IP resources for ExpressRoute gateways
- **Cost Optimization**: Reduces the number of resources you need to manage
- **Regional Availability**: Available in supported Azure regions (like UK South used in this example)

> **Important**: This feature is **only available for ExpressRoute Virtual Network Gateways**. VPN gateways still require explicit public IP resource creation and management.

## Key Features Demonstrated

- **Azure-Managed Public IP**: No need to create or manage public IP resources for ExpressRoute gateways
- **ExpressRoute-Specific**: HOBO feature is only available for ExpressRoute gateways, not VPN gateways
- **Simplified Configuration**: Streamlined Terraform configuration for ExpressRoute deployments
- **Regional Deployment**: Deployed to UK South region
- **Cost Optimization**: Reduced resource management overhead for ExpressRoute scenarios
- **AzAPI Provider**: Uses AzAPI provider for advanced Azure Resource Manager features and future-proofing
