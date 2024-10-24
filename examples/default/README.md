<!-- BEGIN_TF_DOCS -->
# Default Example

This code sample shows how to create the resources using default settings.

```hcl
resource "random_id" "id" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  location = "uksouth"
  name     = "rg-vnetgateway-${random_id.id.hex}"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = "vnet-uksouth-prod"
  resource_group_name = azurerm_resource_group.rg.name
}

module "vgw" {
  source = "../.."

  location              = "uksouth"
  name                  = "vgw-uksouth-prod"
  subnet_address_prefix = "10.0.1.0/24"
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>=1.2)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_test_public_ip_address_id"></a> [test\_public\_ip\_address\_id](#output\_test\_public\_ip\_address\_id)

Description: The ID of the Public IP Address

### <a name="output_test_virtual_network_gateway_id"></a> [test\_virtual\_network\_gateway\_id](#output\_test\_virtual\_network\_gateway\_id)

Description: The ID of the Virtual Network Gateway

## Modules

The following Modules are called:

### <a name="module_vgw"></a> [vgw](#module\_vgw)

Source: ../..

Version:

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

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to <https://semver.org/>
<!-- END_TF_DOCS -->