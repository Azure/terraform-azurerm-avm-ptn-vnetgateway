<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-ptn-vnetgateway

[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-avm-ptn-vnetgateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-vnetgateway "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-avm-ptn-vnetgateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-avm-ptn-vnetgateway "Percentage of issues still open")

This module is designed to deploy an Azure Virtual Network Gateway and several auxillary resources associated to it.

## Features

- Virtual Network Gateway:
  - VPN Gateway or ExpressRoute Gateway.
  - Active-Active or Single.
  - Deployment of `GatewaySubnet`.
- Route Table
  - Optional deployment of Route Table on the Gateway Subnet.
- Local Network Gateway:
  - Optional deployment of `n` Local Network Gateways.
  - Optional deployment of `n` Virtual Network Gateway Connections for Local Network Gateways.
- ExpressRoute Circuit:
  - Configure peering on `n` pre-provisioned ExpressRoute Circuits.
  - Optional deployment of `n` Virtual Network Gateway Connections for ExpressRoute Circuits.

## Example

```hcl
resource "azurerm_resource_group" "rg" {
  location = "uksouth"
  name     = "rg-connectivity-uksouth-prod"
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  name                = "vnet-uksouth-prod"
  resource_group_name = azurerm_resource_group.rg.name
}

module "vgw" {
  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location              = "uksouth"
  name                  = "vgw-uksouth-prod"
  subnet_address_prefix = "10.0.1.0/24"
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3.2)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_express_route_circuit_peering.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/express_route_circuit_peering) (resource)
- [azurerm_local_network_gateway.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/local_network_gateway) (resource)
- [azurerm_public_ip.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) (resource)
- [azurerm_route_table.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) (resource)
- [azurerm_subnet.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) (resource)
- [azurerm_subnet_route_table_association.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) (resource)
- [azurerm_virtual_network_gateway.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway) (resource)
- [azurerm_virtual_network_gateway_connection.vgw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_gateway_connection) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where the resources will be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the Virtual Network Gateway.

Type: `string`

### <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id)

Description: The resource id of the Virtual Network to which the Virtual Network Gateway will be attached.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone)

Description: Specifies the Edge Zone within the Azure Region where this Virtual Network Gateway should exist. Changing this forces a new Virtual Network Gateway to be created.

Type: `string`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see https://aka.ms/avm/telemetryinfo.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_express_route_circuits"></a> [express\_route\_circuits](#input\_express\_route\_circuits)

Description: Map of Virtual Network Gateway Connections and Peering Configurations to create for existing ExpressRoute circuits.

- `id` - (Required) The ID of the ExpressRoute circuit.

- `connection` - (Optional) a `connection` block as defined below. Used to configure the Virtual Network Gateway Connection between the ExpressRoute Circuit and the Virtual Network Gateway.
  - `resource_group_name` - (Optional) The name of the resource group in which to create the Virtual Network Gateway Connection. Defaults to the resource group of the Virtual Network.
  - `authorization_key` - (Optional) The authorization key for the ExpressRoute Circuit.
  - `express_route_gateway_bypass` - (Optional) Whether to bypass the ExpressRoute Gateway for data forwarding.
  - `private_link_fast_path_enabled` - (Optional) Bypass the Express Route gateway when accessing private-links. When enabled express\_route\_gateway\_bypass must be set to true. Defaults to false.
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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_express_route_remote_vnet_traffic_enabled"></a> [express\_route\_remote\_vnet\_traffic\_enabled](#input\_express\_route\_remote\_vnet\_traffic\_enabled)

Description: Enabled ExpressRoute traffic incoming from other connected VNets

Type: `bool`

Default: `false`

### <a name="input_express_route_virtual_wan_traffic_enabled"></a> [express\_route\_virtual\_wan\_traffic\_enabled](#input\_express\_route\_virtual\_wan\_traffic\_enabled)

Description: Enabled ExpressRoute traffic incoming from other connected VWANs

Type: `bool`

Default: `false`

### <a name="input_ip_configurations"></a> [ip\_configurations](#input\_ip\_configurations)

Description: Map of IP Configurations to create for the Virtual Network Gateway.

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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_local_network_gateways"></a> [local\_network\_gateways](#input\_local\_network\_gateways)

Description: Map of Local Network Gateways and Virtual Network Gateway Connections to create for the Virtual Network Gateway.

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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_route_table_bgp_route_propagation_enabled"></a> [route\_table\_bgp\_route\_propagation\_enabled](#input\_route\_table\_bgp\_route\_propagation\_enabled)

Description: Whether or not to enable BGP route propagation on the Route Table.

Type: `bool`

Default: `true`

### <a name="input_route_table_creation_enabled"></a> [route\_table\_creation\_enabled](#input\_route\_table\_creation\_enabled)

Description: Whether or not to create a Route Table associated with the Virtual Network Gateway Subnet.

Type: `bool`

Default: `false`

### <a name="input_route_table_name"></a> [route\_table\_name](#input\_route\_table\_name)

Description: Name of the Route Table associated with Virtual Network Gateway Subnet.

Type: `string`

Default: `null`

### <a name="input_route_table_resource_group_name"></a> [route\_table\_resource\_group\_name](#input\_route\_table\_resource\_group\_name)

Description: The name of the resource group in which to create the Route Table. If left blank, the resource group of the virtual network will be used.

Type: `string`

Default: `null`

### <a name="input_route_table_tags"></a> [route\_table\_tags](#input\_route\_table\_tags)

Description: Tags for the Route Table.

Type: `map(string)`

Default: `{}`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The SKU (size) of the Virtual Network Gateway.

Type: `string`

Default: `"ErGw1AZ"`

### <a name="input_subnet_address_prefix"></a> [subnet\_address\_prefix](#input\_subnet\_address\_prefix)

Description: The address prefix for the gateway subnet. Required if `subnet_creation_enabled = true`.

Type: `string`

Default: `""`

### <a name="input_subnet_creation_enabled"></a> [subnet\_creation\_enabled](#input\_subnet\_creation\_enabled)

Description: Whether or not to create a subnet for the Virtual Network Gateway.

Type: `bool`

Default: `true`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to apply to the Virtual Network Gateway.

Type: `map(string)`

Default: `null`

### <a name="input_type"></a> [type](#input\_type)

Description: The type of the Virtual Network Gateway, ExpressRoute or Vpn.

Type: `string`

Default: `"ExpressRoute"`

### <a name="input_vpn_active_active_enabled"></a> [vpn\_active\_active\_enabled](#input\_vpn\_active\_active\_enabled)

Description: Enable active-active mode for the Virtual Network Gateway.

Type: `bool`

Default: `true`

### <a name="input_vpn_bgp_enabled"></a> [vpn\_bgp\_enabled](#input\_vpn\_bgp\_enabled)

Description: Enable BGP for the Virtual Network Gateway.

Type: `bool`

Default: `false`

### <a name="input_vpn_bgp_route_translation_for_nat_enabled"></a> [vpn\_bgp\_route\_translation\_for\_nat\_enabled](#input\_vpn\_bgp\_route\_translation\_for\_nat\_enabled)

Description: Enable BGP route translation for NAT for the Virtual Network Gateway.

Type: `bool`

Default: `false`

### <a name="input_vpn_bgp_settings"></a> [vpn\_bgp\_settings](#input\_vpn\_bgp\_settings)

Description: BGP settings for the Virtual Network Gateway.

Type:

```hcl
object({
    asn         = optional(number, 65515)
    peer_weight = optional(number, null)
  })
```

Default: `null`

### <a name="input_vpn_custom_route"></a> [vpn\_custom\_route](#input\_vpn\_custom\_route)

Description: The reference to the address space resource which represents the custom routes address space specified by the customer for virtual network gateway and VpnClient.

Type:

```hcl
object({
    address_prefixes = list(string)
  })
```

Default: `null`

### <a name="input_vpn_default_local_network_gateway_id"></a> [vpn\_default\_local\_network\_gateway\_id](#input\_vpn\_default\_local\_network\_gateway\_id)

Description: The ID of the default local network gateway to use for the Virtual Network Gateway.

Type: `string`

Default: `null`

### <a name="input_vpn_dns_forwarding_enabled"></a> [vpn\_dns\_forwarding\_enabled](#input\_vpn\_dns\_forwarding\_enabled)

Description: Enable DNS forwarding for the Virtual Network Gateway.

Type: `bool`

Default: `null`

### <a name="input_vpn_generation"></a> [vpn\_generation](#input\_vpn\_generation)

Description: value for the Generation for the Gateway, Valid values are 'Generation1', 'Generation2'. Options differ depending on SKU.

Type: `string`

Default: `null`

### <a name="input_vpn_ip_sec_replay_protection_enabled"></a> [vpn\_ip\_sec\_replay\_protection\_enabled](#input\_vpn\_ip\_sec\_replay\_protection\_enabled)

Description: Enable IPsec replay protection for the Virtual Network Gateway.

Type: `bool`

Default: `true`

### <a name="input_vpn_point_to_site"></a> [vpn\_point\_to\_site](#input\_vpn\_point\_to\_site)

Description: Point to site configuration for the virtual network gateway.

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

Type:

```hcl
object({
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
```

Default: `null`

### <a name="input_vpn_policy_groups"></a> [vpn\_policy\_groups](#input\_vpn\_policy\_groups)

Description: The policy groups for the Virtual Network Gateway.

Type:

```hcl
map(object({
    name       = string
    is_default = optional(bool, null)
    priority   = optional(number, null)
    policy_members = map(object({
      name  = string
      type  = string
      value = string
    }))
  }))
```

Default: `{}`

### <a name="input_vpn_private_ip_address_enabled"></a> [vpn\_private\_ip\_address\_enabled](#input\_vpn\_private\_ip\_address\_enabled)

Description: Enable private IP address for the Virtual Network Gateway for Virtual Network Gateway Connections. Only supported for AZ SKUs.

Type: `bool`

Default: `null`

### <a name="input_vpn_type"></a> [vpn\_type](#input\_vpn\_type)

Description: The VPN type of the Virtual Network Gateway.

Type: `string`

Default: `"RouteBased"`

## Outputs

The following outputs are exported:

### <a name="output_local_network_gateways"></a> [local\_network\_gateways](#output\_local\_network\_gateways)

Description: A curated output of the Local Network Gateways created by this module.

### <a name="output_public_ip_addresses"></a> [public\_ip\_addresses](#output\_public\_ip\_addresses)

Description: A curated output of the Public IP Addresses created by this module.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the Virtual Network Gateway.

### <a name="output_route_table"></a> [route\_table](#output\_route\_table)

Description: A curated output of the Route Table created by this module.

### <a name="output_subnet"></a> [subnet](#output\_subnet)

Description: A curated output of the GatewaySubnet created by this module.

### <a name="output_virtual_network_gateway"></a> [virtual\_network\_gateway](#output\_virtual\_network\_gateway)

Description: A curated output of the Virtual Network Gateway created by this module.

### <a name="output_virtual_network_gateway_connections"></a> [virtual\_network\_gateway\_connections](#output\_virtual\_network\_gateway\_connections)

Description: A curated output of the Virtual Network Gateway Connections created by this module.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->