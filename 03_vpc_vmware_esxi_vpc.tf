##############################################################
# Create VPC and Subnets
##############################################################

locals {
  vpc = {for k, v in var.enable_vcf_mode ? var.vpc_vcf : var.vpc : var.vpc_name => {
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
      vlan_id =  var.host_vlan_id
    },
    inst_mgmt = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-inst-mgmt"].public_gateway == null ? false : true
      vlan_id = var.mgmt_vlan_id
    },
    vmot = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].public_gateway == null ? false : true
      vlan_id =  var.vmot_vlan_id
    },
    vsan = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].public_gateway == null ? false : true
      vlan_id =  var.vsan_vlan_id
    },
    tep = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].public_gateway == null ? false : true
      vlan_id =  var.tep_vlan_id
    }
  }
}

locals {
  nsxt_edge_subnets = {
    private = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].public_gateway == null ? false : true
      vlan_id =  var.edge_uplink_private_vlan_id
    },
    public = {
      name = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].name
      subnet_id = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].id
      cidr = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block
      prefix_length = split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block,1)
      pgw = module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].public_gateway == null ? false : true
      vlan_id =  var.edge_uplink_public_vlan_id
    },
    edge_tep = {
      name = var.enable_vcf_mode ? module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].name : "none"
      subnet_id = var.enable_vcf_mode ? module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].id : "none"
      cidr = var.enable_vcf_mode ? module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block : "none"
      prefix_length = var.enable_vcf_mode ? split("/", module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block)[1] : "none"
      default_gateway = var.enable_vcf_mode ? cidrhost(module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block,1) : "none"
      pgw = var.enable_vcf_mode ? module.vpc-subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].public_gateway : null == null ? false : true 
      vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : "none" 
    }
  }
}

