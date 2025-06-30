## Important Notes

- **ExpressRoute Only**: This feature is **exclusively available for ExpressRoute Virtual Network Gateways**, not VPN gateways
- This feature must be configured during initial ExpressRoute gateway deployment
- The public IP address is managed by Azure and not visible as a separate resource in your subscription
- **AzAPI Provider**: This example uses the AzAPI provider for direct access to Azure ARM REST APIs and advanced properties

## HOBO Regional Rollout - Important Mitigation

### 500 Internal Server Error Issue

If you encounter a **500 Internal Server Error** when running `terraform plan` or `terraform apply` on existing ExpressRoute gateways, this is likely due to the HOBO feature being rolled out to your region after your gateway was initially deployed.

**Root Cause**: Terraform attempts to add a public IP configuration to an existing ExpressRoute gateway in a HOBO-enabled region, which Azure rejects with an internal server error.

### Mitigation Steps for Existing Gateways

If you have an existing ExpressRoute gateway deployed before HOBO rollout in your region:

1. **Update your configuration** to enable HOBO:
   ```hcl
   module "vgw" {
     source = "../.."

     type = "ExpressRoute"
     hosted_on_behalf_of_public_ip_enabled = true  # Add this line
     # Remove any explicit public IP configurations
   }
   ```

2. **Plan and apply** the changes - the module will automatically handle the public IP removal and destruction when HOBO is enabled.

For more information about Azure Virtual Network Gateway configuration options, see the [main module documentation](../../README.md).

# Usage

Ensure you have Terraform installed and the Azure CLI authenticated to your Azure subscription.

Navigate to the directory containing this configuration and run:

```pwsh
terraform init
terraform plan
terraform apply
```
<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.

## AVM Versioning Notice

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to [Sem Ver](https://semver.org/)
