
resource "azurerm_resource_group" "rg" {
  name     = "rg-connectivity-uksouth-prod"
  location = "uksouth"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-uksouth-prod"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

module "vgw" {
  source = "../.."

  location              = "uksouth"
  name                  = "vgw-uksouth-prod"
  resource_group_name   = azurerm_resource_group.rg.name
  sku                   = "VpnGw1"
  subnet_address_prefix = "10.0.0.1/24"
  type                  = "Vpn"
  virtual_network_name  = azurerm_virtual_network.vnet.name
}

