locals {
  shared_key = sensitive("shared_key")
}

resource "random_id" "id" {
  byte_length = 4
}

resource "azurerm_resource_group" "rg" {
  location = "uksouth"
  name     = "rg-vnetgateway-${random_id.id.hex}"
}

resource "azurerm_resource_group" "rg_two" {
  location = "uksouth"
  name     = "rg-vnetgateway-${random_id.id.hex}-02"
}

resource "azurerm_virtual_network" "vnet" {
  location            = azurerm_resource_group.rg.location
  name                = "vnet-uksouth-prod"
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
  name                = "pip-uksouth-prod"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

module "vgw" {
  source = "../.."

  location = "uksouth"
  name     = "vgw-uksouth-prod"
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
  subnet_address_prefix             = "10.0.1.0/24"
  subnet_creation_enabled           = false
  type                              = "Vpn"
  virtual_network_gateway_subnet_id = azurerm_subnet.gateway_subnet.id
  vpn_active_active_enabled         = true
  vpn_bgp_enabled                   = true
}

