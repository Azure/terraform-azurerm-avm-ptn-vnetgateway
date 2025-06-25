output "test" {
  description = "The ID of the subnet for the virtual network gateway."
  value = {
    vpn           = module.vgw_vpn
    express_route = module.vgw_er
  }
}
