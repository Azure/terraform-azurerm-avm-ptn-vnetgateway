provider "azurerm" {
  features {}
}

variables {
  location              = "uksouth"
  name                  = "vgw-test"
  subnet_address_prefix = "10.0.0.0/24"
  enable_telemetry      = false
  virtual_network_id = join("/", [
    "",
    "subscriptions",
    "00000000-0000-0000-0000-000000000000",
    "resourceGroups",
    "rg-test",
    "providers",
    "Microsoft.Network",
    "virtualNetworks",
    "vnet-test"
  ])
}

run "expressroute" {
  command = plan

  variables {
    sku  = "HighPerformance"
    type = "ExpressRoute"

    ip_configurations = {
      ip_config_0 = {
        public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
        }
      }
    }
    express_route_circuits = {
      erc = {
        id = join("/", [
          "",
          "subscriptions",
          "00000000-0000-0000-0000-000000000000",
          "resourceGroups",
          "rg-erc-test",
          "providers",
          "Microsoft.Network",
          "expressRouteCircuits",
          "erc-test"
        ])
        connection = {
          express_route_gateway_bypass = true
          authorization_key            = "ABDNDBEHF"
          name                         = "conn-test"
          routing_weight               = 10
          shared_key                   = "ABCDEF"
        }
        peering = {
          peering_type        = "AzurePrivatePeering"
          vlan_id             = 100
          resource_group_name = "rg-test"
        }
      }
    }
  }
}


run "expressroute_route_table_creation" {
  command = plan

  variables {
    route_table_creation_enabled = true
  }
}