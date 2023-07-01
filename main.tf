resource "azurerm_subnet" "vgw" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  disable_bgp_route_propagation = !var.route_table_bgp_route_propagation_enabled
  location                      = var.location
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = var.resource_group_name
  tags                          = merge(var.default_tags, var.route_table_tags)
}

resource "azurerm_subnet_route_table_association" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  subnet_id      = azurerm_subnet.vgw.id
  route_table_id = azurerm_route_table.vgw[0].id

  depends_on = [
    azurerm_subnet.vgw,
    azurerm_route_table.vgw
  ]
}

resource "azurerm_public_ip" "vgw" {
  for_each = local.ip_configurations

  name                = coalesce(each.value.public_ip.name, "pip-${var.name}-${each.key}")
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = each.value.public_ip.allocation_method
  sku                 = each.value.public_ip.sku
  tags                = merge(var.default_tags, each.value.public_ip.tags)
}

resource "azurerm_virtual_network_gateway" "vgw" {
  name                       = var.name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = var.type
  sku                        = var.sku
  active_active              = var.vpn_active_active_enabled
  generation                 = var.vpn_generation
  edge_zone                  = var.edge_zone
  vpn_type                   = var.vpn_type
  enable_bgp                 = var.vpn_bgp_enabled
  private_ip_address_enabled = var.vpn_private_ip_address_enabled
  tags                       = merge(var.default_tags, var.tags)

  dynamic "bgp_settings" {
    for_each = var.vpn_bgp_settings == null && alltrue([for ip_configuration in local.ip_configurations : ip_configuration.apipa_addresses == null]) ? [] : ["BgpSettings"]

    content {
      asn         = try(var.vpn_bgp_settings.asn, null)
      peer_weight = try(var.vpn_bgp_settings.peer_weight, null)

      dynamic "peering_addresses" {
        for_each = alltrue([for ip_configuration in local.ip_configurations : ip_configuration.apipa_addresses == null]) ? {} : local.ip_configurations

        content {
          ip_configuration_name = coalesce(peering_addresses.value.ip_configuration_name, "vnetGatewayConfig${peering_addresses.key}")
          apipa_addresses       = peering_addresses.value.apipa_addresses
        }
      }
    }
  }

  dynamic "ip_configuration" {
    for_each = local.ip_configurations

    content {
      name                          = coalesce(ip_configuration.value.ip_configuration_name, "vnetGatewayConfig${ip_configuration.key}")
      subnet_id                     = azurerm_subnet.vgw.id
      private_ip_address_allocation = ip_configuration.value.private_ip_allocation_method
      public_ip_address_id          = azurerm_public_ip.vgw[ip_configuration.key].id
    }
  }

  depends_on = [
    azurerm_subnet.vgw,
    azurerm_public_ip.vgw
  ]
}

resource "azurerm_local_network_gateway" "vgw" {
  for_each = local.local_network_gateways

  name                = coalesce(each.value.name, "lgw-${var.name}-${each.key}")
  resource_group_name = var.resource_group_name
  location            = var.location
  gateway_address     = each.value.gateway_address
  address_space       = each.value.address_space
  gateway_fqdn        = each.value.gateway_fqdn
  tags                = merge(var.default_tags, each.value.tags)

  dynamic "bgp_settings" {
    for_each = each.value.bgp_settings == null ? [] : ["BgpSettings"]

    content {
      asn                 = each.value.bgp_settings.asn
      bgp_peering_address = each.value.bgp_settings.bgp_peering_address
      peer_weight         = each.value.bgp_settings.peer_weight
    }
  }
}

resource "azurerm_virtual_network_gateway_connection" "vgw" {
  for_each = local.virtual_network_gateway_connections

  name                       = coalesce(each.value.name, "con-${var.name}-${each.key}")
  resource_group_name        = var.resource_group_name
  location                   = var.location
  type                       = each.value.type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vgw.id

  authorization_key                  = try(each.value.authorization_key, null)
  connection_mode                    = try(each.value.connection_mode, null)
  connection_protocol                = try(each.value.connection_protocol, null)
  dpd_timeout_seconds                = try(each.value.dpd_timeout_seconds, null)
  egress_nat_rule_ids                = try(each.value.egress_nat_rule_ids, null)
  enable_bgp                         = try(each.value.enable_bgp, null)
  express_route_circuit_id           = try(each.value.express_route_circuit_id, null)
  express_route_gateway_bypass       = try(each.value.express_route_gateway_bypass, null)
  ingress_nat_rule_ids               = try(each.value.ingress_nat_rule_ids, null)
  local_azure_ip_address_enabled     = try(each.value.local_azure_ip_address_enabled, null)
  local_network_gateway_id           = try(azurerm_local_network_gateway.vgw[trimprefix(each.key, "lgw-")].id, null)
  peer_virtual_network_gateway_id    = try(each.value.peer_virtual_network_gateway_id, null)
  routing_weight                     = each.value.routing_weight
  shared_key                         = try(each.value.shared_key, null)
  tags                               = merge(var.default_tags, each.value.tags)
  use_policy_based_traffic_selectors = try(each.value.use_policy_based_traffic_selectors, null)

  dynamic "custom_bgp_addresses" {
    for_each = try(each.value.custom_bgp_addresses, null) == null ? [] : ["CustomBgpAddresses"]

    content {
      primary   = each.value.custom_bgp_addresses.primary
      secondary = each.value.custom_bgp_addresses.secondary
    }
  }

  dynamic "ipsec_policy" {
    for_each = try(each.value.ipsec_policy, null) == null ? [] : ["IPSecPolicy"]

    content {
      sa_lifetime      = each.value.ipsec_policy.sa_lifetime
      sa_datasize      = each.value.ipsec_policy.sa_datasize
      ipsec_encryption = each.value.ipsec_policy.ipsec_encryption
      ipsec_integrity  = each.value.ipsec_policy.ipsec_integrity
      ike_encryption   = each.value.ipsec_policy.ike_encryption
      ike_integrity    = each.value.ipsec_policy.ike_integrity
      dh_group         = each.value.ipsec_policy.dh_group
      pfs_group        = each.value.ipsec_policy.pfs_group
    }
  }

  dynamic "traffic_selector_policy" {
    for_each = try(each.value.traffic_selector_policy, null) == null ? [] : each.value.traffic_selector_policy

    content {
      local_address_cidrs  = traffic_selector_policy.value.local_address_prefixes
      remote_address_cidrs = traffic_selector_policy.value.remote_address_prefixes
    }
  }
  depends_on = [
    azurerm_local_network_gateway.vgw,
    azurerm_virtual_network_gateway.vgw,
  ]
}

resource "azurerm_express_route_circuit_peering" "vgw" {
  for_each = local.express_route_circuit_peerings

  peering_type                  = try(each.value.peering_type, "AzurePrivatePeering")
  express_route_circuit_name    = each.value.express_route_circuit_name
  resource_group_name           = var.resource_group_name
  vlan_id                       = each.value.vlan_id
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  ipv4_enabled                  = each.value.ipv4_enabled
  shared_key                    = each.value.shared_key
  route_filter_id               = each.value.route_filter_id

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config == null ? [] : ["MicrosoftPeeringConfig"]

    content {
      advertised_public_prefixes = each.value.microsoft_advertised_public_prefixes
      customer_asn               = each.value.microsoft_customer_asn
      routing_registry_name      = each.value.microsoft_routing_registry_name
      advertised_communities     = each.value.microsoft_advertised_communities
    }
  }
}
