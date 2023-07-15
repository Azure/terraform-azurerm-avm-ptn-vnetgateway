resource "azurerm_subnet" "vgw" {
  address_prefixes     = [var.subnet_address_prefix]
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = var.location
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = var.resource_group_name
  disable_bgp_route_propagation = !var.route_table_bgp_route_propagation_enabled
  tags = merge(var.default_tags, var.route_table_tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "beca18e0-5b02-42af-897b-f90c6d231523"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}

resource "azurerm_subnet_route_table_association" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  route_table_id = azurerm_route_table.vgw[0].id
  subnet_id      = azurerm_subnet.vgw.id

  depends_on = [
    azurerm_subnet.vgw,
    azurerm_route_table.vgw
  ]
}

resource "azurerm_public_ip" "vgw" {
  for_each = local.ip_configurations

  allocation_method   = each.value.public_ip.allocation_method
  location            = var.location
  name                = coalesce(each.value.public_ip.name, "pip-${var.name}-${each.key}")
  resource_group_name = var.resource_group_name
  sku                 = each.value.public_ip.sku
  tags = merge(var.default_tags, each.value.public_ip.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "b5b10bbf-daff-4fcc-82ab-7424c5f5984c"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}

resource "azurerm_virtual_network_gateway" "vgw" {
  location                   = var.location
  name                       = var.name
  resource_group_name        = var.resource_group_name
  sku                        = var.sku
  type                       = var.type
  active_active              = var.vpn_active_active_enabled
  edge_zone                  = var.edge_zone
  enable_bgp                 = var.vpn_bgp_enabled
  generation                 = var.vpn_generation
  private_ip_address_enabled = var.vpn_private_ip_address_enabled
  tags = merge(var.default_tags, var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "65e0c6671887b8ae433f40b3bddfd8294c3fd619"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-11 16:05:12"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "3919014b-e634-4a56-a21e-7bccb1566330"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
  vpn_type = var.vpn_type

  dynamic "ip_configuration" {
    for_each = local.gateway_ip_configurations

    content {
      public_ip_address_id          = azurerm_public_ip.vgw[ip_configuration.key].id
      subnet_id                     = azurerm_subnet.vgw.id
      name                          = ip_configuration.value.name
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
    }
  }
  dynamic "bgp_settings" {
    for_each = local.bgp_settings

    content {
      asn         = bgp_settings.value.asn
      peer_weight = bgp_settings.value.peer_weight

      dynamic "peering_addresses" {
        for_each = bgp_settings.value.peering_addresses

        content {
          apipa_addresses       = peering_addresses.value.apipa_addresses
          ip_configuration_name = peering_addresses.value.ip_configuration_name
        }
      }
    }
  }

  depends_on = [
    azurerm_subnet.vgw,
    azurerm_public_ip.vgw
  ]
}

resource "azurerm_local_network_gateway" "vgw" {
  for_each = local.local_network_gateways

  location            = var.location
  name                = coalesce(each.value.name, "lgw-${var.name}-${each.key}")
  resource_group_name = var.resource_group_name
  address_space       = each.value.address_space
  gateway_address     = each.value.gateway_address
  gateway_fqdn        = each.value.gateway_fqdn
  tags = merge(var.default_tags, each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "da5b554c-b88e-4d41-a206-808495c54d7b"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))

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

  location                        = var.location
  name                            = coalesce(each.value.name, "con-${var.name}-${each.key}")
  resource_group_name             = var.resource_group_name
  type                            = each.value.type
  virtual_network_gateway_id      = azurerm_virtual_network_gateway.vgw.id
  authorization_key               = try(each.value.authorization_key, null)
  connection_mode                 = try(each.value.connection_mode, null)
  connection_protocol             = try(each.value.connection_protocol, null)
  dpd_timeout_seconds             = try(each.value.dpd_timeout_seconds, null)
  egress_nat_rule_ids             = try(each.value.egress_nat_rule_ids, null)
  enable_bgp                      = try(each.value.enable_bgp, null)
  express_route_circuit_id        = try(each.value.express_route_circuit_id, null)
  express_route_gateway_bypass    = try(each.value.express_route_gateway_bypass, null)
  ingress_nat_rule_ids            = try(each.value.ingress_nat_rule_ids, null)
  local_azure_ip_address_enabled  = try(each.value.local_azure_ip_address_enabled, null)
  local_network_gateway_id        = try(azurerm_local_network_gateway.vgw[trimprefix(each.key, "lgw-")].id, null)
  peer_virtual_network_gateway_id = try(each.value.peer_virtual_network_gateway_id, null)
  routing_weight                  = each.value.routing_weight
  shared_key                      = try(each.value.shared_key, null)
  tags = merge(var.default_tags, each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "fcde249c-d8e6-4c37-9e62-ccb391c88dee"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
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
      dh_group         = each.value.ipsec_policy.dh_group
      ike_encryption   = each.value.ipsec_policy.ike_encryption
      ike_integrity    = each.value.ipsec_policy.ike_integrity
      ipsec_encryption = each.value.ipsec_policy.ipsec_encryption
      ipsec_integrity  = each.value.ipsec_policy.ipsec_integrity
      pfs_group        = each.value.ipsec_policy.pfs_group
      sa_datasize      = each.value.ipsec_policy.sa_datasize
      sa_lifetime      = each.value.ipsec_policy.sa_lifetime
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

  express_route_circuit_name    = each.value.express_route_circuit_name
  peering_type                  = each.value.peering_type
  resource_group_name           = var.resource_group_name
  vlan_id                       = each.value.vlan_id
  ipv4_enabled                  = each.value.ipv4_enabled
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  route_filter_id               = each.value.route_filter_id
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  shared_key                    = each.value.shared_key

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config == null ? [] : ["MicrosoftPeeringConfig"]

    content {
      advertised_public_prefixes = each.value.microsoft_advertised_public_prefixes
      advertised_communities     = each.value.microsoft_advertised_communities
      customer_asn               = each.value.microsoft_customer_asn
      routing_registry_name      = each.value.microsoft_routing_registry_name
    }
  }
}
