# terraform-azurerm-vnet-gateway
![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-vnet-gateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-vnet-gateway "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-vnet-gateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-vnet-gateway "Percentage of issues still open")

This module is designed to deploy an Azure Virtual Network Gateway and several auxillary resources associated to it. 

## Features 
- Virtual Network Gateway: 
    - VPN Gateway or ExpressRoute Gateway. 
    - Active-Active or Single.
    - Deployment of `GatewaySubnet`.
- Route Table 
    - Optional deployment of Route Table on the Gateway Subnet.
- Local Network Gateway:
    - Optional deployment of `n` Local Network Gateways.
    - Optional deployment of `n` Virtual Network Gateway Connections for Local Network Gateways. 
- ExpressRoute Circuit:
    - Configure peering on `n` pre-provisioned ExpressRoute Circuits.
    - Optional deployment of `n` Virtual Network Gateway Connections for ExpressRoute Circuits.

## Example 
```hcl
resource "azurerm_resource_group" "rg" {
  location = "uksouth"
  name     = "rg-connectivity-uksouth-prod"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = "vnet-uksouth-prod"
  resource_group_name = azurerm_resource_group.rg.name
}

module "vgw" {
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name
}
```

## Enable or Disable Tracing Tags

We're using [BridgeCrew Yor](https://github.com/bridgecrewio/yor) and [yorbox](https://github.com/lonegunmanb/yorbox) to help manage tags consistently across infrastructure as code (IaC) frameworks. This adds accountability for the code responsible for deploying the particular Azure resources. In this module you might see tags like:

```hcl
resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = coalesce(var.location, data.azurerm_virtual_network.vgw.location)
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = data.azurerm_virtual_network.vgw.resource_group_name
  disable_bgp_route_propagation = !var.route_table_bgp_route_propagation_enabled
  tags = merge(var.default_tags, var.route_table_tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "89805148-c9e6-4736-96bc-0f4095dfb135"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}
```

To enable tracing tags, set the `tracing_tags_enabled` variable to true:

```hcl
module "vgw" {
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name

  tracing_tags_enabled = true
}
```

The `tracing_tags_enabled` is defaulted to `false`.

To customize the prefix for your tracing tags, set the `tracing_tags_prefix` variable value in your Terraform configuration:

```hcl
module "vgw" {
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name

  tracing_tags_enabled = true
  tracing_tags_prefix  = "custom_prefix_"
}
```

The actual applied tags would be:

```text
{
  custom_prefix_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
  custom_prefix_git_file             = "main.tf"
  custom_prefix_git_last_modified_at = "2023-07-01 10:37:24"
  custom_prefix_git_org              = "Azure"
  custom_prefix_git_repo             = "terraform-azurerm-vnet-gateway"
  custom_prefix_yor_name             = "vgw"
  custom_prefix_yor_trace            = "89805148-c9e6-4736-96bc-0f4095dfb135"
}
```
