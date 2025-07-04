resource "random_id" "id" {
  byte_length = 4
}

locals {
  location = "swedencentral"
}

resource "azurerm_resource_group" "rg" {
  location = local.location
  name     = "rg-vnetgateway-${random_id.id.hex}"
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "vnet-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

module "vgw" {
  source = "../.."

  location              = azurerm_resource_group.rg.location
  name                  = "vgw-${random_id.id.hex}"
  parent_id             = azurerm_resource_group.rg.id
  subnet_address_prefix = "10.0.1.0/24"
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

