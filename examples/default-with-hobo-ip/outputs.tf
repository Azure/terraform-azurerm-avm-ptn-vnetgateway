output "gateway_subnet_id" {
  description = "The ID of the Gateway Subnet used by the ExpressRoute gateway"
  value       = module.vgw.subnet.id
}

output "hosted_on_behalf_of_public_ip_note" {
  description = "Information about the Azure-managed public IP for ExpressRoute gateways"
  value       = "This ExpressRoute Virtual Network Gateway uses an Azure-managed public IP address. The public IP is automatically provisioned and managed by Azure, and is not visible in your subscription's public IP resources. This feature is only available for ExpressRoute gateways, not VPN gateways."
}

output "public_ip_addresses" {
  description = "Public IP addresses created by the module (empty when using hosted_on_behalf_of_public_ip_enabled for ExpressRoute)"
  value       = module.vgw.public_ip_addresses
}

output "virtual_network_gateway_id" {
  description = "The ID of the ExpressRoute Virtual Network Gateway with Azure-managed public IP"
  value       = module.vgw.virtual_network_gateway.id
}

output "virtual_network_gateway_name" {
  description = "The name of the ExpressRoute Virtual Network Gateway"
  value       = module.vgw.virtual_network_gateway.name
}
