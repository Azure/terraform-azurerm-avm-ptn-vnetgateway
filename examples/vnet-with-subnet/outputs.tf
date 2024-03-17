output "test_subnet_id" {
  description = "The ID of the subnet for the virtual network gateway."
  value       = module.vgw.subnet.id
}
