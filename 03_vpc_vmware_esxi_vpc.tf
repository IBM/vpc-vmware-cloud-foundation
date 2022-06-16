##############################################################
# Create VPC and Subnets
##############################################################

locals {
  vpc = {for k, v in var.vpc: var.vpc_name => {
      zones = {
        "${var.vpc_zone}" = {
          infrastructure = {
            vpc_zone_prefix = var.vpc_zone_prefix
            vpc_zone_subnet_size = v.zones.vpc_zone.infrastructure.vpc_zone_subnet_size
            public_gateways = lookup(v.zones.vpc_zone.infrastructure, "public_gateways", [])
            subnets = v.zones.vpc_zone.infrastructure.subnets
          }
          t0-uplink = {
            vpc_zone_prefix = var.vpc_zone_prefix_t0_uplinks
            vpc_zone_subnet_size = v.zones.vpc_zone.t0-uplink.vpc_zone_subnet_size
            public_gateways = lookup(v.zones.vpc_zone.t0-uplink, "public_gateways", [])
            subnets = v.zones.vpc_zone.t0-uplink.subnets
          }          
        }
      }
    }
  }
}

module "vpc-subnets" {

  source = "./modules/vpc-subnets"
  for_each = local.vpc

  vpc_name = each.key
  vpc_zones = each.value.zones
  resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  resources_prefix = local.resources_prefix

  depends_on = [
    ibm_resource_group.resource_group_vmw
  ]

}

##############################################################
# Create Security Groups
##############################################################

resource "ibm_is_security_group" "sg" {

  for_each = var.security_group_rules
  name           = "${local.resources_prefix}-${each.key}-sg"
  vpc            = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  resource_group = data.ibm_resource_group.resource_group_vmw.id

    depends_on =  [
      module.vpc-subnets
    ]
}

##############################################################
# Create Security Group Rules
##############################################################

locals {
  security_group_rules = {
    for k, v in var.security_group_rules : k => {
      security_group_id = ibm_is_security_group.sg[k].id
      rules = [
        for r in v : {
          name       = r.name
          direction  = r.direction
          remote     = lookup(r, "remote", null)
          remote_id  = lookup(r, "remote_id", null) == null ? null : ibm_is_security_group.sg[r["remote_id"]].id
          ip_version = lookup(r, "ip_version", null)
          icmp       = lookup(r, "icmp", null)
          tcp        = lookup(r, "tcp", null)
          udp        = lookup(r, "udp", null)
        }
      ]
    }
  }
}

module "security_group_rules" {

  source = "./modules/vpc-security-group-rules"
  for_each = local.security_group_rules

  resource_group_id     = data.ibm_resource_group.resource_group_vmw.id
  security_group        = each.value.security_group_id
  security_group_rules  = each.value.rules

}

##############################################################
# Calculate subnet details and define output
##############################################################


# This calculates the prefix length and gateway IP for each subnet.

locals {
  subnets = {
    hosts = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host-mgmt"].public_gateway == null ? false : true
      vlan_id =  "0"
    },
    inst_mgmt = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].public_gateway == null ? false : true
      vlan_id =  "100"
    },
    vmot = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].public_gateway == null ? false : true
      vlan_id =  "200"
    },
    vsan = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].public_gateway == null ? false : true
      vlan_id =  "300"
    },
    tep = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].public_gateway == null ? false : true
      vlan_id =  "400"
    }
  }
}

locals {
  nsxt_uplink_subnets = {
    private = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].public_gateway == null ? false : true
      vlan_id =  "710"
    }
    public = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].public_gateway == null ? false : true
      vlan_id =  "700"
    }
  }
}
