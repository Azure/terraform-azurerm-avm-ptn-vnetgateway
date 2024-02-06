variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}

variable "name" {
  type        = string
  description = "The name of the Virtual Network Gateway."
}

variable "sku" {
  type        = string
  description = "The SKU (size) of the Virtual Network Gateway."

  validation {
    condition     = contains(["Basic", "HighPerformance", "Standard", "UltraPerformance", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ"], var.sku)
    error_message = "sku possible values are Basic, HighPerformance, Standard, UltraPerformance, VpnGw1, VpnGw2, VpnGw3, VpnGw4, VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ, VpnGw4AZ, VpnGw5AZ, ErGw1AZ, ErGw2AZ, ErGw3AZ."
  }
}

variable "type" {
  type        = string
  description = "The type of the Virtual Network Gateway, ExpressRoute or VPN."

  validation {
    condition     = contains(["ExpressRoute", "Vpn"], var.type)
    error_message = "type possible values are ExpressRoute or VPN."
  }
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the Virtual Network."
}

variable "virtual_network_resource_group_name" {
  type        = string
  description = "The name of the Virtual Network's Resource Group."
}

variable "default_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources."
  nullable    = false
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "The availability zone of the Virtual Network Gateway. Only supported for AZ SKUs."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see https://aka.ms/avm/telemetryinfo.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "express_route_circuits" {
  type = map(object({
    id                  = string
    resource_group_name = optional(string, null)
    connection = optional(object({
      authorization_key            = optional(string, null)
      express_route_gateway_bypass = optional(bool, null)
      name                         = optional(string, null)
      routing_weight               = optional(number, null)
      shared_key                   = optional(string, null)
      tags                         = optional(map(string), {})
    }), null)
    peering = optional(object({
      peering_type                  = string
      vlan_id                       = number
      ipv4_enabled                  = optional(bool, true)
      peer_asn                      = optional(number, null)
      primary_peer_address_prefix   = optional(string, null)
      secondary_peer_address_prefix = optional(string, null)
      shared_key                    = optional(string, null)
      route_filter_id               = optional(string, null)
      microsoft_peering_config = optional(object({
        advertised_public_prefixes = list(string)
        advertised_communities     = optional(list(string), null)
        customer_asn               = optional(number, null)
        routing_registry_name      = optional(string, null)
      }), null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
Map of Virtual Network Gateway Connections and Peering Configurations to create for existing ExpressRoute circuits.

- `id` - (Required) The ID of the ExpressRoute circuit.

- `connection` - (Optional) a `connection` block as defined below. Used to configure the Virtual Network Gateway Connection between the ExpressRoute Circuit and the Virtual Network Gateway.
  - `authorization_key` - (Optional) The authorization key for the ExpressRoute Circuit.
  - `express_route_gateway_bypass` - (Optional) Whether to bypass the ExpressRoute Gateway for data forwarding.
  - `name` - (Optional) The name of the Virtual Network Gateway Connection.
  - `routing_weight` - (Optional) The weight added to routes learned from this Virtual Network Gateway Connection. Defaults to 10.
  - `shared_key` - (Optional) The shared key for the Virtual Network Gateway Connection.
  - `tags` - (Optional) A mapping of tags to assign to the resource.

- `peering` - (Optional) a `peering` block as defined below. Used to configure the ExpressRoute Circuit Peering.
  - `peering_type` - (Required) The type of the peering. Possible values are AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering.
  - `vlan_id` - (Required) The VLAN ID for the peering.
  - `ipv4_enabled` - (Optional) Whether IPv4 is enabled on the peering. Defaults to true.
  - `peer_asn` - (Optional) The peer ASN.
  - `primary_peer_address_prefix` - (Optional) The primary address prefix.
  - `secondary_peer_address_prefix` - (Optional) The secondary address prefix.
  - `shared_key` - (Optional) The shared key for the peering.
  - `route_filter_id` - (Optional) The ID of the route filter to apply to the peering.
  - `microsoft_peering_config` - (Optional) a `microsoft_peering_config` block as defined below. Used to configure the Microsoft Peering.
    - `advertised_communities` - (Optional) The list of communities to advertise to the Microsoft Peering.
    - `advertised_public_prefixes` - (Required) The list of public prefixes to advertise to the Microsoft Peering.
    - `customer_asn` - (Optional) The customer ASN.
    - `routing_registry_name` - (Optional) The routing registry name.
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.express_route_circuits == null ? true : alltrue([for k, v in var.express_route_circuits : contains(["AzurePrivatePeering", "AzurePublicPeering", "MicrosoftPeering"], v.peering.peering_type) if v.peering != null])
    error_message = "peering_type possible values are AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering."
  }
}

variable "ip_configurations" {
  type = map(object({
    ip_configuration_name         = optional(string, null)
    apipa_addresses               = optional(list(string), null)
    private_ip_address_allocation = optional(string, "Dynamic")
    public_ip = optional(object({
      name              = optional(string, null)
      allocation_method = optional(string, "Dynamic")
      sku               = optional(string, "Basic")
      tags              = optional(map(string), {})
    }), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Map of IP Configurations to create for the Virtual Network Gateway.

- `ip_configuration_name` - (Optional) The name of the IP Configuration.
- `apipa_addresses` - (Optional) The list of APPIPA addresses.
- `private_ip_address_allocation` - (Optional) The private IP allocation method. Possible values are Static or Dynamic. Defaults to Dynamic.
- `public_ip` - (Optional) a `public_ip` block as defined below. Used to configure the Public IP Address for the IP Configuration.
  - `name` - (Optional) The name of the Public IP Address.
  - `allocation_method` - (Optional) The allocation method of the Public IP Address. Possible values are Static or Dynamic. Defaults to Dynamic.
  - `sku` - (Optional) The SKU of the Public IP Address. Possible values are Basic or Standard. Defaults to Basic.
  - `tags` - (Optional) A mapping of tags to assign to the resource.
DESCRIPTION
  nullable    = false
}

variable "local_network_gateways" {
  type = map(object({
    id              = optional(string, null)
    name            = optional(string, null)
    address_space   = optional(list(string), null)
    gateway_fqdn    = optional(string, null)
    gateway_address = optional(string, null)
    tags            = optional(map(string), {})
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number, null)
    }), null)
    connection = optional(object({
      name                               = optional(string, null)
      type                               = string
      connection_mode                    = optional(string, null)
      connection_protocol                = optional(string, null)
      dpd_timeout_seconds                = optional(number, null)
      egress_nat_rule_ids                = optional(list(string), null)
      enable_bgp                         = optional(bool, null)
      ingress_nat_rule_ids               = optional(list(string), null)
      local_azure_ip_address_enabled     = optional(bool, null)
      peer_virtual_network_gateway_id    = optional(string, null)
      routing_weight                     = optional(number, null)
      shared_key                         = optional(string, null)
      tags                               = optional(map(string), null)
      use_policy_based_traffic_selectors = optional(bool, null)
      custom_bgp_addresses = optional(object({
        primary   = string
        secondary = string
      }), null)
      ipsec_policy = optional(object({
        dh_group         = string
        ike_encryption   = string
        ike_integrity    = string
        ipsec_encryption = string
        ipsec_integrity  = string
        pfs_group        = string
        sa_datasize      = optional(number, null)
        sa_lifetime      = optional(number, null)
      }), null)
      traffic_selector_policy = optional(list(
        object({
          local_address_prefixes  = list(string)
          remote_address_prefixes = list(string)
        })
      ), null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
Map of Local Network Gateways and Virtual Network Gateway Connections to create for the Virtual Network Gateway.

- `id` - (Optional) The ID of the pre-exisitng Local Network Gateway.
- `name` - (Optional) The name of the Local Network Gateway to create.
- `address_space` - (Optional) The list of address spaces for the Local Network Gateway.
- `gateway_fqdn` - (Optional) The gateway FQDN for the Local Network Gateway.
- `gateway_address` - (Optional) The gateway IP address for the Local Network Gateway.
- `tags` - (Optional) A mapping of tags to assign to the resource.
- `bgp_settings` - (Optional) a `bgp_settings` block as defined below. Used to configure the BGP settings for the Local Network Gateway.
  - `asn` - (Required) The ASN of the Local Network Gateway.
  - `bgp_peering_address` - (Required) The BGP peering address of the Local Network Gateway.
  - `peer_weight` - (Optional) The weight added to routes learned from this BGP speaker.

- `connection` - (Optional) a `connection` block as defined below. Used to configure the Virtual Network Gateway Connection for the Local Network Gateway.
  - `name` - (Optional) The name of the Virtual Network Gateway Connection.
  - `type` - (Required) The type of Virtual Network Gateway Connection. Possible values are IPsec or Vnet2Vnet.
  - `connection_mode` - (Optional) The connection mode.
  - `connection_protocol` - (Optional) The connection protocol. Possible values are IKEv2 or IKEv1.
  - `dpd_timeout_seconds` - (Optional) The dead peer detection timeout in seconds.
  - `egress_nat_rule_ids` - (Optional) The list of egress NAT rule IDs.
  - `enable_bgp` - (Optional) Whether or not BGP is enabled for this Virtual Network Gateway Connection.
  - `ingress_nat_rule_ids` - (Optional) The list of ingress NAT rule IDs.
  - `local_azure_ip_address_enabled` - (Optional) Whether or not the local Azure IP address is enabled.
  - `peer_virtual_network_gateway_id` - (Optional) The ID of the peer Virtual Network Gateway.
  - `routing_weight` - (Optional) The routing weight.
  - `shared_key` - (Optional) The shared key.
  - `tags` - (Optional) A mapping of tags to assign to the resource.
  - `use_policy_based_traffic_selectors` - (Optional) Whether or not to use policy based traffic selectors.
  - `custom_bgp_addresses` - (Optional) a `custom_bgp_addresses` block as defined below. Used to configure the custom BGP addresses for the Virtual Network Gateway Connection.
    - `primary` - (Required) The primary custom BGP address.
    - `secondary` - (Required) The secondary custom BGP address.
  - `ipsec_policy` - (Optional) a `ipsec_policy` block as defined below. Used to configure the IPsec policy for the Virtual Network Gateway Connection.
    - `dh_group` - (Required) The DH Group used in IKE Phase 1 for initial SA.
    - `ike_encryption` - (Required) The IKE encryption algorithm (IKE phase 2).
    - `ike_integrity` - (Required) The IKE integrity algorithm (IKE phase 2).
    - `ipsec_encryption` - (Required) The IPSec encryption algorithm (IKE phase 1).
    - `ipsec_integrity` - (Required) The IPSec integrity algorithm (IKE phase 1).
    - `pfs_group` - (Required) The Pfs Group used in IKE Phase 2 for new child SA.
    - `sa_datasize` - (Optional) The IPSec Security Association (also called Quick Mode or Phase 2 SA) data size specified in KB for a policy.
    - `sa_lifetime` - (Optional) The IPSec Security Association (also called Quick Mode or Phase 2 SA) lifetime specified in seconds for a policy.
  - `traffic_selector_policy` - (Optional) a `traffic_selector_policy` block as defined below. Used to configure the traffic selector policy for the Virtual Network Gateway Connection.
    - `local_address_prefixes` - (Required) The list of local address prefixes.
    - `remote_address_prefixes` - (Required) The list of remote address prefixes.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = var.local_network_gateways == null ? true : alltrue([for k, v in var.local_network_gateways : (v.gateway_fqdn == null && v.gateway_address == null ? false : true) if v.id == null])
    error_message = "At least one of gateway_fqdn or gateway_address must be specified for local_network_gateways."
  }
}

variable "route_table_bgp_route_propagation_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to enable BGP route propagation on the Route Table."
  nullable    = false
}

variable "route_table_creation_enabled" {
  type        = bool
  default     = false
  description = "Whether or not to create a Route Table associated with the Virtual Network Gateway Subnet."
  nullable    = false
}

variable "route_table_name" {
  type        = string
  default     = null
  description = "Name of the Route Table associated with Virtual Network Gateway Subnet."
}

variable "route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the Route Table."
  nullable    = false
}

variable "subnet_address_prefix" {
  type        = string
  default     = ""
  description = "The address prefix for the gateway subnet. Either subnet_id or subnet_address_prefix must be specified."
  nullable    = false
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "The ID of a pre-existing gateway subnet to use for the Virtual Network Gateway. Either subnet_id or subnet_address_prefix must be specified."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the Virtual Network Gateway."
  nullable    = false
}

variable "tracing_tags_enabled" {
  type        = bool
  default     = false
  description = "Whether enable tracing tags that generated by BridgeCrew Yor."
  nullable    = false
}

variable "tracing_tags_prefix" {
  type        = string
  default     = "avm_"
  description = "Default prefix for generated tracing tags"
  nullable    = false
}

variable "vpn_active_active_enabled" {
  type        = bool
  default     = false
  description = "Enable active-active mode for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_bgp_enabled" {
  type        = bool
  default     = false
  description = "Enable BGP for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_bgp_settings" {
  type = object({
    asn         = optional(number, null)
    peer_weight = optional(number, null)
  })
  default     = null
  description = "BGP settings for the Virtual Network Gateway."
}

variable "vpn_generation" {
  type        = string
  default     = null
  description = "value for the Generation for the Gateway, Valid values are 'Generation1', 'Generation2'. Options differ depending on SKU."

  validation {
    condition     = var.vpn_generation == null ? true : contains(["Generation1", "Generation2"], var.vpn_generation)
    error_message = "vpn_generation possible values are 'Generation1', 'Generation2'. Options differ depending on SKU."
  }
}

variable "vpn_point_to_site" {
  type = object({
    address_space         = list(string)
    aad_tenant            = optional(string, null)
    aad_audience          = optional(string, null)
    aad_issuer            = optional(string, null)
    radius_server_address = optional(string, null)
    radius_server_secret  = optional(string, null)
    root_certificate = optional(map(object({
      name             = string
      public_cert_data = string
    })), {})
    revoked_certificate = optional(map(object({
      name       = string
      thumbprint = string
    })), {})
    vpn_client_protocols = optional(list(string), null)
    vpn_auth_types       = optional(list(string), null)
  })
  default     = null
  description = <<DESCRIPTION
Point to site configuration for the virtual network gateway.

- `address_space` - (Required) Address space for the virtual network gateway.
- `aad_tenant` - (Optional) The AAD tenant to use for authentication.
- `aad_audience` - (Optional) The AAD audience to use for authentication.
- `aad_issuer` - (Optional) The AAD issuer to use for authentication.
- `radius_server_address` - (Optional) The address of the radius server.
- `radius_server_secret` - (Optional) The secret of the radius server.
- `root_certificate` - (Optional) The root certificate of the virtual network gateway.
  - `name` - (Required) The name of the root certificate.
  - `public_cert_data` - (Required) The public certificate data.
- `revoked_certificate` - (Optional) The revoked certificate of the virtual network gateway.
  - `name` - (Required) The name of the revoked certificate.
  - `thumbprint` - (Required) The thumbprint of the revoked certificate.
- `vpn_client_protocols` - (Optional) The VPN client protocols.
- `vpn_auth_types` - (Optional) The VPN authentication types.
DESCRIPTION
}

variable "vpn_private_ip_address_enabled" {
  type        = bool
  default     = null
  description = "Enable private IP address for the Virtual Network Gateway for Virtual Network Gateway Connections. Only supported for AZ SKUs."
}

variable "vpn_type" {
  type        = string
  default     = "RouteBased"
  description = "The VPN type of the Virtual Network Gateway."
  nullable    = false

  validation {
    condition     = contains(["PolicyBased", "RouteBased"], var.vpn_type)
    error_message = "vpn_type possible values are PolicyBased or RouteBased."
  }
}
