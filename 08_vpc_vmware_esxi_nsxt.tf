
##############################################################
# Create VLAN interface resources for NSX-T Managers
##############################################################


module "zone_nxt_t" {
  source                          = "./modules/vpc-nsx-t"
  vmw_vpc                         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_inst_mgmt_subnet_id         = local.subnets.inst_mgmt.subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id                = var.mgmt_vlan_id
  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_security_group.sg,
    ]
}

##############################################################
# Create VLAN interface resources for NSX-T Edges
##############################################################

module "zone_nxt_t_edge" {
  source                          = "./modules/vpc-nsx-t-edge"
  vmw_enable_vcf_mode             = var.enable_vcf_mode
  vmw_vpc                         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_priv_subnet_id              = local.nsxt_edge_subnets.private.subnet_id
  vmw_pub_subnet_id               = local.nsxt_edge_subnets.public.subnet_id
  vmw_inst_mgmt_subnet_id         = local.subnets.inst_mgmt.subnet_id
  vmw_tep_subnet_id               = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.subnet_id : local.subnets.tep.subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_sg_tep                      = ibm_is_security_group.sg["tep"].id
  vmw_sg_uplink_pub               = ibm_is_security_group.sg["uplink-pub"].id
  vmw_sg_uplink_priv              = ibm_is_security_group.sg["uplink-priv"].id
  vmw_mgmt_vlan_id                = var.mgmt_vlan_id
  vmw_tep_vlan_id                 = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
  vmw_edge_uplink_public_vlan_id  = var.edge_uplink_public_vlan_id
  vmw_edge_uplink_private_vlan_id = var.edge_uplink_private_vlan_id
  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_security_group.sg,
    ]
}

##############################################################
# Create Floating Public IPs to public VIP
##############################################################



resource "ibm_is_floating_ip" "floating_ip" {
  count             = var.vpc_t0_public_ips
  name              = "${local.resources_prefix}-vlan-nic-t0-uplink-public-floating-ip-${count.index}"
  zone              = var.vpc_zone

  tags = local.resource_tags.floating_ip_t0

  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_security_group.sg,
      module.zone_nxt_t_edge
    ]
}

resource "ibm_is_bare_metal_server_network_interface_floating_ip" "t0_public_vip_floating_ip" {
  count             = var.vpc_t0_public_ips
  bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  network_interface = module.zone_nxt_t_edge.t0_uplink_public_vip.id
  floating_ip       = ibm_is_floating_ip.floating_ip[count.index].id
  depends_on = [
    module.vpc-subnets,
    module.zone_bare_metal_esxi["cluster_0"],
    ibm_is_security_group.sg,
    module.zone_nxt_t_edge,
    ibm_is_floating_ip.floating_ip
  ]
}



##############################################################
# Create NSX-T random passwords
##############################################################

# Note use random_password instead...this is for testing only.

# Password for the root user of the appliance operating system
# Must contain only lower ASCII characters without spaces.
# Must be at least 8 characters, but no more than 20 characters in length
# Must contain at least one uppercase letter
# Must contain at least one lowercase letter
# Must contain at least one number
# Must contain at least one special character, 
# for example @!#$%?^


resource "random_string" "nsxt_password" {
  length           = 16
  special          = true
  numeric          = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "@!#$%?"
}



##############################################################
# Define output maps and output
##############################################################



locals {
  nsx_t_mgr = {
    nsx_t_0 = {
      fqdn = "nsx-t-0.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[0].primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip[0].id
      username = "admin"
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      vlan_id = var.mgmt_vlan_id
    }
    nsx_t_1 = {
      fqdn = "nsx-t-1.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[1].primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip[1].id
      username = "admin"
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      vlan_id = var.mgmt_vlan_id
    }
    nsx_t_2 = {
      fqdn = "nsx-t-2.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[2].primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip[2].id
      username = "admin"
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      vlan_id = var.mgmt_vlan_id
    }
    nsx_t_vip = {
      fqdn = "nsx-t-vip.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.id
      username = "admin"
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      vlan_id = var.mgmt_vlan_id
    }
  }
}

locals {
  nsx_t_edge = {
    edge_0 = {
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      username = "admin"
      mgmt = {
        fqdn = "edge-0.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[0].primary_ip[0].address
        prefix_length = local.subnets.inst_mgmt.prefix_length
        default_gateway = local.subnets.inst_mgmt.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[0].id
        vlan_id = var.mgmt_vlan_id
      }
      tep = {
        fqdn = ""
        ip_address = var.enable_vcf_mode ? "use-vcf-pool" : module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address 
        prefix_length = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.prefix_length : local.subnets.tep.prefix_length
        default_gateway = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.default_gateway : local.subnets.tep.default_gateway
        id = var.enable_vcf_mode ? "none" : module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[0].id 
        vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
      }
    }
    edge_1 = {
      password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
      username = "admin"
      mgmt = {
        fqdn = "edge-1.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[1].primary_ip[0].address
        prefix_length = local.subnets.inst_mgmt.prefix_length
        default_gateway = local.subnets.inst_mgmt.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[1].id
        vlan_id = var.mgmt_vlan_id
      }
      tep = {
        fqdn = ""
        ip_address = var.enable_vcf_mode ? "use-vcf-pool" : module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address
        prefix_length = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.prefix_length : local.subnets.tep.prefix_length 
        default_gateway = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.default_gateway : local.subnets.tep.default_gateway
        id = var.enable_vcf_mode ? "none" : module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[1].id
        vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
      }
    }
  }
}

locals {
  nsx_t_t0 = {
    edge_0 = {
      private_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_private[0].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_private[0].primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.private.prefix_length
        default_gateway = local.nsxt_edge_subnets.private.default_gateway
        public_ips = ""
        vlan_id = var.edge_uplink_private_vlan_id
      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public[0].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public[0].primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.public.prefix_length
        default_gateway = local.nsxt_edge_subnets.public.default_gateway
        public_ips = ""
        vlan_id = var.edge_uplink_public_vlan_id
      }
    }
    edge_1 = {
      private_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_private[1].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_private[1].primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.private.prefix_length
        default_gateway = local.nsxt_edge_subnets.private.default_gateway
        public_ips = ""
        vlan_id = var.edge_uplink_private_vlan_id

      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public[1].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public[1].primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.public.prefix_length
        default_gateway = local.nsxt_edge_subnets.public.default_gateway
        public_ips = ""
        vlan_id = var.edge_uplink_public_vlan_id
      }
    }
    ha-vip = {
      private_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_private_vip.id
        ip_address = module.zone_nxt_t_edge.t0_uplink_private_vip.primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.private.prefix_length
        default_gateway = local.nsxt_edge_subnets.private.default_gateway
        public_ips = ""
        vlan_id = var.edge_uplink_private_vlan_id

      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public_vip.id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public_vip.primary_ip[0].address
        prefix_length = local.nsxt_edge_subnets.public.prefix_length
        default_gateway = local.nsxt_edge_subnets.public.default_gateway
        public_ips = var.vpc_t0_public_ips == 0 ? [] : ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip[*].address
        vlan_id = var.edge_uplink_public_vlan_id
      }
    }
  }
}


