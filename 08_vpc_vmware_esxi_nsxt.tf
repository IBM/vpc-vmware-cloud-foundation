

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
# Create VLAN interfaces for VI Workload NSX-T Managers
##############################################################

locals {
  zone_clusters_nsx_t_managers = {
    for k, v in var.zone_clusters : k => v if v.nsx_t_managers == true
  }
}


module "zone_nxt_t_mgrs" {
  source                          = "./modules/vpc-nsx-t"
  for_each                        = local.zone_clusters_vcenters

  vmw_vpc                         = ibm_is_vpc.vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_mgmt_subnet_id              = each.value.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].subnet_id : local.subnets_map.infrastructure["wl-mgmt"].subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[var.zone_clusters["cluster_0"].host_list[0]]   # Note deploy NSX-T managers on mgmt cluster.
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id                = each.value.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id

  vmw_nsx_t_name                  = "${each.value.name}-nsx-t"

  depends_on = [
      module.vpc_subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
    ]
}


##############################################################
# Define output maps for VI Workload NSX-T Managers
##############################################################


locals {
  zone_clusters_nsx_t_managers_values = {
    for k, v in var.zone_clusters : v.name => {
      nsx_t_0 = {
        hostname = "${v.name}-nsx-t-0"
        fqdn = "${v.name}-nsx-t-0.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[0].primary_ip[0].address
        prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
        default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
        id = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[0].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
      },
      nsx_t_1 = {
        hostname = "${v.name}-nsx-t-1"
        fqdn = "${v.name}-nsx-t-1.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[1].primary_ip[0].address
        prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
        default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
        id = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[1].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
      },
      nsx_t_2 = {
        hostname = "${v.name}-nsx-t-2"
        fqdn = "${v.name}-nsx-t-2.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[2].primary_ip[0].address
        prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
        default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
        id = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip[2].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
      },
      nsx_t_vip = {
        hostname = "${v.name}-nsx-t-vip"
        fqdn = "${v.name}-nsx-t-vip.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip_vip.primary_ip[0].address
        prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
        default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
        id = module.zone_nxt_t_mgrs[k].vmw_nsx_t_manager_ip_vip.id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
      }
    } if v.nsx_t_managers == true
  }
}


##############################################################
# Create VLAN interfaces for VI Workload NSX-T Edges
##############################################################

locals {
  zone_clusters_nsx_t_edges = {
    for k, v in var.zone_clusters : k => v if v.nsx_t_edges == true
  }
}


module "zone_nxt_t_edges" {
  source                          = "./modules/vpc-nsx-t-edge"
  for_each                        = local.zone_clusters_nsx_t_edges

  vmw_enable_vcf_mode             = var.enable_vcf_mode

  vmw_vpc                         = ibm_is_vpc.vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id

  vmw_priv_subnet_id              = each.value.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].subnet_id : local.subnets_map.edges["wl-t0-priv"].subnet_id
  vmw_pub_subnet_id               = each.value.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].subnet_id : local.subnets_map.edges["wl-t0-pub"].subnet_id
  vmw_mgmt_subnet_id              = each.value.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].subnet_id : local.subnets_map.infrastructure["wl-mgmt"].subnet_id
  vmw_tep_subnet_id               = var.enable_vcf_mode ? each.value.domain == "mgmt" ? local.subnets_map.edges["edge-tep"].subnet_id : local.subnets_map.edges["wl-edge-tep"].subnet_id : local.subnets_map.infrastructure["tep"].subnet_id

  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi[each.key].ibm_is_bare_metal_server_id[var.zone_clusters[each.key].host_list[0]] # Deploy edges on workload cluster

  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_sg_tep                      = ibm_is_security_group.sg["tep"].id
  vmw_sg_uplink_pub               = ibm_is_security_group.sg["uplink-pub"].id
  vmw_sg_uplink_priv              = ibm_is_security_group.sg["uplink-priv"].id

  vmw_mgmt_vlan_id                = each.value.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
  vmw_tep_vlan_id                 = var.enable_vcf_mode ? each.value.domain == "mgmt" ? var.edge_tep_vlan_id : var.wl_mgmt_vlan_id : var.tep_vlan_id
  vmw_edge_uplink_public_vlan_id  = each.value.domain == "mgmt" ? var.edge_uplink_public_vlan_id : var.wl_edge_uplink_public_vlan_id
  vmw_edge_uplink_private_vlan_id = each.value.domain == "mgmt" ? var.edge_uplink_private_vlan_id : var.wl_edge_uplink_public_vlan_id

  vmw_edge_name                   = "${each.value.name}-edge"
  vmw_t0_name                     = "${each.value.name}-t0"

  depends_on = [
      module.vpc_subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
    ]
}






