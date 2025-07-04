<!-- BEGIN_TF_DOCS -->
# Deploy a virtual network with a pre-defined subnet

This template allows you to deploy a simple virtual network with a pre-defined subnet.

```hcl
locals {
  shared_key = sensitive("shared_key")
}

resource "random_id" "id" {
  byte_length = 4
}

locals {
  location = "swedencentral"
}

resource "azurerm_resource_group" "rg" {
  location = local.location
  name     = "rg-vnetgateway-${random_id.id.hex}-01"
}

resource "azurerm_resource_group" "rg_two" {
  location = local.location
  name     = "rg-vnetgateway-${random_id.id.hex}-02"
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "vnet-prod"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "gateway_subnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "public_ip" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg.location
  name                = "pip-${random_id.id.hex}-02"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

module "vgw_vpn" {
  source = "../.."

  location  = local.location
  name      = "vgw-vpn-${random_id.id.hex}"
  parent_id = azurerm_resource_group.rg.id
  ip_configurations = {
    "ip_config_01" = {
      name            = "vnetGatewayConfig01"
      apipa_addresses = ["169.254.21.1"]
    },
    "ip_config_02" = {
      name            = "vnetGatewayConfig02"
      apipa_addresses = ["169.254.21.2"]
      public_ip = {
        creation_enabled = false
        id               = azurerm_public_ip.public_ip.id
      }
    }
  }
  local_network_gateways = {
    gateway-uks = {
      name                = "lgw-gateway"
      resource_group_name = azurerm_resource_group.rg_two.name
      gateway_address     = "1.1.1.1"
      address_space       = ["196.0.0.0/16"]
      connection = {
        type       = "IPsec"
        shared_key = local.shared_key
      }
    }
  }
  sku                               = "VpnGw1AZ"
  subnet_creation_enabled           = false
  type                              = "Vpn"
  virtual_network_gateway_subnet_id = azurerm_subnet.gateway_subnet.id
  vpn_active_active_enabled         = true
  vpn_bgp_enabled                   = true
}

module "vgw_er" {
  source = "../.."

  location  = local.location
  name      = "vgw-ex-${random_id.id.hex}"
  parent_id = azurerm_resource_group.rg.id
  ip_configurations = {
    ip_config_01 = {
      name = "vnetGatewayConfig01"
    }
  }
  sku                               = "ErGw1AZ"
  subnet_creation_enabled           = false
  type                              = "ExpressRoute"
  virtual_network_gateway_subnet_id = azurerm_subnet.gateway_subnet.id
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

- [azurerm_public_ip.public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.rg_two](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_subnet.gateway_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) (resource)
- [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### <a name="output_test"></a> [test](#output\_test)

Description: The ID of the subnet for the virtual network gateway.

## Modules

The following Modules are called:

### <a name="module_vgw_er"></a> [vgw\_er](#module\_vgw\_er)

Source: ../..

Version:

### <a name="module_vgw_vpn"></a> [vgw\_vpn](#module\_vgw\_vpn)

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

Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. The module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to [Sem Ver](https://semver.org/)
<!-- END_TF_DOCS -->