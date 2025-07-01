resource "random_id" "id" {
  byte_length = 4
}

locals {
  location = "uksouth"
}

resource "azurerm_resource_group" "rg" {
  location = local.location
  name     = "rg-vnetgateway-hobo-${random_id.id.hex}"
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "vnet-hobo-${random_id.id.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# ExpressRoute Virtual Network Gateway with Azure-managed public IP (HOBO)
module "vgw" {
  source = "../.."

  location                              = azurerm_resource_group.rg.location
  name                                  = "vgw-hobo-${random_id.id.hex}"
  hosted_on_behalf_of_public_ip_enabled = true      # Workaround to use Azure-managed public IP for ExpressRoute gateways, and remove the public IP resource creation and attachment.
  sku                                   = "ErGw1AZ" # ExpressRoute gateway SKU
  subnet_address_prefix                 = "10.0.1.0/24"
  tags = {
    environment  = "demo"
    purpose      = "expressroute-hobo-ip-example"
    gateway_type = "ExpressRoute"
  }
  type               = "ExpressRoute" # HOBO only available for ExpressRoute
  virtual_network_id = azurerm_virtual_network.vnet.id
}