##############################################################
# Define output maps for VI Workload NSX-T Edges
##############################################################



locals {
  zone_clusters_nsx_t_edges_values = {
    for k, v in var.zone_clusters : v.name => {
      edge_0 = {
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        username = "admin"
        hostname = "${v.name}-edge-0"
        mgmt = {
          fqdn = "${v.name}-edge-0.${var.dns_root_domain}"
          ip_address = module.zone_nxt_t_edges[k].vmw_nsx_t_edge_mgmt_ip[0].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
          id = module.zone_nxt_t_edges[k].vmw_nsx_t_edge_mgmt_ip[0].id
          vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
        }
        tep = {
          fqdn = ""
          ip_address = var.enable_vcf_mode ? [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address, module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address] : [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address] 
          prefix_length = var.enable_vcf_mode ? v.domain == "mgmt" ? local.subnets_map.edges["edge-tep"].prefix_length : local.subnets_map.edges["wl-edge-tep"].prefix_length : local.subnets_map.infrastructure["tep"].prefix_length
          default_gateway = var.enable_vcf_mode ? v.domain == "mgmt" ? local.subnets_map.edges["edge-tep"].default_gateway : local.subnets_map.edges["wl-edge-tep"].default_gateway : local.subnets_map.infrastructure["tep"].default_gateway
          id = var.enable_vcf_mode ? [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[0].id, module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[1].id] : [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[0].id]
          vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
        }
      },
      edge_1 = {
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        username = "admin"
        hostname = "${v.name}-edge-1"
        mgmt = {
          fqdn = "${v.name}-edge-1.${var.dns_root_domain}"
          ip_address = module.zone_nxt_t_edges[k].vmw_nsx_t_edge_mgmt_ip[1].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
          id = module.zone_nxt_t_edges[k].vmw_nsx_t_edge_mgmt_ip[1].id
          vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
        }
        tep = {
          fqdn = ""
          ip_address = var.enable_vcf_mode ? [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[2].primary_ip[0].address, module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[3].primary_ip[0].address] : [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address]
          prefix_length = var.enable_vcf_mode ? v.domain == "mgmt" ? local.subnets_map.edges["edge-tep"].prefix_length : local.subnets_map.edges["wl-edge-tep"].prefix_length : local.subnets_map.infrastructure["tep"].prefix_length
          default_gateway = var.enable_vcf_mode ? v.domain == "mgmt" ? local.subnets_map.edges["edge-tep"].default_gateway : local.subnets_map.edges["wl-edge-tep"].default_gateway : local.subnets_map.infrastructure["tep"].default_gateway
          id = var.enable_vcf_mode ? [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[2].id, module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[3].id] : [module.zone_nxt_t_edges[k].vmw_nsx_t_edge_tep_ip[1].id]
          vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
        }
      }
    } if v.nsx_t_edges == true
  }
}



