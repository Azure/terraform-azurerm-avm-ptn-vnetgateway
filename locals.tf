locals {
  azurerm_express_route_circuit_peering           = local.express_route_circuit_peerings.nonsensitive_map
  azurerm_express_route_circuit_peering_sensitive = local.express_route_circuit_peerings.sensitive_map
  azurerm_local_network_gateway = {
    for k, v in var.local_network_gateways : k => v if v.id == null
  }
  azurerm_public_ip = {
    for k, v in local.ip_configurations : k => {
      name                    = v.public_ip.name
      allocation_method       = v.public_ip.allocation_method
      sku                     = v.public_ip.sku
      tags                    = v.public_ip.tags
      zones                   = v.public_ip.zones
      edge_zone               = v.public_ip.edge_zone
      ddos_protection_mode    = v.public_ip.ddos_protection_mode
      ddos_protection_plan_id = v.public_ip.ddos_protection_plan_id
      domain_name_label       = v.public_ip.domain_name_label
      idle_timeout_in_minutes = v.public_ip.idle_timeout_in_minutes
      ip_tags                 = v.public_ip.ip_tags
      ip_version              = v.public_ip.ip_version
      public_ip_prefix_id     = v.public_ip.public_ip_prefix_id
      reverse_fqdn            = v.public_ip.reverse_fqdn
      sku_tier                = v.public_ip.sku_tier
    }
  }
  azurerm_virtual_network_gateway = {
    tags = var.tags == null ? {} : var.tags
    bgp_settings = {
      asn         = try(var.vpn_bgp_settings.asn, null)
      peer_weight = try(var.vpn_bgp_settings.peer_weight, null)
      peering_addresses = {
        for k, v in local.ip_configurations : k => {
          ip_configuration_name = v.name
          apipa_addresses       = v.apipa_addresses
        }
        if v.apipa_addresses != null
      }
    }
    ip_configuration = {
      for k, v in local.ip_configurations : k => {
        name                          = v.name
        public_ip_address_id          = azurerm_public_ip.vgw[k].id
        subnet_id                     = var.subnet_creation_enabled ? azurerm_subnet.vgw[0].id : local.subnet_id
        private_ip_address_allocation = v.private_ip_address_allocation
      }
    }
  }
  azurerm_virtual_network_gateway_connection = merge(
    local.local_network_gateway_virtual_network_gateway_connections.nonsensitive_map,
    local.express_route_circuit_virtual_network_gateway_connections.nonsensitive_map
  )
  azurerm_virtual_network_gateway_connection_sensitive = merge(
    local.local_network_gateway_virtual_network_gateway_connections.sensitive_map,
    local.express_route_circuit_virtual_network_gateway_connections.sensitive_map
  )
}


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
  default_ip_configuration = {
    name                          = null
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
  ip_configurations = {
    for k, v in(
      length(var.ip_configurations) == 0 ? (
        var.vpn_active_active_enabled ?
        {
          "001" = local.default_ip_configuration
          "002" = local.default_ip_configuration
        }
        :
        {
          "001" = local.default_ip_configuration
        }
      )
      :
      var.ip_configurations
    )
    : k => merge(
      v,
      {
        name = coalesce(v.name, "vnetGatewayConfig${k}")
        public_ip = merge(
          v.public_ip,
          {
            name = coalesce(v.public_ip.name, "pip-${var.name}-${k}")
          }
        )
      }
    )
  }
}
locals {
  express_route_circuit_virtual_network_gateway_connections = {
    sensitive_map = {
      for k, v in var.express_route_circuits : "erc-${k}" => merge(
        v.connection,
        {
          type                     = "ExpressRoute"
          express_route_circuit_id = v.id
        }
      )
      if v.connection != null
    }
    nonsensitive_map = {
      for k, v in var.express_route_circuits : "erc-${k}" => merge(
        v.connection,
        {
          type                     = "ExpressRoute"
          express_route_circuit_id = v.id
          shared_key               = null
          authorization_key        = null
        }
      )
      if v.connection != null
    }
  }
  local_network_gateway_virtual_network_gateway_connections = {
    sensitive_map = {
      for k, v in var.local_network_gateways : "lgw-${k}" => merge(
        v.connection,
        {
          local_network_gateway_id = v.id
        }
      )
      if v.connection != null
    }
    nonsensitive_map = {
      for k, v in var.local_network_gateways : "lgw-${k}" => merge(
        v.connection,
        {
          local_network_gateway_id = v.id
          shared_key               = null
        }
      )
      if v.connection != null
    }
  }
}

locals {
  express_route_circuit_peerings = {
    sensitive_map = {
      for k, v in var.express_route_circuits : k => merge(
        v.peering,
        {
          express_route_circuit_name = basename(v.id)
        }
      )
      if v.peering != null
    }
    nonsensitive_map = {
      for k, v in var.express_route_circuits : k => merge(
        v.peering,
        {
          express_route_circuit_name = basename(v.id)
          shared_key                 = null
        }
      )
      if v.peering != null
    }
  }
}
