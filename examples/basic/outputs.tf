output "test_public_ip_address_id" {
  value = module.vgw.public_ip_addresses["001"].id
}

output "test_virtual_network_gateway_id" {
  value = module.vgw.virtual_network_gateway.id
}
