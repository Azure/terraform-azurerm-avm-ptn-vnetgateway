locals {
  default_ip_configuration = {
    ip_configuration_name        = null
    apipa_addresses              = null
    private_ip_allocation_method = "Dynamic"
    public_ip = {
      name              = null
      allocation_method = "Dynamic"
      sku               = "Basic"
      tags              = null
    }
  }
  ip_configurations = (
    try(length(var.ip_configurations) == 0, var.ip_configurations == null) ? (
      var.vpn_active_active_enabled ?
      {
        "001" = local.default_ip_configuration
        "002" = local.default_ip_configuration
      } :
      {
        "001" = local.default_ip_configuration
      }
    )
    : var.ip_configurations
  )
}

locals {
  express_route_circuit_peerings = var.express_route_circuits != null ? { for k, v in var.express_route_circuits :
    "erc-${k}" => merge(
      v.peering_config,
      {
        express_route_circuit_name = basename(v.express_route_circuit_id)
      }
    )
    if v.peering_config != null
  } : {}
}

locals {
  local_network_gateways = var.local_network_gateways != null ? var.local_network_gateways : {}
}

locals {
  erc_virtual_network_gateway_connections = var.express_route_circuits != null ? { for k, v in var.express_route_circuits :
    "erc-${k}" => merge(
      v.connection_config,
      {
        type                     = "ExpressRouteCircuit"
        express_route_circuit_id = v.express_route_circuit_id
      }
    )
    if v.connection_config != null
  } : {}
  lgw_virtual_network_gateway_connections = var.local_network_gateways != null ? { for k, v in var.local_network_gateways :
    "lgw-${k}" => v.connection_config
    if v.connection_config != null
  } : {}
  virtual_network_gateway_connections = merge(local.lgw_virtual_network_gateway_connections, local.erc_virtual_network_gateway_connections)
}

