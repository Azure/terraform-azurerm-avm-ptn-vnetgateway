resource "azurerm_subnet" "vgw" {
  count = var.subnet_creation_enabled ? 1 : 0

  address_prefixes     = [var.subnet_address_prefix]
  name                 = "GatewaySubnet"
  resource_group_name  = local.virtual_network_resource_group_name
  virtual_network_name = local.virtual_network_name
}

resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = var.location
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = coalesce(var.route_table_resource_group_name, local.virtual_network_resource_group_name)
  bgp_route_propagation_enabled = !var.route_table_bgp_route_propagation_enabled
  tags                          = merge(var.tags, var.route_table_tags)
}

resource "azurerm_subnet_route_table_association" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  route_table_id = azurerm_route_table.vgw[0].id
  subnet_id      = try(azurerm_subnet.vgw[0].id, local.subnet_id)

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
  resource_group_name     = coalesce(each.value.resource_group_name, local.virtual_network_resource_group_name)
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

resource "azurerm_virtual_network_gateway" "vgw" {
  location                              = var.location
  name                                  = var.name
  resource_group_name                   = local.virtual_network_resource_group_name
  sku                                   = var.sku
  type                                  = var.type
  active_active                         = var.type == "Vpn" ? var.vpn_active_active_enabled : null
  bgp_route_translation_for_nat_enabled = var.type == "Vpn" ? var.vpn_bgp_route_translation_for_nat_enabled : null
  default_local_network_gateway_id      = var.type == "Vpn" ? var.vpn_default_local_network_gateway_id : null
  dns_forwarding_enabled                = var.type == "Vpn" ? var.vpn_dns_forwarding_enabled : null
  edge_zone                             = var.edge_zone
  enable_bgp                            = var.type == "Vpn" ? var.vpn_bgp_enabled : null
  generation                            = var.type == "Vpn" ? var.vpn_generation : null
  ip_sec_replay_protection_enabled      = var.type == "Vpn" ? var.vpn_ip_sec_replay_protection_enabled : null
  private_ip_address_enabled            = var.type == "Vpn" ? var.vpn_private_ip_address_enabled : null
  remote_vnet_traffic_enabled           = var.express_route_remote_vnet_traffic_enabled
  tags                                  = var.tags
  virtual_wan_traffic_enabled           = var.express_route_virtual_wan_traffic_enabled
  vpn_type                              = var.type == "Vpn" ? var.vpn_type : null

  dynamic "ip_configuration" {
    for_each = local.azurerm_virtual_network_gateway.ip_configuration

    content {
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
      subnet_id                     = ip_configuration.value.subnet_id
      name                          = ip_configuration.value.name
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
    }
  }
  dynamic "bgp_settings" {
    for_each = var.vpn_bgp_enabled == true && var.type == "Vpn" ? ["BgpSettings"] : []

    content {
      asn         = local.azurerm_virtual_network_gateway.bgp_settings.asn
      peer_weight = local.azurerm_virtual_network_gateway.bgp_settings.peer_weight

      dynamic "peering_addresses" {
        for_each = local.azurerm_virtual_network_gateway.bgp_settings.peering_addresses

        content {
          apipa_addresses       = peering_addresses.value.apipa_addresses
          ip_configuration_name = peering_addresses.value.ip_configuration_name
        }
      }
    }
  }
  dynamic "custom_route" {
    for_each = var.vpn_custom_route == null || var.type != "Vpn" ? [] : ["CustomRoute"]

    content {
      address_prefixes = var.vpn_custom_route.address_prefixes
    }
  }
  dynamic "policy_group" {
    for_each = var.vpn_policy_groups

    content {
      name       = policy_group.value.name
      is_default = policy_group.value.is_default
      priority   = policy_group.value.priority

      dynamic "policy_member" {
        for_each = policy_group.value.policy_members

        content {
          name  = policy_member.value.name
          type  = policy_member.value.type
          value = policy_member.value.value
        }
      }
    }
  }
  dynamic "vpn_client_configuration" {
    for_each = var.vpn_point_to_site == null || var.type != "Vpn" ? [] : ["VpnClientConfiguration"]

    content {
      address_space         = var.vpn_point_to_site.address_space
      aad_audience          = var.vpn_point_to_site.aad_audience
      aad_issuer            = var.vpn_point_to_site.aad_issuer
      aad_tenant            = var.vpn_point_to_site.aad_tenant
      radius_server_address = var.vpn_point_to_site.radius_server_address
      radius_server_secret  = var.vpn_point_to_site.radius_server_secret
      vpn_auth_types        = var.vpn_point_to_site.vpn_auth_types
      vpn_client_protocols  = var.vpn_point_to_site.vpn_client_protocols

      dynamic "ipsec_policy" {
        for_each = var.vpn_point_to_site.ipsec_policy == null ? [] : ["IPSecPolicy"]

        content {
          dh_group                  = var.vpn_point_to_site.ipsec_policy.dh_group
          ike_encryption            = var.vpn_point_to_site.ipsec_policy.ike_encryption
          ike_integrity             = var.vpn_point_to_site.ipsec_policy.ike_integrity
          ipsec_encryption          = var.vpn_point_to_site.ipsec_policy.ipsec_encryption
          ipsec_integrity           = var.vpn_point_to_site.ipsec_policy.ipsec_integrity
          pfs_group                 = var.vpn_point_to_site.ipsec_policy.pfs_group
          sa_data_size_in_kilobytes = var.vpn_point_to_site.ipsec_policy.sa_data_size_in_kilobytes
          sa_lifetime_in_seconds    = var.vpn_point_to_site.ipsec_policy.sa_lifetime_in_seconds
        }
      }
      dynamic "radius_server" {
        for_each = var.vpn_point_to_site.radius_servers

        content {
          address = radius_server.value.address
          score   = radius_server.value.store
          secret  = radius_server.value.secret
        }
      }
      dynamic "revoked_certificate" {
        for_each = var.vpn_point_to_site.revoked_certificates

        content {
          name       = revoked_certificate.value.name
          thumbprint = revoked_certificate.value.thumbprint
        }
      }
      dynamic "root_certificate" {
        for_each = var.vpn_point_to_site.root_certificates

        content {
          name             = root_certificate.value.name
          public_cert_data = root_certificate.value.public_cert_data
        }
      }
      dynamic "virtual_network_gateway_client_connection" {
        for_each = var.vpn_point_to_site.virtual_network_gateway_client_connections

        content {
          address_prefixes   = virtual_network_gateway_client_connection.value.address_prefixes
          name               = virtual_network_gateway_client_connection.value.name
          policy_group_names = virtual_network_gateway_client_connection.value.policy_group_names
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.vpn_active_active_enabled == true && var.type == "Vpn" ? length(local.azurerm_virtual_network_gateway.ip_configuration) > 1 : true
      error_message = "An active-active gateway requires at least two IP configurations."
    }
  }
}

resource "azurerm_local_network_gateway" "vgw" {
  for_each = local.azurerm_local_network_gateway

  location            = var.location
  name                = coalesce(each.value.name, "lgw-${var.name}-${each.key}")
  resource_group_name = coalesce(each.value.resource_group_name, local.virtual_network_resource_group_name)
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
  resource_group_name                = coalesce(each.value.resource_group_name, local.virtual_network_resource_group_name)
  type                               = each.value.type
  virtual_network_gateway_id         = azurerm_virtual_network_gateway.vgw.id
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
  resource_group_name           = coalesce(each.value.resource_group_name, local.virtual_network_resource_group_name)
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
      advertised_public_prefixes = each.value.microsoft_advertised_public_prefixes
      advertised_communities     = each.value.microsoft_advertised_communities
      customer_asn               = each.value.microsoft_customer_asn
      routing_registry_name      = each.value.microsoft_routing_registry_name
    }
  }
}
