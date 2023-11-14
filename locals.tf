locals {
  bgp_settings = (var.vpn_bgp_settings == null && alltrue([for ip_configuration in local.ip_configurations : ip_configuration.apipa_addresses == null]) ? {} :
    {
      BgpSettings = {
        asn         = try(var.vpn_bgp_settings.asn, null)
        peer_weight = try(var.vpn_bgp_settings.peer_weight, null)
        peering_addresses = {
          for k, v in local.ip_configurations : k => {
            ip_configuration_name = lookup(local.gateway_ip_configurations[k], "ip_configuration_name", null)
            apipa_addresses       = v.apipa_addresses
          }
          if v.apipa_addresses != null
        }
      }
    }
  )
  default_ip_configuration = {
    ip_configuration_name         = null
    apipa_addresses               = null
    private_ip_address_allocation = "Dynamic"
    public_ip = {
      name              = null
      allocation_method = "Dynamic"
      sku               = "Basic"
      tags              = null
    }
  }
  gateway_ip_configurations = {
    for k, v in local.ip_configurations : k => {
      name                          = coalesce(v.ip_configuration_name, "vnetGatewayConfig${k}")
      private_ip_address_allocation = v.private_ip_address_allocation
    }
  }
  ip_configurations = (length(var.ip_configurations) == 0 ?
    var.vpn_active_active_enabled ?
    {
      "001" = local.default_ip_configuration
      "002" = local.default_ip_configuration
    } :
    {
      "001" = local.default_ip_configuration
    }
    : var.ip_configurations
  )
}

locals {
  local_network_gateways = {
  for k, v in var.local_network_gateways : k => v if v.id == null }
}

locals {
  express_route_circuit_peerings = {
    for k, v in var.express_route_circuits : k => merge(
      v.peering,
      {
        express_route_circuit_name = basename(v.id)
      }
    )
    if v.peering != null
  }
}

locals {
  erc_virtual_network_gateway_connections = {
    for k, v in var.express_route_circuits : "erc-${k}" => merge(
      v.connection,
      {
        type                     = "ExpressRoute"
        express_route_circuit_id = v.id
      }
    )
    if v.connection != null
  }
  lgw_virtual_network_gateway_connections = {
    for k, v in var.local_network_gateways : "lgw-${k}" => merge(
      v.connection,
      {
        local_network_gateway_id = v.id
      }
    )
    if v.connection != null
  }
  virtual_network_gateway_connections = merge(local.lgw_virtual_network_gateway_connections, local.erc_virtual_network_gateway_connections)
}

