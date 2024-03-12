output "test_public_ip_address_id" {
  description = "The ID of the Public IP Address"
  value       = module.vgw.public_ip_addresses["001"].id
}

output "test_virtual_network_gateway_id" {
  description = "The ID of the Virtual Network Gateway"
  value       = module.vgw.virtual_network_gateway.id
}
