output "local_network_gateways" {
  description = "A curated output of the Local Network Gateways created by this module."
  value = {
    for k, v in azurerm_local_network_gateway.vgw : k => {
      id   = v.id
      name = v.name
    }
  }
}

output "public_ip_addresses" {
  description = "A curated output of the Public IP Addresses created by this module."
  value = {
    for k, v in azurerm_public_ip.vgw : k => {
      id         = v.id
      ip_address = try(v.ip_address, null)
      name       = v.name
    }
  }
}

output "resource_id" {
  description = "The ID of the Virtual Network Gateway."
  value       = azurerm_virtual_network_gateway.vgw.id
}

output "route_table" {
  description = "A curated output of the Route Table created by this module."
  value = {
    id   = try(azurerm_route_table.vgw[0].id, null)
    name = try(azurerm_route_table.vgw[0].name, null)

  }
}

output "subnet" {
  description = "A curated output of the GatewaySubnet created by this module."
  value = {
    id   = coalesce(try(azurerm_subnet.vgw[0].id, null), local.subnet_id)
    name = coalesce(try(azurerm_subnet.vgw[0].name, null), basename(local.subnet_id))
  }
}

output "virtual_network_gateway" {
  description = "A curated output of the Virtual Network Gateway created by this module."
  value = {
    bgp_settings = try(azurerm_virtual_network_gateway.vgw.bgp_settings, null)
    id           = azurerm_virtual_network_gateway.vgw.id
    name         = azurerm_virtual_network_gateway.vgw.name
  }
}

output "virtual_network_gateway_connections" {
  description = "A curated output of the Virtual Network Gateway Connections created by this module."
  value = {
    erc = {
      for k, v in azurerm_virtual_network_gateway_connection.vgw : trimprefix(k, "erc-") => {
        id   = v.id
        name = v.name
      } if substr(k, 0, 4) == "erc-"
    }
    lgw = {
      for k, v in azurerm_virtual_network_gateway_connection.vgw : trimprefix(k, "lgw-") => {
        id   = v.id
        name = v.name
      } if substr(k, 0, 4) == "lgw-"
    }
  }
}
