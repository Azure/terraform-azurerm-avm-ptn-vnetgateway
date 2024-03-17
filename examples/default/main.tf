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

