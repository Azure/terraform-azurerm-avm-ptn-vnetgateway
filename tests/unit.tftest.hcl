# valid_string_concat.tftest.hcl

mock_provider "azurerm" {}

variables {
  location                            = "uksouth"
  name                                = "vgw-test"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.0.0/24"
  type                                = "Vpn"
  virtual_network_name                = "vnet-test"
  virtual_network_resource_group_name = "rg-test"
}

run "default" {

  command = plan

}

// run "expressroute" {

//   command = plan


//   variables {
//     location                            = "uksouth"
//     name                                = "vgw-uksouth-prod"
//     sku                                 = "VpnGw1"
//     subnet_address_prefix               = "10.0.1.0/24"
//     type                                = "ExpressRoute"
//     virtual_network_name                = "rg"
//     virtual_network_resource_group_name = "vnet"
//     ip_configurations = {
//       ip_config_0 = {
//         public_ip = {
//           allocation_method = "Static"
//           sku               = "Standard"
//         }
//       }
//     }
//     express_route_circuits = {
//       desen = {
//         id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/expressRouteCircuits/desen"
//         connection = {
//           express_route_gateway_bypass = true
//           authorization_key            = "ABDNDBEHF"
//           name                         = "desen"
//           routing_weight               = 10
//         }
//       }
//     }
//   }
// }
