resource "azurerm_subnet" "vgw" {
  address_prefixes     = [var.subnet_address_prefix]
  name                 = "GatewaySubnet"
  resource_group_name  = var.virtual_network_resource_group_name
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = var.location
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = var.virtual_network_resource_group_name
  disable_bgp_route_propagation = !var.route_table_bgp_route_propagation_enabled
  tags = merge(var.default_tags, var.route_table_tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "89805148-c9e6-4736-96bc-0f4095dfb135"
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
  resource_group_name = var.virtual_network_resource_group_name
  sku                 = each.value.public_ip.sku
  tags = merge(var.default_tags, each.value.public_ip.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "7f18d01c-b186-4a88-88a0-1edabdcc3538"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
}

resource "azurerm_virtual_network_gateway" "vgw" {
  location                   = var.location
  name                       = var.name
  resource_group_name        = var.virtual_network_resource_group_name
  sku                        = var.sku
  type                       = var.type
  active_active              = var.vpn_active_active_enabled
  edge_zone                  = var.edge_zone
  enable_bgp                 = var.vpn_bgp_enabled
  generation                 = var.vpn_generation
  private_ip_address_enabled = var.vpn_private_ip_address_enabled
  tags = merge(var.default_tags, var.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "f4d795487dd08e721ce03e7dc1f7806fdd148c93"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-15 19:38:46"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "4d5e3262-05b2-41c8-a5f7-1f01f78c598a"
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
  dynamic "vpn_client_configuration" {
    for_each = var.vpn_point_to_site == null ? [] : ["VpnClientConfiguration"]

    content {
      address_space         = var.vpn_point_to_site.address_space
      aad_audience          = var.vpn_point_to_site.aad_audience
      aad_issuer            = var.vpn_point_to_site.aad_issuer
      aad_tenant            = var.vpn_point_to_site.aad_tenant
      radius_server_address = var.vpn_point_to_site.radius_server_address
      radius_server_secret  = var.vpn_point_to_site.radius_server_secret
      vpn_auth_types        = var.vpn_point_to_site.vpn_auth_types
      vpn_client_protocols  = var.vpn_point_to_site.vpn_client_protocols

      dynamic "revoked_certificate" {
        for_each = var.vpn_point_to_site.revoked_certificate

        content {
          name       = revoked_certificate.value.name
          thumbprint = revoked_certificate.value.thumbprint
        }
      }
      dynamic "root_certificate" {
        for_each = var.vpn_point_to_site.root_certificate

        content {
          name             = root_certificate.value.name
          public_cert_data = root_certificate.value.public_cert_data
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
  for_each = var.local_network_gateways

  location            = var.location
  name                = coalesce(each.value.name, "lgw-${var.name}-${each.key}")
  resource_group_name = var.virtual_network_resource_group_name
  address_space       = each.value.address_space
  gateway_address     = each.value.gateway_address
  gateway_fqdn        = each.value.gateway_fqdn
  tags = merge(var.default_tags, each.value.tags, (/*<box>*/ (var.tracing_tags_enabled ? { for k, v in /*</box>*/ {
    avm_git_commit           = "bc67a9e4a4c0beb833f1249369f9f1aa864de6e3"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-17 15:24:49"
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "1699f313-6e9a-450a-9457-479e67efbe25"
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
  resource_group_name             = var.virtual_network_resource_group_name
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
    avm_git_org              = "Azure"
    avm_git_repo             = "terraform-azurerm-vnet-gateway"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "7ca8984d-3fa3-4fa4-b32d-3c489223aedd"
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
  resource_group_name           = var.virtual_network_resource_group_name
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
