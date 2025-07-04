locals {
  azurerm_express_route_circuit_peering           = nonsensitive(sensitive(local.express_route_circuit_peerings))
  azurerm_express_route_circuit_peering_sensitive = local.express_route_circuit_peerings
  azurerm_local_network_gateway = {
    for local_network_gateway_key, local_network_gateway in var.local_network_gateways : local_network_gateway_key => local_network_gateway if local_network_gateway.id == null
  }
  azurerm_public_ip = var.hosted_on_behalf_of_public_ip_enabled ? {} : {
    for ip_configuration_key, ip_configuration in local.ip_configurations : ip_configuration_key => {
      name                    = ip_configuration.public_ip.name
      resource_group_name     = ip_configuration.public_ip.resource_group_name
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
      peer_weight = try(var.vpn_bgp_settings.peer_weight, 0)
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
        public_ip_address_id          = var.hosted_on_behalf_of_public_ip_enabled ? null : (ip_configuration.public_ip.creation_enabled ? azurerm_public_ip.vgw[ip_configuration_key].id : ip_configuration.public_ip.id)
        subnet_id                     = var.subnet_creation_enabled ? azurerm_subnet.vgw[0].id : var.virtual_network_gateway_subnet_id
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
  # Transform edge_zone string to extendedLocation object for AzAPI
  extended_location = var.edge_zone != null ? {
    name = var.edge_zone
    type = "EdgeZone"
  } : null
  virtual_network_gateway_properties = {
    # Common properties for all gateway types
    gatewayType = var.type
    sku = {
      name = var.sku
      tier = var.sku
    }
    # IP Configurations
    ipConfigurations = [
      for key, ip_config in local.azurerm_virtual_network_gateway.ip_configuration : {
        name = ip_config.name
        properties = merge(
          {
            privateIPAllocationMethod = ip_config.private_ip_address_allocation
            subnet = {
              id = ip_config.subnet_id
            }
          },
          ip_config.public_ip_address_id != null ? {
            publicIPAddress = {
              id = ip_config.public_ip_address_id
            }
          } : {}
        )
      }
    ]
    # Dynamic VPN-specific properties
    vpnType                         = var.type == "Vpn" ? var.vpn_type : "RouteBased"
    activeActive                    = var.type == "Vpn" && var.vpn_active_active_enabled == true ? true : false
    enableBgp                       = var.type == "Vpn" && var.vpn_bgp_enabled == true ? true : false
    vpnGatewayGeneration            = var.type == "Vpn" && var.vpn_generation != null ? var.vpn_generation : null
    enablePrivateIpAddress          = var.type == "Vpn" && var.vpn_private_ip_address_enabled == true ? true : false
    enableBgpRouteTranslationForNat = var.type == "Vpn" && var.vpn_bgp_route_translation_for_nat_enabled == true ? true : null
    enableDnsForwarding             = var.type == "Vpn" && var.vpn_dns_forwarding_enabled == true ? true : null
    disableIPSecReplayProtection    = var.type == "Vpn" && var.vpn_ip_sec_replay_protection_enabled == false ? true : null
    # VPN gateway default site
    gatewayDefaultSite = var.type == "Vpn" && var.vpn_default_local_network_gateway_id != null ? {
      id = var.vpn_default_local_network_gateway_id
    } : null
    # BGP Settings
    bgpSettings = var.type == "Vpn" && var.vpn_bgp_enabled == true ? {
      asn        = local.azurerm_virtual_network_gateway.bgp_settings.asn
      peerWeight = local.azurerm_virtual_network_gateway.bgp_settings.peer_weight
      bgpPeeringAddresses = [
        for key, peering_addr in local.azurerm_virtual_network_gateway.bgp_settings.peering_addresses : {
          ipconfigurationId    = "${var.parent_id}/providers/Microsoft.Network/virtualNetworkGateways/${var.name}/ipConfigurations/${peering_addr.ip_configuration_name}"
          customBgpIpAddresses = peering_addr.apipa_addresses
        }
      ]
    } : null
    # Custom Routes
    customRoutes = var.type == "Vpn" && var.vpn_custom_route != null ? {
      addressPrefixes = var.vpn_custom_route.address_prefixes
    } : null
    # VPN Client Configuration
    vpnClientConfiguration = var.type == "Vpn" && var.vpn_point_to_site != null ? {
      vpnClientAddressPool = {
        addressPrefixes = var.vpn_point_to_site.address_space
      }
      vpnClientProtocols     = var.vpn_point_to_site.vpn_client_protocols
      vpnAuthenticationTypes = var.vpn_point_to_site.vpn_auth_types

      # AAD Authentication
      aadTenant   = var.vpn_point_to_site.aad_tenant
      aadAudience = var.vpn_point_to_site.aad_audience
      aadIssuer   = var.vpn_point_to_site.aad_issuer

      # RADIUS Authentication
      radiusServerAddress = var.vpn_point_to_site.radius_server_address
      radiusServerSecret  = var.vpn_point_to_site.radius_server_secret
      radiusServers = [
        for radius_server in var.vpn_point_to_site.radius_servers : {
          radiusServerAddress = radius_server.address
          radiusServerScore   = radius_server.score
          radiusServerSecret  = radius_server.secret
        }
      ]

      # IPSec Policy
      vpnClientIpsecPolicies = var.vpn_point_to_site.ipsec_policy != null ? [{
        dhGroup             = var.vpn_point_to_site.ipsec_policy.dh_group
        ikeEncryption       = var.vpn_point_to_site.ipsec_policy.ike_encryption
        ikeIntegrity        = var.vpn_point_to_site.ipsec_policy.ike_integrity
        ipsecEncryption     = var.vpn_point_to_site.ipsec_policy.ipsec_encryption
        ipsecIntegrity      = var.vpn_point_to_site.ipsec_policy.ipsec_integrity
        pfsGroup            = var.vpn_point_to_site.ipsec_policy.pfs_group
        saDataSizeKilobytes = var.vpn_point_to_site.ipsec_policy.sa_data_size_in_kilobytes
        saLifeTimeSeconds   = var.vpn_point_to_site.ipsec_policy.sa_lifetime_in_seconds
      }] : []

      # Root Certificates
      vpnClientRootCertificates = [
        for root_cert in var.vpn_point_to_site.root_certificates : {
          name           = root_cert.name
          publicCertData = root_cert.public_cert_data
        }
      ]

      # Revoked Certificates
      vpnClientRevokedCertificates = [
        for revoked_cert in var.vpn_point_to_site.revoked_certificates : {
          name       = revoked_cert.name
          thumbprint = revoked_cert.thumbprint
        }
      ]

      # Virtual Network Gateway Client Connections
      vngClientConnectionConfigurations = [
        for client_conn in var.vpn_point_to_site.virtual_network_gateway_client_connections : {
          name = client_conn.name
          properties = {
            vpnClientAddressPool = {
              addressPrefixes = client_conn.address_prefixes
            }
            virtualNetworkGatewayPolicyGroups = [
              for policy_group_name in client_conn.policy_group_names : {
                id = "${var.parent_id}/providers/Microsoft.Network/virtualNetworkGateways/${var.name}/virtualNetworkGatewayPolicyGroups/${policy_group_name}"
              }
            ]
          }
        }
      ]
    } : null
    # VPN Policy Groups
    virtualNetworkGatewayPolicyGroups = var.type == "Vpn" && length(var.vpn_policy_groups) > 0 ? [
      for policy_group in var.vpn_policy_groups : {
        name = policy_group.name
        properties = {
          isDefault = policy_group.is_default
          priority  = policy_group.priority
          policyMembers = [
            for policy_member in policy_group.policy_members : {
              name           = policy_member.name
              attributeType  = policy_member.type
              attributeValue = policy_member.value
            }
          ]
        }
      }
    ] : null
    # Express Route specific properties
    allowRemoteVnetTraffic = var.type == "ExpressRoute" ? var.express_route_remote_vnet_traffic_enabled : null
    allowVirtualWanTraffic = var.type == "ExpressRoute" ? var.express_route_virtual_wan_traffic_enabled : null
  }
  # Filter out null values from the properties
  virtual_network_gateway_properties_filtered = {
    for k, v in local.virtual_network_gateway_properties : k => v if v != null
  }
}
locals {
  resource_group_name  = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).resource_group_name
  virtual_network_name = var.subnet_creation_enabled ? basename(var.virtual_network_id) : ""
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
