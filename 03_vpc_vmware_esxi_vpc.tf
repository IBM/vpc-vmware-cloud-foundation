##############################################################
# Define VPC structure 
##############################################################

# Select the VPC strcture based on architecture. 

locals {
  vcf_vpc_structure = var.vcf_architecture == "standard" ? var.vpc_vcf_standard : var.vpc_vcf_consolidated
  vpc_structure = var.enable_vcf_mode ? local.vcf_vpc_structure : var.vpc_ryo
}


##############################################################
# Define maps for VPC prefixes and use VLAN IDs 
##############################################################


locals {
  vpc_prefix_map = {
    infrastructure = var.vpc_zone_prefix
    edges = var.vpc_zone_prefix_t0_uplinks
  }
}

locals {
  vlan_id_map = {
    infrastructure = {
      host = var.host_vlan_id
      mgmt = var.mgmt_vlan_id
      vmot = var.vmot_vlan_id
      vsan = var.vsan_vlan_id
      tep = var.tep_vlan_id
      wl-mgmt = var.wl_mgmt_vlan_id
      wl-vmot = var.wl_vmot_vlan_id
      wl-vsan = var.wl_vsan_vlan_id
      wl-tep = var.wl_tep_vlan_id
    },
    edges = {
      t0-priv = var.edge_uplink_private_vlan_id
      t0-pub = var.edge_uplink_public_vlan_id
      edge-tep = var.edge_tep_vlan_id
      wl-t0-priv = var.wl_edge_uplink_private_vlan_id
      wl-t0-pub = var.wl_edge_uplink_public_vlan_id
      wl-edge-tep = var.wl_edge_tep_vlan_id
    },
  }    
}



##############################################################
# Create VPC and Subnets
##############################################################

locals {
  vpc_subnets_test = {for k, v in local.vpc_structure : var.vpc_name => {
      zones = {
        "${var.vpc_zone}" = {      
          for domain_k, domain_v in v.zones.vpc_zone : domain_k => {
            vpc_zone_prefix = local.vpc_prefix_map[domain_k]
            vpc_zone_subnet_size = v.zones.vpc_zone[domain_k].vpc_zone_subnet_size
            public_gateways = lookup(v.zones.vpc_zone[domain_k], "public_gateways", [])
            subnets = v.zones.vpc_zone[domain_k].subnets
          } 
        }
      }
    }
  }
}



##### old

/*
locals {
  vpc_subnets = {for k, v in var.enable_vcf_mode ? var.vpc_vcf : var.vpc : var.vpc_name => {
      zones = {
        "${var.vpc_zone}" = {
          infrastructure = {
            vpc_zone_prefix = var.vpc_zone_prefix
            vpc_zone_subnet_size = v.zones.vpc_zone.infrastructure.vpc_zone_subnet_size
            public_gateways = lookup(v.zones.vpc_zone.infrastructure, "public_gateways", [])
            subnets = v.zones.vpc_zone.infrastructure.subnets
          }
          edges = {
            vpc_zone_prefix = var.vpc_zone_prefix_t0_uplinks
            vpc_zone_subnet_size = v.zones.vpc_zone.edges.vpc_zone_subnet_size
            public_gateways = lookup(v.zones.vpc_zone.edges, "public_gateways", [])
            subnets = v.zones.vpc_zone.edges.subnets
          }          
        }
      }
    }
  }
}
*/

resource "ibm_is_vpc" "vmware_vpc" {
  name = "${local.resources_prefix}-${var.vpc_name}"
  resource_group = data.ibm_resource_group.resource_group_vmw.id
  address_prefix_management = "manual"
}

module "vpc_subnets" {
  source = "./modules/vpc-subnets"
  #for_each = local.vpc_subnets
  for_each = local.vpc_subnets_test

  vpc_id = ibm_is_vpc.vmware_vpc.id
  vpc_name = each.key
  vpc_zones = each.value.zones
  resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  resources_prefix = local.resources_prefix

  tags = local.resource_tags.subnets

  depends_on = [
    ibm_is_vpc.vmware_vpc,
    ibm_resource_group.resource_group_vmw
  ]

}

##############################################################
# Create Security Groups
##############################################################

locals {
  security_groups = {
    for k, v in var.security_group_rules : k => {
      name = k
    }
  }
}

resource "ibm_is_security_group" "sg" {

  for_each       = local.security_groups
  name           = "${local.resources_prefix}-${each.key}-sg"
  vpc            = ibm_is_vpc.vmware_vpc.id
  resource_group = data.ibm_resource_group.resource_group_vmw.id

    depends_on =  [
      module.vpc_subnets
    ]

  tags = local.resource_tags.security_group
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
  subnets_map = {
    for k,v in local.vpc_structure.vpc.zones.vpc_zone : k => {
      for subnet_k, subnet_v in v.subnets : subnet_k => {
        name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].name
        subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].id
        cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].ipv4_cidr_block
        prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].ipv4_cidr_block)[1]
        default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].ipv4_cidr_block,1)
        pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-${subnet_k}"].public_gateway == null ? false : true
        vlan_id = local.vlan_id_map[k][subnet_k]
      }
    }
  }
}


/*



locals {
  subnets = {
    hosts = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-host"].public_gateway == null ? false : true
      vlan_id =  var.host_vlan_id
    },
    mgmt = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-mgmt"].public_gateway == null ? false : true
      vlan_id = var.mgmt_vlan_id
    },
    vmot = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vmot"].public_gateway == null ? false : true
      vlan_id =  var.vmot_vlan_id
    },
    vsan = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-vsan"].public_gateway == null ? false : true
      vlan_id =  var.vsan_vlan_id
    },
    tep = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-tep"].public_gateway == null ? false : true
      vlan_id =  var.tep_vlan_id
    }
  }
}

locals {
  nsxt_edge_subnets = {
    private = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-priv"].public_gateway == null ? false : true
      vlan_id =  var.edge_uplink_private_vlan_id
    },
    public = {
      name = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].name
      subnet_id = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].id
      cidr = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block
      prefix_length = split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block)[1]
      default_gateway = cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].ipv4_cidr_block,1)
      pgw = module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-t0-pub"].public_gateway == null ? false : true
      vlan_id =  var.edge_uplink_public_vlan_id
    },
    edge_tep = {
      name = var.enable_vcf_mode ? module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].name : "none"
      subnet_id = var.enable_vcf_mode ? module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].id : "none"
      cidr = var.enable_vcf_mode ? module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block : "none"
      prefix_length = var.enable_vcf_mode ? split("/", module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block)[1] : "none"
      default_gateway = var.enable_vcf_mode ? cidrhost(module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].ipv4_cidr_block,1) : "none"
      pgw = var.enable_vcf_mode ? module.vpc_subnets[var.vpc_name].vpc_subnet_zone_subnet["${var.vpc_name}-${var.vpc_zone}-edge-tep"].public_gateway : null == null ? false : true 
      vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : "none" 
    }
  }
}

*/

