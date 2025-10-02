# DEPRECATION NOTICE

This module is deprecated and will no longer receive updates.

The code for this module has been migrated a the submodule [avm-ptn-alz-connectivity-hub-and-spoke-vnet/virtual-network-gateway](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest/submodules/virtual-network-gateway).

We recommend referencing the [avm-ptn-alz-connectivity-hub-and-spoke-vnet](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet) module for future deployments.

# terraform-azurerm-avm-ptn-vnetgateway

[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-avm-ptn-vnetgateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-vnetgateway "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-avm-ptn-vnetgateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-vnetgateway "Percentage of issues still open")

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
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location              = "uksouth"
  name                  = "vgw-uksouth-prod"
  subnet_address_prefix = "10.0.1.0/24"
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
```