locals {
  zone_clusters_nsx_t_t0_values = {
    for k, v in var.zone_clusters : v.name => {
      edge_0 = {
        private_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_private[0].id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_private[0].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].prefix_length : local.subnets_map.edges["wl-t0-priv"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].default_gateway : local.subnets_map.edges["wl-t0-priv"].default_gateway
          public_ips = []
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_private_vlan_id : var.wl_edge_uplink_private_vlan_id 
        }
        public_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_public[0].id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_public[0].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].prefix_length : local.subnets_map.edges["wl-t0-pub"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].default_gateway : local.subnets_map.edges["wl-t0-pub"].default_gateway
          public_ips = []
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_public_vlan_id : var.wl_edge_uplink_public_vlan_id
        }
      }
      edge_1 = {
        private_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_private[1].id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_private[1].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].prefix_length : local.subnets_map.edges["wl-t0-priv"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].default_gateway : local.subnets_map.edges["wl-t0-priv"].default_gateway
          public_ips = []
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_private_vlan_id : var.wl_edge_uplink_private_vlan_id 

        }
        public_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_public[1].id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_public[1].primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].prefix_length : local.subnets_map.edges["wl-t0-pub"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].default_gateway : local.subnets_map.edges["wl-t0-pub"].default_gateway
          public_ips = []
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_public_vlan_id : var.wl_edge_uplink_public_vlan_id
        }
      }
      ha-vip = {
        private_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_private_vip.id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_private_vip.primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].prefix_length : local.subnets_map.edges["wl-t0-priv"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-priv"].default_gateway : local.subnets_map.edges["wl-t0-priv"].default_gateway
          public_ips = []
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_private_vlan_id : var.wl_edge_uplink_private_vlan_id 

        }
        public_uplink = {
          id = module.zone_nxt_t_edges[k].t0_uplink_public_vip.id
          ip_address = module.zone_nxt_t_edges[k].t0_uplink_public_vip.primary_ip[0].address
          prefix_length = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].prefix_length : local.subnets_map.edges["wl-t0-pub"].prefix_length
          default_gateway = v.domain == "mgmt" ? local.subnets_map.edges["t0-pub"].default_gateway : local.subnets_map.edges["wl-t0-pub"].default_gateway
          public_ips = var.zone_clusters[k].public_ips == 0 ? [] : [for flip_k,flip_v in local.zone_clusters_vi_nsx_t_t0_flips_map : ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip_nsx_t[flip_k].address if flip_v.cluster_name == v.name ]
          vlan_id = v.domain == "mgmt" ? var.edge_uplink_public_vlan_id : var.wl_edge_uplink_public_vlan_id
        }
      }
    } if v.nsx_t_edges == true
  }
}




##############################################################
# Create Floating Public IPs to public VIP
##############################################################



locals {
  zone_clusters_nsx_t_t0_flips_list = flatten ([
    for k, v in var.zone_clusters : [
      for i,ip_v in range(v.public_ips) : {
        name = "${v.name}-t0-uplink-public-floating-ip-${ip_v}"
        cluster_name = v.name
        cluster_key = k
        }
    ] if v.nsx_t_edges == true
  ])
  zone_clusters_vi_nsx_t_t0_flips_map = {
    for v in local.zone_clusters_nsx_t_t0_flips_list : v.name => v
  }
}



resource "ibm_is_floating_ip" "floating_ip_nsx_t" {
  for_each          = local.zone_clusters_vi_nsx_t_t0_flips_map
  name              = "${local.resources_prefix}-vlan-nic-${each.value.name}"
  zone              = var.vpc_zone

  tags = local.resource_tags.floating_ip_t0

  depends_on = [
      module.vpc_subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
      module.zone_nxt_t_edges
    ]
}



resource "ibm_is_bare_metal_server_network_interface_floating_ip" "t0_public_vip_floating_ip_nsx_t" {
  for_each          = local.zone_clusters_vi_nsx_t_t0_flips_map
  bare_metal_server = module.zone_bare_metal_esxi[each.value.cluster_key].ibm_is_bare_metal_server_id[var.zone_clusters[each.value.cluster_key].host_list[0]]
  network_interface = module.zone_nxt_t_edges[each.value.cluster_key].t0_uplink_public_vip.id
  floating_ip       = ibm_is_floating_ip.floating_ip_nsx_t[each.key].id
  depends_on = [
    module.vpc_subnets,
    module.zone_bare_metal_esxi,
    ibm_is_security_group.sg,
    module.zone_nxt_t_edges,
    ibm_is_floating_ip.floating_ip_nsx_t
  ]
}
