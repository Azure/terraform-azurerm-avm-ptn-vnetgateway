variable "location" {
  type        = string
  description = "The Azure region where the resources will be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the Virtual Network Gateway."
}

variable "parent_id" {
  type        = string
  description = "The id of the resource group in which to create the Virtual Network Gateway and associated resources."
  nullable    = false

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+$", var.parent_id))
    error_message = "parent_id must be a valid resource group id."
  }
}

variable "diagnostic_settings_virtual_network_gateway" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the gateway. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings_virtual_network_gateway : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings_virtual_network_gateway :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "edge_zone" {
  type        = string
  default     = null
  description = "Specifies the Edge Zone within the Azure Region where this Virtual Network Gateway should exist. Changing this forces a new Virtual Network Gateway to be created."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "express_route_circuits" {
  type = map(object({
    id = string
    connection = optional(object({
      resource_group_name            = optional(string, null)
      authorization_key              = optional(string, null)
      express_route_gateway_bypass   = optional(bool, null)
      private_link_fast_path_enabled = optional(bool, false)
      name                           = optional(string, null)
      routing_weight                 = optional(number, null)
      shared_key                     = optional(string, null)
      tags                           = optional(map(string), {})
    }), null)
    peering = optional(object({
      peering_type                  = string
      vlan_id                       = number
      resource_group_name           = optional(string, null)
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
  - `resource_group_name` - (Optional) The name of the resource group in which to create the Virtual Network Gateway Connection. Defaults to the resource group of the Virtual Network.
  - `authorization_key` - (Optional) The authorization key for the ExpressRoute Circuit.
  - `express_route_gateway_bypass` - (Optional) Whether to bypass the ExpressRoute Gateway for data forwarding.
  - `private_link_fast_path_enabled` - (Optional) Bypass the Express Route gateway when accessing private-links. When enabled express_route_gateway_bypass must be set to true. Defaults to false.
  - `name` - (Optional) The name of the Virtual Network Gateway Connection.
  - `routing_weight` - (Optional) The weight added to routes learned from this Virtual Network Gateway Connection. Defaults to 10.
  - `shared_key` - (Optional) The shared key for the Virtual Network Gateway Connection.
  - `tags` - (Optional) A mapping of tags to assign to the resource.

- `peering` - (Optional) a `peering` block as defined below. Used to configure the ExpressRoute Circuit Peering.
  - `peering_type` - (Required) The type of the peering. Possible values are AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering.
  - `vlan_id` - (Required) The VLAN ID for the peering.
  - `resource_group_name` - (Optional) The name of the resource group in which to put the ExpressRoute Circuit Peering. Defaults to the resource group of the Virtual Network Gateway.
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
    condition = var.express_route_circuits == null ? true : alltrue([
      for k, v in var.express_route_circuits : contains(["AzurePrivatePeering", "AzurePublicPeering", "MicrosoftPeering"], v.peering.peering_type) if v.peering != null
    ])
    error_message = "peering_type possible values are AzurePrivatePeering, AzurePublicPeering or MicrosoftPeering."
  }
  validation {
    condition = alltrue([
      for k, v in var.express_route_circuits : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/expressRouteCircuits/[^/]+$", v.id))
    ])
    error_message = "id must be a valid resource id."
  }
  validation {
    condition = alltrue([
      for k, v in var.express_route_circuits : v.connection != null && v.connection.private_link_fast_path_enabled == true ? v.connection.express_route_gateway_bypass == true : true
    ])
    error_message = "private_link_fast_path_enabled must be set to true when express_route_gateway_bypass is set to true."
  }
}

variable "express_route_remote_vnet_traffic_enabled" {
  type        = bool
  default     = false
  description = "Enabled ExpressRoute traffic incoming from other connected VNets"
  nullable    = false
}

variable "express_route_virtual_wan_traffic_enabled" {
  type        = bool
  default     = false
  description = "Enabled ExpressRoute traffic incoming from other connected VWANs"
  nullable    = false
}

variable "hosted_on_behalf_of_public_ip_enabled" {
  type        = bool
  default     = false
  description = "Whether or not to attach a Public IP Address for the Virtual Network Gateway. ExpressRoute Gateways are implementing HOBO (hosted on behalf of) public IPs. This is a breaking change and requires the public IP to be turned off and not assigned."
  nullable    = false
}

variable "ip_configurations" {
  type = map(object({
    name                          = optional(string, null)
    apipa_addresses               = optional(list(string), null)
    private_ip_address_allocation = optional(string, "Dynamic")
    public_ip = optional(object({
      creation_enabled        = optional(bool, true)
      id                      = optional(string, null)
      name                    = optional(string, null)
      resource_group_name     = optional(string, null)
      allocation_method       = optional(string, "Static")
      sku                     = optional(string, "Standard")
      tags                    = optional(map(string), {})
      zones                   = optional(list(number), [1, 2, 3])
      edge_zone               = optional(string, null)
      ddos_protection_mode    = optional(string, "VirtualNetworkInherited")
      ddos_protection_plan_id = optional(string, null)
      domain_name_label       = optional(string, null)
      idle_timeout_in_minutes = optional(number, null)
      ip_tags                 = optional(map(string), {})
      ip_version              = optional(string, "IPv4")
      public_ip_prefix_id     = optional(string, null)
      reverse_fqdn            = optional(string, null)
      sku_tier                = optional(string, "Regional")
    }), {})
  }))
  default     = {}
  description = <<DESCRIPTION
Map of IP Configurations to create for the Virtual Network Gateway.

- `name` - (Optional) The name of the IP Configuration.
- `apipa_addresses` - (Optional) The list of APPIPA addresses.
- `private_ip_address_allocation` - (Optional) The private IP allocation method. Possible values are Static or Dynamic. Defaults to Dynamic.
- `public_ip` - (Optional) a `public_ip` block as defined below. Used to configure the Public IP Address for the IP Configuration.
  - `id` - (Optional) The resource id of an existing public ip address to use for the IP Configuration.
  - `name` - (Optional) The name of the Public IP Address.
  - `resource_group_name` - (Optional) The name of the resource group in which to create the Public IP Address.
  - `allocation_method` - (Optional) The allocation method of the Public IP Address. Possible values are Static or Dynamic. Defaults to Dynamic.
  - `sku` - (Optional) The SKU of the Public IP Address. Possible values are Basic or Standard. Defaults to Standard.
  - `tags` - (Optional) A mapping of tags to assign to the resource.
  - `zones` - (Optional) The list of availability zones for the Public IP Address.
  - `edge_zone` - (Optional) Specifies the Edge Zone within the Azure Region where this Public IP should exist. Changing this forces a new Public IP to be created.
  - `ddos_protection_mode` - (Optional) The DDoS protection mode of the Public IP Address. Possible values are Disabled, Enabled or VirtualNetworkInherited. Defaults to VirtualNetworkInherited.
  - `ddos_protection_plan_id` - (Optional) The ID of the DDoS protection plan for the Public IP Address.
  - `domain_name_label` - (Optional) The domain name label for the Public IP Address.
  - `idle_timeout_in_minutes` - (Optional) The idle timeout in minutes for the Public IP Address.
  - `ip_tags` - (Optional) A mapping of IP tags to assign to the resource.
  - `ip_version` - (Optional) The IP version of the Public IP Address. Possible values are IPv4 or IPv6. Defaults to IPv4.
  - `public_ip_prefix_id` - (Optional) The ID of the Public IP Prefix for the Public IP Address.
  - `reverse_fqdn` - (Optional) The reverse FQDN for the Public IP Address.
  - `sku_tier` - (Optional) The tier of the Public IP Address. Possible values are Regional or Global. Defaults to Regional.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.ip_configurations : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/publicIPAddresses/[^/]+$", v.public_ip.id))
      if v.public_ip != null && v.public_ip.id != null
    ])
    error_message = "public_ip.id must be a valid resource id."
  }
  validation {
    condition     = alltrue([for _, v in var.ip_configurations : (v.public_ip.creation_enabled == false ? v.public_ip.id != null : true) || (v.public_ip.id != null ? v.public_ip.creation_enabled == false : true) if v.public_ip != null])
    error_message = "id must be specified when creation_enabled is false."
  }
}

variable "local_network_gateways" {
  type = map(object({
    id                  = optional(string, null)
    name                = optional(string, null)
    resource_group_name = optional(string, null)
    address_space       = optional(list(string), null)
    gateway_fqdn        = optional(string, null)
    gateway_address     = optional(string, null)
    tags                = optional(map(string), {})
    bgp_settings = optional(object({
      asn                 = number
      bgp_peering_address = string
      peer_weight         = optional(number, null)
    }), null)
    connection = optional(object({
      name                               = optional(string, null)
      resource_group_name                = optional(string, null)
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
  - `resource_group_name` - (Optional) The name of the resource group in which to create the Virtual Network Gateway Connection. Defaults to the resource group of the Virtual Network.
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
  validation {
    condition = alltrue([
      for k, v in var.local_network_gateways : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/localNetworkGateways/[^/]+$", v.id))
      if v.id != null
    ])
    error_message = "id must be a valid resource id."
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

variable "route_table_resource_group_name" {
  type        = string
  default     = null
  description = "The name of the resource group in which to create the Route Table. If left blank, the resource group of the virtual network will be used."
}

variable "route_table_tags" {
  type        = map(string)
  default     = {}
  description = "Tags for the Route Table."
  nullable    = false
}

variable "sku" {
  type        = string
  default     = "ErGw1AZ"
  description = "The SKU (size) of the Virtual Network Gateway."
  nullable    = false

  validation {
    condition     = contains(["Basic", "HighPerformance", "Standard", "UltraPerformance", "VpnGw1", "VpnGw2", "VpnGw3", "VpnGw4", "VpnGw5", "VpnGw1AZ", "VpnGw2AZ", "VpnGw3AZ", "VpnGw4AZ", "VpnGw5AZ", "ErGw1AZ", "ErGw2AZ", "ErGw3AZ"], var.sku)
    error_message = "sku possible values are Basic, HighPerformance, Standard, UltraPerformance, VpnGw1, VpnGw2, VpnGw3, VpnGw4, VpnGw5, VpnGw1AZ, VpnGw2AZ, VpnGw3AZ, VpnGw4AZ, VpnGw5AZ, ErGw1AZ, ErGw2AZ, ErGw3AZ."
  }
}

variable "subnet_address_prefix" {
  type        = string
  default     = ""
  description = "The address prefix for the gateway subnet. Required if `subnet_creation_enabled = true`."
  nullable    = false
}

variable "subnet_creation_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to create a subnet for the Virtual Network Gateway."
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "Tags to apply to the Virtual Network Gateway."
}

variable "type" {
  type        = string
  default     = "ExpressRoute"
  description = "The type of the Virtual Network Gateway, ExpressRoute or Vpn."
  nullable    = false

  validation {
    condition     = contains(["ExpressRoute", "Vpn"], var.type)
    error_message = "type possible values are ExpressRoute or Vpn."
  }
}

variable "virtual_network_gateway_subnet_id" {
  type        = string
  default     = null
  description = "The resource id of the Virtual Network Gateway Subnet. If not specified, the module will create a new subnet for the Virtual Network Gateway."

  validation {
    condition     = var.virtual_network_gateway_subnet_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+/subnets/[^/]+$", var.virtual_network_gateway_subnet_id))
    error_message = "virtual_network_gateway_subnet_id must be a valid resource id."
  }
  validation {
    condition     = var.virtual_network_gateway_subnet_id == null && var.virtual_network_id == null ? false : true
    error_message = "one of virtual_network_gateway_subnet_id or virtual_network_id must be supplied."
  }
  validation {
    condition     = var.subnet_creation_enabled ? var.virtual_network_gateway_subnet_id == null : var.virtual_network_gateway_subnet_id != null
    error_message = "virtual_network_gateway_subnet_id must be supplied when subnet_creation_enabled is false and not when it is true."
  }
  validation {
    condition     = var.virtual_network_gateway_subnet_id == null ? true : startswith(var.virtual_network_gateway_subnet_id, var.parent_id)
    error_message = "virtual_network_gateway_subnet_id must be in the same resource group as the Virtual Network Gateway."
  }
}

variable "virtual_network_id" {
  type        = string
  default     = null
  description = "The resource id of the Virtual Network to which the Virtual Network Gateway will be attached."

  validation {
    condition     = var.virtual_network_id == null || can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/virtualNetworks/[^/]+$", var.virtual_network_id))
    error_message = "virtual_network_id must be a valid resource id."
  }
  validation {
    condition     = var.subnet_creation_enabled ? var.virtual_network_id != null : var.virtual_network_id == null
    error_message = "virtual_network_id must be supplied when subnet_creation_enabled is true and not when it is false."
  }
  validation {
    condition     = var.virtual_network_id == null ? true : startswith(var.virtual_network_id, var.parent_id)
    error_message = "virtual_network_id must be in the same resource group as the Virtual Network Gateway."
  }
}

variable "vpn_active_active_enabled" {
  type        = bool
  default     = true
  description = "Enable active-active mode for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_bgp_enabled" {
  type        = bool
  default     = false
  description = "Enable BGP for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_bgp_route_translation_for_nat_enabled" {
  type        = bool
  default     = false
  description = "Enable BGP route translation for NAT for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_bgp_settings" {
  type = object({
    asn         = optional(number, 65515)
    peer_weight = optional(number, null)
  })
  default     = null
  description = "BGP settings for the Virtual Network Gateway."
}

variable "vpn_custom_route" {
  type = object({
    address_prefixes = list(string)
  })
  default     = null
  description = "The reference to the address space resource which represents the custom routes address space specified by the customer for virtual network gateway and VpnClient."
}

variable "vpn_default_local_network_gateway_id" {
  type        = string
  default     = null
  description = "The ID of the default local network gateway to use for the Virtual Network Gateway."
}

variable "vpn_dns_forwarding_enabled" {
  type        = bool
  default     = null
  description = "Enable DNS forwarding for the Virtual Network Gateway."
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

variable "vpn_ip_sec_replay_protection_enabled" {
  type        = bool
  default     = true
  description = "Enable IPsec replay protection for the Virtual Network Gateway."
  nullable    = false
}

variable "vpn_point_to_site" {
  type = object({
    address_space         = list(string)
    aad_tenant            = optional(string, null)
    aad_audience          = optional(string, null)
    aad_issuer            = optional(string, null)
    radius_server_address = optional(string, null)
    radius_server_secret  = optional(string, null)
    root_certificates = optional(map(object({
      name             = string
      public_cert_data = string
    })), {})
    revoked_certificates = optional(map(object({
      name       = string
      thumbprint = string
    })), {})
    radius_servers = optional(map(object({
      address = string
      secret  = string
      score   = number
    })), {})
    vpn_client_protocols = optional(list(string), null)
    vpn_auth_types       = optional(list(string), null)
    ipsec_policy = optional(object({
      dh_group                  = string
      ike_encryption            = string
      ike_integrity             = string
      ipsec_encryption          = string
      ipsec_integrity           = string
      pfs_group                 = string
      sa_data_size_in_kilobytes = optional(number, null)
      sa_lifetime_in_seconds    = optional(number, null)
    }), null)
    virtual_network_gateway_client_connections = optional(map(object({
      name               = string
      policy_group_names = list(string)
      address_prefixes   = list(string)
    })), {})
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
- `radius_server` - (Optional) The radius server of the virtual network gateway.
  - `address` - (Required) The address of the radius server.
  - `secret` - (Required) The secret of the radius server.
  - `score` - (Required) The score of the radius server.
- `ipsec_policy` - (Optional) The IPsec policy of the virtual network gateway.
  - `dh_group` - (Required) The DH group of the IPsec policy.
  - `ike_encryption` - (Required) The IKE encryption of the IPsec policy.
  - `ike_integrity` - (Required) The IKE integrity of the IPsec policy.
  - `ipsec_encryption` - (Required) The IPsec encryption of the IPsec policy.
  - `ipsec_integrity` - (Required) The IPsec integrity of the IPsec policy.
  - `pfs_group` - (Required) The PFS group of the IPsec policy.
  - `sa_data_size_in_kilobytes` - (Optional) The SA data size in kilobytes of the IPsec policy.
  - `sa_lifetime_in_seconds` - (Optional) The SA lifetime in seconds of the IPsec policy.
- `virtual_network_gateway_client_connection` - (Optional) The virtual network gateway client connection of the virtual network gateway.
  - `name` - (Required) The name of the virtual network gateway client connection.
  - `policy_group_names` - (Required) The policy group names of the virtual network gateway client connection.
  - `address_prefixes` - (Required) The address prefixes of the virtual network gateway client connection.
- `vpn_client_protocols` - (Optional) The VPN client protocols.
- `vpn_auth_types` - (Optional) The VPN authentication types.
DESCRIPTION
}

variable "vpn_policy_groups" {
  type = map(object({
    name       = string
    is_default = optional(bool, null)
    priority   = optional(number, null)
    policy_members = map(object({
      name  = string
      type  = string
      value = string
    }))
  }))
  default     = {}
  description = "The policy groups for the Virtual Network Gateway."
  nullable    = false
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
