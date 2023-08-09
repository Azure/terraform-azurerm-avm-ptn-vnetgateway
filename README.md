<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-vnet-gateway
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/Azure/terraform-azurerm-vnet-gateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-vnet-gateway "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/Azure/terraform-azurerm-vnet-gateway.svg)](http://isitmaintained.com/project/Azure/terraform-azurerm-vnet-gateway "Percentage of issues still open")

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
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name
}
```

## Enable or Disable Tracing Tags

We're using [BridgeCrew Yor](https://github.com/bridgecrewio/yor) and [yorbox](https://github.com/lonegunmanb/yorbox) to help manage tags consistently across infrastructure as code (IaC) frameworks. This adds accountability for the code responsible for deploying the particular Azure resources. In this module you might see tags like:

```hcl
resource "azurerm_route_table" "vgw" {
  count = var.route_table_creation_enabled ? 1 : 0

  location                      = coalesce(var.location, data.azurerm_virtual_network.vgw.location)
  name                          = coalesce(var.route_table_name, "rt-${var.name}")
  resource_group_name           = data.azurerm_virtual_network.vgw.resource_group_name
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
```

To enable tracing tags, set the `tracing_tags_enabled` variable to true:

```hcl
module "vgw" {
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name

  tracing_tags_enabled = true
}
```

The `tracing_tags_enabled` is defaulted to `false`.

To customize the prefix for your tracing tags, set the `tracing_tags_prefix` variable value in your Terraform configuration:

```hcl
module "vgw" {
  source  = "Azure/vnet-gateway/azure"
  version = "<version>" # change this to your desired version, https://www.terraform.io/language/expressions/version-constraints

  location                            = "uksouth"
  name                                = "vgw-uksouth-prod"
  sku                                 = "VpnGw1"
  subnet_address_prefix               = "10.0.1.0/24"
  type                                = "Vpn"
  virtual_network_name                = azurerm_virtual_network.vnet.name
  virtual_network_resource_group_name = azurerm_virtual_network.vnet.resource_group_name

  tracing_tags_enabled = true
  tracing_tags_prefix  = "custom_prefix_"
}
```

The actual applied tags would be:

```text
{
  custom_prefix_git_commit           = "0978238465c76c23be1b5998c1451519b4d135c9"
  custom_prefix_git_file             = "main.tf"
  custom_prefix_git_last_modified_at = "2023-07-01 10:37:24"
  custom_prefix_git_org              = "Azure"
  custom_prefix_git_repo             = "terraform-azurerm-vnet-gateway"
  custom_prefix_yor_name             = "vgw"
  custom_prefix_yor_trace            = "89805148-c9e6-4736-96bc-0f4095dfb135"
}
```

## Documentation
<!-- markdownlint-disable MD033 -->

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.1, < 4.0)

## Modules

No modules.

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: The Azure region where the resources will be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the Virtual Network Gateway.

Type: `string`

### <a name="input_sku"></a> [sku](#input\_sku)

Description: The SKU (size) of the Virtual Network Gateway.

Type: `string`

### <a name="input_subnet_address_prefix"></a> [subnet\_address\_prefix](#input\_subnet\_address\_prefix)

Description: The address prefix for the gateway subnet.

Type: `string`

### <a name="input_type"></a> [type](#input\_type)

Description: The type of the Virtual Network Gateway, ExpressRoute or VPN.

Type: `string`

### <a name="input_virtual_network_name"></a> [virtual\_network\_name](#input\_virtual\_network\_name)

Description: The name of the Virtual Network.

Type: `string`

### <a name="input_virtual_network_resource_group_name"></a> [virtual\_network\_resource\_group\_name](#input\_virtual\_network\_resource\_group\_name)

Description: The name of the Virtual Network's Resource Group.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags)

Description: Tags to apply to all resources.

Type: `map(string)`

Default: `{}`

### <a name="input_edge_zone"></a> [edge\_zone](#input\_edge\_zone)

Description: The availability zone of the Virtual Network Gateway. Only supported for AZ SKUs.

Type: `string`

Default: `null`

### <a name="input_express_route_circuits"></a> [express\_route\_circuits](#input\_express\_route\_circuits)

Description: Map of Virtual Network Gateway Connections and Peering Configurations to create for existing ExpressRoute circuits.

- `express_route_circuit_id` - (Required) The ID of the ExpressRoute circuit.

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

Type:

```hcl
map(object({
    express_route_circuit_id = string
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
      primary_peer_address_prefix   = optional(number, null)
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

### <a name="input_ip_configurations"></a> [ip\_configurations](#input\_ip\_configurations)

Description: Map of IP Configurations to create for the Virtual Network Gateway.

- `ip_configuration_name` - (Optional) The name of the IP Configuration.
- `apipa_addresses` - (Optional) The list of APPIPA addresses.
- `private_ip_address_allocation` - (Optional) The private IP allocation method. Possible values are Static or Dynamic. Defaults to Dynamic.
- `public_ip` - (Optional) a `public_ip` block as defined below. Used to configure the Public IP Address for the IP Configuration.
  - `name` - (Optional) The name of the Public IP Address.
  - `allocation_method` - (Optional) The allocation method of the Public IP Address. Possible values are Static or Dynamic. Defaults to Dynamic.
  - `sku` - (Optional) The SKU of the Public IP Address. Possible values are Basic or Standard. Defaults to Basic.
  - `tags` - (Optional) A mapping of tags to assign to the resource.

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_local_network_gateways"></a> [local\_network\_gateways](#input\_local\_network\_gateways)

Description: Map of Local Network Gateways and Virtual Network Gateway Connections to create for the Virtual Network Gateway.

- `name` - (Optional) The name of the Local Network Gateway.
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

Type:

```hcl
map(object({
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

### <a name="input_route_table_tags"></a> [route\_table\_tags](#input\_route\_table\_tags)

Description: Tags for the Route Table.

Type: `map(string)`

Default: `{}`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: Tags to apply to the Virtual Network Gateway.

Type: `map(string)`

Default: `{}`

### <a name="input_tracing_tags_enabled"></a> [tracing\_tags\_enabled](#input\_tracing\_tags\_enabled)

Description: Whether enable tracing tags that generated by BridgeCrew Yor.

Type: `bool`

Default: `false`

### <a name="input_tracing_tags_prefix"></a> [tracing\_tags\_prefix](#input\_tracing\_tags\_prefix)

Description: Default prefix for generated tracing tags

Type: `string`

Default: `"avm_"`

### <a name="input_vpn_active_active_enabled"></a> [vpn\_active\_active\_enabled](#input\_vpn\_active\_active\_enabled)

Description: Enable active-active mode for the Virtual Network Gateway.

Type: `bool`

Default: `false`

### <a name="input_vpn_bgp_enabled"></a> [vpn\_bgp\_enabled](#input\_vpn\_bgp\_enabled)

Description: Enable BGP for the Virtual Network Gateway.

Type: `bool`

Default: `false`

### <a name="input_vpn_bgp_settings"></a> [vpn\_bgp\_settings](#input\_vpn\_bgp\_settings)

Description: BGP settings for the Virtual Network Gateway.

Type:

```hcl
object({
    asn         = optional(number, null)
    peer_weight = optional(number, null)
  })
```

Default: `null`

### <a name="input_vpn_generation"></a> [vpn\_generation](#input\_vpn\_generation)

Description: value for the Generation for the Gateway, Valid values are 'Generation1', 'Generation2'. Options differ depending on SKU.

Type: `string`

Default: `null`

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
```

Default: `null`

### <a name="input_vpn_private_ip_address_enabled"></a> [vpn\_private\_ip\_address\_enabled](#input\_vpn\_private\_ip\_address\_enabled)

Description: Enable private IP address for the Virtual Network Gateway for Virtual Network Gateway Connections. Only supported for AZ SKUs.

Type: `bool`

Default: `null`

### <a name="input_vpn_type"></a> [vpn\_type](#input\_vpn\_type)

Description: The VPN type of the Virtual Network Gateway.

Type: `string`

Default: `"RouteBased"`

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

## Outputs

The following outputs are exported:

### <a name="output_local_network_gateways"></a> [local\_network\_gateways](#output\_local\_network\_gateways)

Description: A curated output of the Local Network Gateways created by this module.

### <a name="output_public_ip_addresses"></a> [public\_ip\_addresses](#output\_public\_ip\_addresses)

Description: A curated output of the Public IP Addresses created by this module.

### <a name="output_route_table"></a> [route\_table](#output\_route\_table)

Description: A curated output of the Route Table created by this module.

### <a name="output_subnet"></a> [subnet](#output\_subnet)

Description: A curated output of the GatewaySubnet created by this module.

### <a name="output_virtual_network_gateway"></a> [virtual\_network\_gateway](#output\_virtual\_network\_gateway)

Description: A curated output of the Virtual Network Gateway created by this module.

### <a name="output_virtual_network_gateway_connections"></a> [virtual\_network\_gateway\_connections](#output\_virtual\_network\_gateway\_connections)

Description: A curated output of the Virtual Network Gateway Connections created by this module.

<!-- markdownlint-enable -->
## Contributing
1. Fork the repository.
2. Write Terraform code in a new branch.
3. Run `docker run --rm -v ${pwd}:/src -w /src mcr.microsoft.com/azterraform:latest make pre-commit` to format the code.
4. Run `docker run --rm -v $(pwd):/src -w /src mcr.microsoft.com/azterraform:latest make pr-check` to run the check locally.
5. Create a pull request for the main branch.
    * CI pr-check will be executed automatically.
    * Once pr-check was passed, with manually approval, the e2e test and version upgrade test would be executed.
6. Merge pull request after approval.

## Trademarks

This project may contain trademarks or logos for projects, products, or services.
Authorized use of Microsoft trademarks or logos is subject to and must follow Microsoft's Trademark & Brand Guidelines.
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
<!-- END_TF_DOCS -->