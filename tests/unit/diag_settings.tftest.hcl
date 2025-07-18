mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  location              = "somelocation"
  name                  = "nameofvgw"
  parent_id             = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/somerg"
  subnet_address_prefix = "10.0.1.0/24"
  virtual_network_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/somerg/providers/Microsoft.Network/virtualNetworks/somevnet"
}
run "diagnostic_settings" {
  command = plan

  variables {
    diagnostic_settings_virtual_network_gateway = {
      mySettings = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/somerg/providers/Microsoft.OperationalInsights/workspaces/someworkspace"
      }
    }
  }

  assert {
    error_message = "Expected diagnostic settings to be created for the virtual network gateway"
    condition     = azurerm_monitor_diagnostic_setting.vgw["mySettings"] != null
  }
}
