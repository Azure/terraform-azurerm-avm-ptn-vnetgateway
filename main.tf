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
    avm_yor_trace            = "a36b6e8d-0fb5-4c50-a3e9-f8889e53f0d7"
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
    avm_yor_trace            = "b06e2843-00de-48ac-8ba4-04a6694c3c8e"
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
    avm_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
    avm_git_file             = "main.tf"
    avm_git_last_modified_at = "2023-07-01 10:37:24"
    avm_git_org              = "luke-taylor"
    avm_git_repo             = "terraform-azurerm-alz-vgw"
    avm_yor_name             = "vgw"
    avm_yor_trace            = "0deb59e2-d6bb-4232-8433-508604f84427"
  } /*<box>*/ : replace(k, "avm_", var.tracing_tags_prefix) => v } : {}) /*</box>*/))
  vpn_type = var.vpn_type

  dynamic "ip_configuration" {
    for_each = local.ip_configurations

    content {
      public_ip_address_id          = azurerm_public_ip.vgw[ip_configuration.key].id
      subnet_id                     = azurerm_subnet.vgw.id
      name                          = coalesce(ip_configuration.value.ip_configuration_name, "vnetGatewayConfig${ip_configuration.key}")
      private_ip_address_allocation = ip_configuration.value.private_ip_allocation_method
    }
  }
  dynamic "bgp_settings" {
    for_each = var.vpn_bgp_settings == null && alltrue([for ip_configuration in local.ip_configurations : ip_configuration.apipa_addresses == null]) ? [] : ["BgpSettings"]

    content {
      asn         = try(var.vpn_bgp_settings.asn, null)
      peer_weight = try(var.vpn_bgp_settings.peer_weight, null)

      dynamic "peering_addresses" {
        for_each = alltrue([for ip_configuration in local.ip_configurations : ip_configuration.apipa_addresses == null]) ? {} : local.ip_configurations

        content {
          apipa_addresses       = peering_addresses.value.apipa_addresses
          ip_configuration_name = coalesce(peering_addresses.value.ip_configuration_name, "vnetGatewayConfig${peering_addresses.key}")
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
    avm_yor_trace            = "27bbab0a-91d9-4205-930e-6590549bb1b0"
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
    avm_yor_trace            = "f5f444f5-79b1-4098-84fd-c274f0741685"
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
