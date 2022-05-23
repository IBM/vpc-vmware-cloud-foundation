##############################################################
# Create VPC 
##############################################################

resource "ibm_is_vpc" "vmware_vpc" {
  name = "${var.resources_prefix}-${var.vpc_name}"
  resource_group = var.resource_group_id
  address_prefix_management = "manual"
}

##############################################################
# locals
##############################################################

locals {
vpc_zone_prefixes = {for vpc_zone_prefix_list in flatten([
      for zone, zone_prefix in var.vpc_zones: [
        for prefix_name, prefix_data in zone_prefix: {
           "zone" = zone
           zone_prefix = prefix_name
           vpc_zone_prefix = prefix_data.vpc_zone_prefix
           vpc_zone_subnet_size = prefix_data.vpc_zone_subnet_size
           public_gateways = lookup(prefix_data, "public_gateways", [])
           subnets = prefix_data.subnets
        }
      ]
    ]): join("-", [vpc_zone_prefix_list.zone, vpc_zone_prefix_list.zone_prefix]) => vpc_zone_prefix_list}
}

##############################################################
# Create Prefix on the VPC in a specific Zone
#
# The cidr_block is clean definition but static to a specific Zone.
##############################################################

resource "ibm_is_vpc_address_prefix" "vmware_vpc_address_prefix_zone" {

  for_each = local.vpc_zone_prefixes

  name = "${var.resources_prefix}-${each.key}"
  zone = each.value.zone
  vpc  = ibm_is_vpc.vmware_vpc.id
  cidr = each.value.vpc_zone_prefix
  depends_on = [
    ibm_is_vpc.vmware_vpc
  ]
}

##############################################################
# Create Public Gateway/s
##############################################################

resource "ibm_is_public_gateway" "vpc_zone_subnet_public_gateway" {

    for_each = { for vpc_public_gateways in flatten ([
                     for k, v in local.vpc_zone_prefixes : [
                       for public_gateway in v.public_gateways : {
                           vpc_zone_prefixes = k,
                           "public_gateway" = public_gateway
                           zone = v.zone
                       }
                     ]
                ]) : join("-", [vpc_public_gateways.zone, vpc_public_gateways.public_gateway]) => vpc_public_gateways
    }

    name = "${var.resources_prefix}-${var.vpc_name}-${each.value.public_gateway}"
    resource_group  = var.resource_group_id
    vpc             = ibm_is_vpc.vmware_vpc.id
    zone            = each.value.zone

    //User can configure timeouts
    timeouts {
      create = "90m"
      delete = "60m"
    }
}

##############################################################
# Create Subnets
##############################################################

resource "ibm_is_subnet" "vpc_subnet_zone_subnet" {

  for_each = { for subnet_map in flatten([
        for k, v in local.vpc_zone_prefixes : [
            for subnet_name, subnet in v.subnets : {
                name: subnet_name
                zone: v.zone
                cidr_offset: subnet["cidr_offset"]
                ip_version: subnet["ip_version"]
                public_gateway: lookup(subnet, "public_gateway", "")
                ipv4_cidr_block = cidrsubnet(v.vpc_zone_prefix, v.vpc_zone_subnet_size, subnet.cidr_offset)
            }
        ]
      ]): join("-", [var.vpc_name, subnet_map.zone, subnet_map.name]) => subnet_map
    }

  name            = join("-", [var.resources_prefix, var.vpc_name, each.value.zone, each.value.name])
  resource_group  = var.resource_group_id
  vpc             = ibm_is_vpc.vmware_vpc.id
  zone            = each.value.zone
  ipv4_cidr_block = each.value.ipv4_cidr_block
  public_gateway = each.value.public_gateway == "" ? null : ibm_is_public_gateway.vpc_zone_subnet_public_gateway["${each.value.zone}-${each.value.public_gateway}"].id
  
  depends_on = [
    ibm_is_vpc.vmware_vpc,
    ibm_is_vpc_address_prefix.vmware_vpc_address_prefix_zone
  ]

  timeouts {
    create = "10m"
    delete = "60m"
  }
}
