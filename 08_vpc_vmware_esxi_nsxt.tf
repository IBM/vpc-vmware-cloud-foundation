##############################################################
# Create VLAN interface resources for host TEPs (new)
##############################################################

# Note...TEPs provisioned as follows allow floating - can be used in pool  

locals {
  hosts_total = sum(flatten([
      for cluster_name in keys(var.zone_clusters): 
          var.zone_clusters[cluster_name].host_count
    ]))
}

resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_host_teps" {
    count = local.hosts_total

    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
    subnet = local.subnets.tep.subnet_id
    name   = "vlan-nic-tep-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["tep"].id]
    allow_ip_spoofing = false
    vlan = 400
}


locals {
  zone_host_teps = [for tep in ibm_is_bare_metal_server_network_interface_allow_float.zone_host_teps : {
      ip_address = tep.primary_ip[0].address
      vlan_nic_id = tep.id
      vlan_nic_name = tep.name
    }]
}

# for file_share in var.zone_clusters[cluster_name].vpc_file_shares: {
#             "name": file_share.name
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
  vmw_vpc                         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_priv_subnet_id              = local.nsxt_uplink_subnets.private.subnet_id
  vmw_pub_subnet_id               = local.nsxt_uplink_subnets.public.subnet_id
  vmw_inst_mgmt_subnet_id         = local.subnets.inst_mgmt.subnet_id
  vmw_tep_subnet_id               = local.subnets.tep.subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_sg_tep                      = ibm_is_security_group.sg["tep"].id
  vmw_sg_uplink                   = ibm_is_security_group.sg["uplink"].id
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
  name              = "vlan-nic-t0-uplink-public-flip-${count.index}"
  zone              = var.vpc_zone
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


resource "random_string" "nsxt_mgr_password" {
  length           = 16
  special          = true
  number           = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "_/@<>"
}

resource "random_string" "nsxt_edge_password" {
  length           = 16
  special          = true
  number           = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "_/!<>"
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
      password = random_string.nsxt_mgr_password.result
      vlan_id = "100"
    }
    nsx_t_1 = {
      fqdn = "nsx-t-1.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[1].primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip[1].id
      username = "admin"
      password = random_string.nsxt_mgr_password.result
      vlan_id = "100"
    }
    nsx_t_2 = {
      fqdn = "nsx-t-2.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[2].primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip[2].id
      username = "admin"
      password = random_string.nsxt_mgr_password.result
      vlan_id = "100"
    }
    nsx_t_vip = {
      fqdn = "nsx-t-vip.${var.dns_root_domain}"
      ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.primary_ip[0].address
      prefix_length = local.subnets.inst_mgmt.prefix_length
      default_gateway = local.subnets.inst_mgmt.default_gateway
      id = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.id
      username = "admin"
      password = random_string.nsxt_mgr_password.result
      vlan_id = "100"
    }
  }
}

locals {
  nsx_t_edge = {
    edge_0 = {
      password = random_string.nsxt_edge_password.result
      username = "admin"
      mgmt = {
        fqdn = "edge-1.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[0].primary_ip[0].address
        prefix_length = local.subnets.inst_mgmt.prefix_length
        default_gateway = local.subnets.inst_mgmt.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[0].id
        vlan_id = "100"
      }
      tep = {
        fqdn = ""
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address
        prefix_length = local.subnets.tep.prefix_length
        default_gateway = local.subnets.tep.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[0].id
        vlan_id = "400"
      }
    }
    edge_1 = {
      password = random_string.nsxt_edge_password.result
      username = "admin"
      mgmt = {
        fqdn = "edge-2.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[1].primary_ip[0].address
        prefix_length = local.subnets.inst_mgmt.prefix_length
        default_gateway = local.subnets.inst_mgmt.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[1].id
        vlan_id = "100"
      }
      tep = {
        fqdn = ""
        ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address
        prefix_length = local.subnets.tep.prefix_length
        default_gateway = local.subnets.tep.default_gateway
        id = module.zone_nxt_t_edge.vmw_nsx_t_edge_tep_ip[1].id
        vlan_id = "400"
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
        prefix_length = local.nsxt_uplink_subnets.private.prefix_length
        default_gateway = local.nsxt_uplink_subnets.private.default_gateway
        public_ips = ""
        vlan_id = "710"
      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public[0].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public[0].primary_ip[0].address
        prefix_length = local.nsxt_uplink_subnets.public.prefix_length
        default_gateway = local.nsxt_uplink_subnets.public.default_gateway
        public_ips = ""
        vlan_id = "700"
      }
    }
    edge_1 = {
      private_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_private[1].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_private[1].primary_ip[0].address
        prefix_length = local.nsxt_uplink_subnets.private.prefix_length
        default_gateway = local.nsxt_uplink_subnets.private.default_gateway
        public_ips = ""
        vlan_id = "710"

      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public[1].id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public[1].primary_ip[0].address
        prefix_length = local.nsxt_uplink_subnets.public.prefix_length
        default_gateway = local.nsxt_uplink_subnets.public.default_gateway
        public_ips = ""
        vlan_id = "700"
      }
    }
    ha-vip = {
      private_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_private_vip.id
        ip_address = module.zone_nxt_t_edge.t0_uplink_private_vip.primary_ip[0].address
        prefix_length = local.nsxt_uplink_subnets.private.prefix_length
        default_gateway = local.nsxt_uplink_subnets.private.default_gateway
        public_ips = ""
        vlan_id = "710"

      }
      public_uplink = {
        id = module.zone_nxt_t_edge.t0_uplink_public_vip.id
        ip_address = module.zone_nxt_t_edge.t0_uplink_public_vip.primary_ip[0].address
        prefix_length = local.nsxt_uplink_subnets.public.prefix_length
        default_gateway = local.nsxt_uplink_subnets.public.default_gateway
        public_ips = var.vpc_t0_public_ips == 0 ? [] : ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip[*].address
        vlan_id = "700"
      }
    }
  }
}
