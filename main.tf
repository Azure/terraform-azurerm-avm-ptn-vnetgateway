resource "azurerm_subnet" "vgw" {
  count = var.subnet_creation_enabled ? 1 : 0

  address_prefixes     = [var.subnet_address_prefix]
  name                 = "GatewaySubnet"
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network_name
}

resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = var.location
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = coalesce(var.route_table_resource_group_name, local.resource_group_name)
  bgp_route_propagation_enabled = var.route_table_bgp_route_propagation_enabled
  tags                          = merge(var.tags, var.route_table_tags)
}

resource "azurerm_subnet_route_table_association" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  route_table_id = azurerm_route_table.vgw[0].id
  subnet_id      = var.subnet_creation_enabled ? azurerm_subnet.vgw[0].id : var.virtual_network_gateway_subnet_id

  depends_on = [
    azurerm_subnet.vgw,
    azurerm_route_table.vgw
  ]
}

resource "azurerm_public_ip" "vgw" {
  for_each = local.azurerm_public_ip

  allocation_method       = each.value.allocation_method
  location                = var.location
  name                    = each.value.name
  resource_group_name     = coalesce(each.value.resource_group_name, local.resource_group_name)
  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  domain_name_label       = each.value.domain_name_label
  edge_zone               = each.value.edge_zone
  idle_timeout_in_minutes = each.value.idle_timeout_in_minutes
  ip_tags                 = each.value.ip_tags
  ip_version              = each.value.ip_version
  public_ip_prefix_id     = each.value.public_ip_prefix_id
  reverse_fqdn            = each.value.reverse_fqdn
  sku                     = each.value.sku
  sku_tier                = each.value.sku_tier
  tags                    = merge(var.tags, each.value.tags)
  zones                   = each.value.zones
}

resource "azapi_resource" "vgw" {
  location  = var.location
  name      = var.name
  parent_id = var.parent_id
  type      = "Microsoft.Network/virtualNetworkGateways@2024-07-01"
  body = {
    extendedLocation = local.extended_location
    properties       = local.virtual_network_gateway_properties_filtered
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  tags                   = var.tags
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  lifecycle {
    precondition {
      condition     = var.vpn_active_active_enabled == true && var.type == "Vpn" ? length(local.azurerm_virtual_network_gateway.ip_configuration) > 1 : true
      error_message = "An active-active gateway requires at least two IP configurations."
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "vgw" {
  for_each = var.diagnostic_settings_virtual_network_gateway

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azapi_resource.vgw.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}

# Handle migration from azurerm_virtual_network_gateway to azapi_resource
moved {
  from = azurerm_virtual_network_gateway.vgw
  to   = azapi_resource.vgw
}

resource "azurerm_local_network_gateway" "vgw" {
  for_each = local.azurerm_local_network_gateway

  location            = var.location
  name                = coalesce(each.value.name, "lgw-${var.name}-${each.key}")
  resource_group_name = coalesce(each.value.resource_group_name, local.resource_group_name)
  address_space       = each.value.address_space
  gateway_address     = each.value.gateway_address
  gateway_fqdn        = each.value.gateway_fqdn
  tags                = merge(var.tags, each.value.tags)

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
  for_each = local.azurerm_virtual_network_gateway_connection

  location                           = var.location
  name                               = coalesce(each.value.name, "con-${var.name}-${each.key}")
  resource_group_name                = coalesce(each.value.resource_group_name, local.resource_group_name)
  type                               = each.value.type
  virtual_network_gateway_id         = azapi_resource.vgw.id
  authorization_key                  = try(local.azurerm_virtual_network_gateway_connection_sensitive[each.key].authorization_key, null)
  connection_mode                    = try(each.value.connection_mode, null)
  connection_protocol                = try(each.value.connection_protocol, null)
  dpd_timeout_seconds                = try(each.value.dpd_timeout_seconds, null)
  egress_nat_rule_ids                = try(each.value.egress_nat_rule_ids, null)
  enable_bgp                         = try(each.value.enable_bgp, null)
  express_route_circuit_id           = try(each.value.express_route_circuit_id, null)
  express_route_gateway_bypass       = try(each.value.express_route_gateway_bypass, null)
  ingress_nat_rule_ids               = try(each.value.ingress_nat_rule_ids, null)
  local_azure_ip_address_enabled     = try(each.value.local_azure_ip_address_enabled, null)
  local_network_gateway_id           = try(azurerm_local_network_gateway.vgw[trimprefix(each.key, "lgw-")].id, each.value.local_network_gateway_id, null)
  peer_virtual_network_gateway_id    = try(each.value.peer_virtual_network_gateway_id, null)
  private_link_fast_path_enabled     = try(each.value.private_link_fast_path_enabled, null)
  routing_weight                     = each.value.routing_weight
  shared_key                         = try(local.azurerm_virtual_network_gateway_connection_sensitive[each.key].shared_key, null)
  tags                               = merge(var.tags, each.value.tags)
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
}

resource "azurerm_express_route_circuit_peering" "vgw" {
  for_each = local.azurerm_express_route_circuit_peering

  express_route_circuit_name    = each.value.express_route_circuit_name
  peering_type                  = each.value.peering_type
  resource_group_name           = coalesce(each.value.resource_group_name, local.resource_group_name)
  vlan_id                       = each.value.vlan_id
  ipv4_enabled                  = each.value.ipv4_enabled
  peer_asn                      = each.value.peer_asn
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  route_filter_id               = each.value.route_filter_id
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  shared_key                    = local.azurerm_express_route_circuit_peering_sensitive[each.key].shared_key

  dynamic "microsoft_peering_config" {
    for_each = each.value.microsoft_peering_config == null ? [] : ["MicrosoftPeeringConfig"]

    content {
      advertised_public_prefixes = each.value.microsoft_peering_config.advertised_public_prefixes
      advertised_communities     = each.value.microsoft_peering_config.advertised_communities
      customer_asn               = each.value.microsoft_peering_config.customer_asn
      routing_registry_name      = each.value.microsoft_peering_config.routing_registry_name
    }
  }
}
