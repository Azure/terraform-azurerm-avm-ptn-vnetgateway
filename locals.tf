locals {
  subnet_id = join("/", [
    var.virtual_network_id,
    "subnets",
    "GatewaySubnet"
  ])
  virtual_network_name                = basename(var.virtual_network_id)
  virtual_network_resource_group_name = split("/", var.virtual_network_id)[4]
}
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
      name                    = null
      allocation_method       = "Static"
      sku                     = "Standard"
      tags                    = null
      zones                   = [1, 2, 3]
      edge_zone               = null
      ddos_protection_mode    = "VirtualNetworkInherited"
      ddos_protection_plan_id = null
      domain_name_label       = null
      idle_timeout_in_minutes = null
      ip_tags                 = {}
      ip_version              = "IPv4"
      public_ip_prefix_id     = null
      reverse_fqdn            = null
      sku_tier                = "Regional"
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

