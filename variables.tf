variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
}

variable "name" {
  type        = string
  description = "The name of the virtual network gateway."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group."
}

variable "sku" {
  type        = string
  description = "The SKU (size) of the virtual network gateway."

  validation {
    condition     = contains(["Basic", "HighPerformance", "Standard", "UltraPerformance", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ"], var.sku)
    error_message = "sku possible values are Basic, HighPerformance, Standard, UltraPerformance, VpnGw1, VpnGw2, VpnGw3, VpnGw4, VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ, VpnGw4AZ, VpnGw5AZ."
  }
}

variable "subnet_address_prefix" {
  type        = string
  description = "The address prefix for the gateway subnet."
}

variable "type" {
  type        = string
  description = "The type of the virtual network gateway, ExpressRoute or VPN."

  validation {
    condition     = contains(["ExpressRoute", "Vpn"], var.type)
    error_message = "type possible values are ExpressRoute or VPN."
  }
}

variable "virtual_network_name" {
  type        = string
  description = "The name of the virtual network."
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
  description = "The availability zone of the virtual network gateway. Only supported for AZ SKUs."
}

variable "express_route_circuits" {
  type = map(object({
    express_route_circuit_id = string
    connection_config = optional(object({
      authorization_key            = optional(string, null)
      express_route_gateway_bypass = optional(bool, null)
      name                         = optional(string, null)
      routing_weight               = optional(number, null)
      shared_key                   = optional(string, null)
      tags                         = optional(map(string), {})
    }), null)
    peering_config = optional(object({
      peering_type                  = string
      vlan_id                       = number
      ipv4_enabled                  = optional(bool, null)
      peer_asn                      = optional(number, null)
      primary_peer_address_prefix   = optional(number, null)
      secondary_peer_address_prefix = optional(string, null)
      shared_key                    = optional(string, null)
      route_filter_id               = optional(string, null)
      microsoft_peering_config = optional(object({
        advertised_communities     = optional(list(string), null)
        advertised_public_prefixes = list(string)
        customer_asn               = optional(number, null)
        routing_registry_name      = optional(string, null)
      }), null)
    }), null)
  }))
  default     = {}
  description = "Express Route circuits configuration."
  nullable    = false

  validation {
    condition     = var.express_route_circuits == null ? true : alltrue([for k, v in var.express_route_circuits : contains(["AzurePrivatePeering", "AzurePublicPeering", "MicrosoftPeering"], v.peering_config.peering_type)])
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
  description = "IP configurations for the virtual network gateway."
  nullable    = false
}

variable "local_network_gateways" {
  type = map(object({
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
    connection_config = optional(object({
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
  description = "Local network gateways configuration."
  nullable    = false

  validation {
    condition     = var.local_network_gateways == null ? true : alltrue([for k, v in var.local_network_gateways : v.gateway_fqdn == null && v.gateway_address == null ? false : true])
    error_message = "At least one of gateway_fqdn or gateway_address must be specified for local_network_gateways."
  }
}

variable "route_table_bgp_route_propagation_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to enable BGP route propagation on the route table."
  nullable    = false
}

variable "route_table_creation_enabled" {
  type        = bool
  default     = false
  description = "Whether or not to create a route table associated with the Virtual Network Gateway Subnet."
  nullable    = false
}

variable "route_table_name" {
  type        = string
  default     = null
  description = "Name of the route table associated with Virtual Network Gateway Subnet."
}

variable "route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the route table."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the virtual network gateway."
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
  description = "Enable active-active mode for the virtual network gateway."
  nullable    = false
}

variable "vpn_bgp_enabled" {
  type        = bool
  default     = false
  description = "Enable BGP for the virtual network gateway."
  nullable    = false
}

variable "vpn_bgp_settings" {
  type = object({
    asn         = optional(number, null)
    peer_weight = optional(number, null)
  })
  default     = null
  description = "BGP settings for the virtual network gateway."
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

variable "vpn_private_ip_address_enabled" {
  type        = bool
  default     = null
  description = "Enable private IP address for the virtual network gateway for Virtual Network Gateway Connections. Only supported for AZ SKUs."
}

variable "vpn_type" {
  type        = string
  default     = "RouteBased"
  description = "The VPN type of the virtual network gateway."
  nullable    = false

  validation {
    condition     = contains(["PolicyBased", "RouteBased"], var.vpn_type)
    error_message = "vpn_type possible values are PolicyBased or RouteBased."
  }
}
