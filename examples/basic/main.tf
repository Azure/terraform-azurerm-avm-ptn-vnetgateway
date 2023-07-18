
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
  source = "../.."

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name
}

