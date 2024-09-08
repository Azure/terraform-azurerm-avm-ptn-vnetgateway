provider "azurerm" {
  features {}
}

variables {
  location                  = "uksouth"
  name                      = "vgw-test"
  subnet_address_prefix     = "10.0.0.0/24"
  sku                       = "VpnGw1AZ"
  type                      = "Vpn"
  enable_telemetry          = false
  vpn_active_active_enabled = false
  virtual_network_id = join("/", [
    "",
    "subscriptions",
    "00000000-0000-0000-0000-000000000000",
    "resourceGroups",
    "rg-test", "providers",
    "Microsoft.Network",
    "virtualNetworks",
    "vnet-test"
  ])
}

run "vpn_active_active" {
  command = plan

  variables {
    vpn_active_active_enabled = true
  }
}

run "vpn_active_active_custom_ip_config" {
  command = plan

  variables {
    vpn_active_active_enabled = true
    ip_configurations = {
      ip_config_0 = {
        public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
        }
      }
      ip_config_2 = {
        public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
        }
      }
    }
  }
}

run "vpn_active_active_custom_ip_config_fail" {
  command = plan

  variables {
    vpn_active_active_enabled = true
    ip_configurations = {
      ip_config_0 = {
        public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
        }
      }
    }
  }

  expect_failures = [
    azurerm_virtual_network_gateway.vgw
  ]
}

run "vpn_local_network_gateway" {
  command = plan

  variables {
    ip_configurations = {
      ip_config_0 = {
        public_ip = {
          allocation_method = "Static"
          sku               = "Standard"
        }
      }
    }
    local_network_gateways = {
      lgn-1 = {
        name            = "lgn-test"
        gateway_address = "0.0.0.0"
        bgp_settings = {
          asn                 = 65515
          bgp_peering_address = "0.0.0.0"
        }
        connection = {
          name       = "conn-test"
          type       = "IPsec"
          shared_key = "ABCDEF"
        }
      }
    }
  }
}