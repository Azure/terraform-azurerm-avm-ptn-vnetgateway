locals {
  azurerm_express_route_circuit_peering           = nonsensitive(sensitive(local.express_route_circuit_peerings))
  azurerm_express_route_circuit_peering_sensitive = local.express_route_circuit_peerings
  azurerm_local_network_gateway = {
    for local_network_gateway_key, local_network_gateway in var.local_network_gateways : local_network_gateway_key => local_network_gateway if local_network_gateway.id == null
  }
  azurerm_public_ip = {
    for ip_configuration_key, ip_configuration in local.ip_configurations : ip_configuration_key => {
      name                    = ip_configuration.public_ip.name
      resource_group_name     = coalesce(ip_configuration.public_ip.resource_group_name, local.virtual_network_resource_group_name)
      allocation_method       = ip_configuration.public_ip.allocation_method
      sku                     = ip_configuration.public_ip.sku
      tags                    = ip_configuration.public_ip.tags
      zones                   = ip_configuration.public_ip.zones
      edge_zone               = ip_configuration.public_ip.edge_zone
      ddos_protection_mode    = ip_configuration.public_ip.ddos_protection_mode
      ddos_protection_plan_id = ip_configuration.public_ip.ddos_protection_plan_id
      domain_name_label       = ip_configuration.public_ip.domain_name_label
      idle_timeout_in_minutes = ip_configuration.public_ip.idle_timeout_in_minutes
      ip_tags                 = ip_configuration.public_ip.ip_tags
      ip_version              = ip_configuration.public_ip.ip_version
      public_ip_prefix_id     = ip_configuration.public_ip.public_ip_prefix_id
      reverse_fqdn            = ip_configuration.public_ip.reverse_fqdn
      sku_tier                = ip_configuration.public_ip.sku_tier
    }
    if ip_configuration.public_ip.creation_enabled == true
  }
  azurerm_virtual_network_gateway = {
    bgp_settings = {
      asn         = try(var.vpn_bgp_settings.asn, 65515)
      peer_weight = try(var.vpn_bgp_settings.peer_weight, null)
      peering_addresses = {
        for ip_configuration_key, ip_configuration in local.ip_configurations : ip_configuration_key => {
          ip_configuration_name = ip_configuration.name
          apipa_addresses       = ip_configuration.apipa_addresses
        }
        if ip_configuration.apipa_addresses != null
      }
    }
    ip_configuration = {
      for ip_configuration_key, ip_configuration in local.ip_configurations : ip_configuration_key => {
        name                          = ip_configuration.name
        public_ip_address_id          = try(azurerm_public_ip.vgw[ip_configuration_key].id, ip_configuration.public_ip.id)
        subnet_id                     = try(azurerm_subnet.vgw[0].id, local.subnet_id)
        private_ip_address_allocation = ip_configuration.private_ip_address_allocation
      }
    }
  }
  azurerm_virtual_network_gateway_connection = nonsensitive(sensitive(merge(
    local.local_network_gateway_virtual_network_gateway_connections,
    local.express_route_circuit_virtual_network_gateway_connections
  )))
  azurerm_virtual_network_gateway_connection_sensitive = merge(
    local.local_network_gateway_virtual_network_gateway_connections,
    local.express_route_circuit_virtual_network_gateway_connections
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
      creation_enabled        = true
      resource_group_name     = null
      id                      = null
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
    for ip_configuration_key, ip_configuration in(
      length(var.ip_configurations) == 0 ? (
        var.vpn_active_active_enabled && var.type == "Vpn" ?
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
    : ip_configuration_key => merge(
      ip_configuration,
      {
        name = coalesce(ip_configuration.name, "vnetGatewayConfig${ip_configuration_key}")
        public_ip = merge(
          ip_configuration.public_ip,
          {
            name = coalesce(ip_configuration.public_ip.name, "pip-${var.name}-${ip_configuration_key}")
          }
        )
      }
    )
  }
}
locals {
  express_route_circuit_virtual_network_gateway_connections = {
    for express_route_circuit_key, express_route_circuit in var.express_route_circuits : "erc-${express_route_circuit_key}" => merge(
      express_route_circuit.connection,
      {
        type                     = "ExpressRoute"
        express_route_circuit_id = express_route_circuit.id
      }
    )
    if express_route_circuit.connection != null
  }
  local_network_gateway_virtual_network_gateway_connections = {
    for local_network_gateway_key, local_network_gateway in var.local_network_gateways : "lgw-${local_network_gateway_key}" => merge(
      local_network_gateway.connection,
      {
        local_network_gateway_id = local_network_gateway.id
      }
    )
    if local_network_gateway.connection != null
  }
}
locals {
  express_route_circuit_peerings = {
    for express_route_circuit_key, express_route_circuit in var.express_route_circuits : express_route_circuit_key => merge(
      express_route_circuit.peering,
      {
        express_route_circuit_name = basename(express_route_circuit.id)
      }
    )
    if express_route_circuit.peering != null
  }
}
