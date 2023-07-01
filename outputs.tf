output "local_network_gateway_ids" {
  description = "value for local_network_gateway_ids. The IDs of the local network gateways."
  value = {
    for local_network_gateway in azurerm_local_network_gateway.vgw : local_network_gateway.name => local_network_gateway.id
  }
}

output "public_ip_address_ids" {
  description = "value for public_ip_address_ids. The IDs of the public IP addresses."
  value = {
    for public_ip_address in azurerm_public_ip.vgw : public_ip_address.name => public_ip_address.id
  }
}

output "route_table_name" {
  description = "value for the name of the route table."
  value       = try(azurerm_route_table.vgw[0].name, null)
}

output "virtual_network_connection_ids" {
  description = "value for virtual_network_connection_ids. The IDs of the virtual network connections."
  value = {
    for virtual_network_connection in azurerm_virtual_network_gateway_connection.vgw : virtual_network_connection.name => virtual_network_connection.id
  }
}

output "virtual_network_gateway_id" {
  description = "value for virtual_network_gateway_id. The ID of the virtual network gateway."
  value       = azurerm_virtual_network_gateway.vgw.id
}
