##############################################################
# Create VLAN interfaces for vCenter for VI workload
##############################################################

# This will create VLAN nic for the first host of the VI workload
# cluster, if the cluster map as vcenter = true.  

locals {
  zone_clusters_vi_vcenters = {
    for k, v in var.zone_clusters : k => v if v.name != "mgmt" && v.vcenter == true
  }
}

module "zone_vcenter_vi_workload" {
  source                      = "./modules/vpc-vcenter"
  for_each                    = local.zone_clusters_vi_vcenters

  vmw_resource_group_id       = data.ibm_resource_group.resource_group_vmw.id
  vmw_mgmt_subnet             = local.subnets.mgmt.subnet_id
  vmw_vcenter_esx_host_id     = module.zone_bare_metal_esxi[each.key].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt                 = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id            = var.mgmt_vlan_id

  vmw_vcenter_name            = "${each.value.name}-vcenter"

  depends_on = [
    module.vpc-subnets,
    ibm_is_security_group.sg,
    module.zone_bare_metal_esxi
  ]
}

##############################################################
# Define output maps for VI Workload vCenters
##############################################################

locals {
  zone_clusters_vi_vcenters_values = {
    for k, v in var.zone_clusters : v.name => {
      host_name = "${v.name}-vcenter"
      fqdn = "${v.name}-vcenter.${var.dns_root_domain}"
      ip_address = module.zone_vcenter_vi_workload[k].vmw_vcenter_ip
      prefix_length = local.subnets.mgmt.prefix_length
      default_gateway = local.subnets.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets.mgmt.subnet_id
      username = "administrator@vsphere.local"
      password = var.vcf_password == "" ? random_string.vcenter_password.result : var.vcf_password
    } if v.name != "mgmt" && v.vcenter == true
  }
}


##############################################################
# Create VLAN interfaces for VI Workload NSX-T Managers
##############################################################

locals {
  zone_clusters_vi_nsx_t_managers = {
    for k, v in var.zone_clusters : k => v if v.name != "mgmt" && v.nsx_t_managers == true
  }
}

module "zone_nxt_t_vi_workload" {
  source                          = "./modules/vpc-nsx-t"
  for_each                        = local.zone_clusters_vi_vcenters

  vmw_vpc                         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_mgmt_subnet_id              = local.subnets.mgmt.subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]   # Note deploy NSX-T managers on mgmt cluster.
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id                = var.mgmt_vlan_id

  vmw_nsx_t_name                  = "${each.value.name}-nsx-t"

  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
    ]
}

##############################################################
# Define output maps for VI Workload NSX-T Managers
##############################################################



locals {
  zone_clusters_vi_nsx_t_managers_values = {
    for k, v in var.zone_clusters : v.name => {
      nsx_t_0 = {
        host_name = "${v.name}-nsx-t-0"
        fqdn = "${v.name}-nsx-t-0.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[0].primary_ip[0].address
        prefix_length = local.subnets.mgmt.prefix_length
        default_gateway = local.subnets.mgmt.default_gateway
        id = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[0].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = var.mgmt_vlan_id
      },
      nsx_t_1 = {
        host_name = "${v.name}-nsx-t-1"
        fqdn = "${v.name}-nsx-t-1.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[1].primary_ip[0].address
        prefix_length = local.subnets.mgmt.prefix_length
        default_gateway = local.subnets.mgmt.default_gateway
        id = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[1].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = var.mgmt_vlan_id
      },
      nsx_t_2 = {
        host_name = "${v.name}-nsx-t-2"
        fqdn = "${v.name}-nsx-t-2.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[2].primary_ip[0].address
        prefix_length = local.subnets.mgmt.prefix_length
        default_gateway = local.subnets.mgmt.default_gateway
        id = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip[2].id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = var.mgmt_vlan_id
      },
      nsx_t_vip = {
        host_name = "${v.name}-nsx-t-vip"
        fqdn = "${v.name}-nsx-t-vip.${var.dns_root_domain}"
        ip_address = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip_vip.primary_ip[0].address
        prefix_length = local.subnets.mgmt.prefix_length
        default_gateway = local.subnets.mgmt.default_gateway
        id = module.zone_nxt_t_vi_workload[k].vmw_nsx_t_manager_ip_vip.id
        username = "admin"
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        vlan_id = var.mgmt_vlan_id
      }
    } if v.name !=  "mgmt" && v.nsx_t_managers == true
  }
}


##############################################################
# Create VLAN interfaces for VI Workload NSX-T Edges
##############################################################

locals {
  zone_clusters_vi_nsx_t_edges = {
    for k, v in var.zone_clusters : k => v if v.name != "mgmt" && v.nsx_t_edges == true
  }
}


module "zone_nxt_t_edge_vi_workload" {
  source                          = "./modules/vpc-nsx-t-edge"
  for_each                        = local.zone_clusters_vi_nsx_t_edges

  vmw_enable_vcf_mode             = var.enable_vcf_mode

  vmw_vpc                         = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone                    = var.vpc_zone
  vmw_resources_prefix            = local.resources_prefix
  vmw_resource_group_id           = data.ibm_resource_group.resource_group_vmw.id
  vmw_priv_subnet_id              = local.nsxt_edge_subnets.private.subnet_id
  vmw_pub_subnet_id               = local.nsxt_edge_subnets.public.subnet_id
  vmw_mgmt_subnet_id              = local.subnets.mgmt.subnet_id
  vmw_tep_subnet_id               = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.subnet_id : local.subnets.tep.subnet_id
  vmw_vcenter_esx_host_id         = module.zone_bare_metal_esxi[each.key].ibm_is_bare_metal_server_id[0] # Deploy edges on workload cluster
  vmw_sg_mgmt                     = ibm_is_security_group.sg["mgmt"].id
  vmw_sg_tep                      = ibm_is_security_group.sg["tep"].id
  vmw_sg_uplink_pub               = ibm_is_security_group.sg["uplink-pub"].id
  vmw_sg_uplink_priv              = ibm_is_security_group.sg["uplink-priv"].id

  vmw_mgmt_vlan_id                = var.mgmt_vlan_id
  vmw_tep_vlan_id                 = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
  vmw_edge_uplink_public_vlan_id  = var.edge_uplink_public_vlan_id
  vmw_edge_uplink_private_vlan_id = var.edge_uplink_private_vlan_id

  vmw_edge_name                   = "${each.value.name}-edge"
  vmw_t0_name                     = "${each.value.name}-t0"

  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
    ]
}





##############################################################
# Create Floating Public IPs to public VIP
##############################################################



locals {
  zone_clusters_vi_vi_nsx_t_t0_flips_list = flatten ([
    for k, v in var.zone_clusters : [
      for i,ip_v in range(v.public_ips) : {
        name = "${v.name}-t0-uplink-public-floating-ip-${ip_v}"
        cluster_name = v.name
        cluster_key = k
        }
    ] if v.name != "mgmt" && v.nsx_t_edges == true
  ])
  zone_clusters_vi_vi_nsx_t_t0_flips_map = {
    for v in local.zone_clusters_vi_vi_nsx_t_t0_flips_list : v.name => v
  }
}



resource "ibm_is_floating_ip" "floating_ip_vi_workload" {
  for_each          = local.zone_clusters_vi_vi_nsx_t_t0_flips_map
  name              = "${local.resources_prefix}-vlan-nic-${each.value.name}"
  zone              = var.vpc_zone

  tags = local.resource_tags.floating_ip_t0

  depends_on = [
      module.vpc-subnets,
      module.zone_bare_metal_esxi,
      ibm_is_security_group.sg,
      module.zone_nxt_t_edge_vi_workload
    ]
}



resource "ibm_is_bare_metal_server_network_interface_floating_ip" "t0_public_vip_floating_ip_vi_workload" {
  for_each          = local.zone_clusters_vi_vi_nsx_t_t0_flips_map
  bare_metal_server = module.zone_bare_metal_esxi[each.value.cluster_key].ibm_is_bare_metal_server_id[0]
  network_interface = module.zone_nxt_t_edge_vi_workload[each.value.cluster_key].t0_uplink_public_vip.id
  floating_ip       = ibm_is_floating_ip.floating_ip_vi_workload[each.key].id
  depends_on = [
    module.vpc-subnets,
    module.zone_bare_metal_esxi,
    ibm_is_security_group.sg,
    module.zone_nxt_t_edge,
    ibm_is_floating_ip.floating_ip_vi_workload
  ]
}

/*

resource.ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip_vi_workload[*].


*/



##############################################################
# Define output maps for VI Workload NSX-T Edges
##############################################################



locals {
  zone_clusters_vi_nsx_t_edges_values = {
    for k, v in var.zone_clusters : v.name => {
      edge_0 = {
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        username = "admin"
        host_name = "${v.name}-edge-0"
        mgmt = {
          fqdn = "${v.name}-edge-0.${var.dns_root_domain}"
          ip_address = module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_mgmt_ip[0].primary_ip[0].address
          prefix_length = local.subnets.mgmt.prefix_length
          default_gateway = local.subnets.mgmt.default_gateway
          id = module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_mgmt_ip[0].id
          vlan_id = var.mgmt_vlan_id
        }
        tep = {
          fqdn = ""
          ip_address = var.enable_vcf_mode ? [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address, module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address] : [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[0].primary_ip[0].address] 
          prefix_length = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.prefix_length : local.subnets.tep.prefix_length
          default_gateway = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.default_gateway : local.subnets.tep.default_gateway
          id = var.enable_vcf_mode ? [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[0].id, module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[1].id] : [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[0].id]
          vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
        }
      },
      edge_1 = {
        password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password
        username = "admin"
        host_name = "${v.name}-edge-1"
        mgmt = {
          fqdn = "${v.name}-edge-1.${var.dns_root_domain}"
          ip_address = module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_mgmt_ip[1].primary_ip[0].address
          prefix_length = local.subnets.mgmt.prefix_length
          default_gateway = local.subnets.mgmt.default_gateway
          id = module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_mgmt_ip[1].id
          vlan_id = var.mgmt_vlan_id
        }
        tep = {
          fqdn = ""
          ip_address = var.enable_vcf_mode ? [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[2].primary_ip[0].address, module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[3].primary_ip[0].address] : [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[1].primary_ip[0].address]
          prefix_length = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.prefix_length : local.subnets.tep.prefix_length 
          default_gateway = var.enable_vcf_mode ? local.nsxt_edge_subnets.edge_tep.default_gateway : local.subnets.tep.default_gateway
          id = var.enable_vcf_mode ? [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[2].id, module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[3].id] : [module.zone_nxt_t_edge_vi_workload[k].vmw_nsx_t_edge_tep_ip[1].id]
          vlan_id = var.enable_vcf_mode ? var.edge_tep_vlan_id : var.tep_vlan_id
        }
      }
    } if v.name !=  "mgmt" && v.nsx_t_edges == true
  }
}


locals {
  zone_clusters_vi_nsx_t_t0_values = {
    for k, v in var.zone_clusters : v.name => {
      edge_0 = {
        private_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private[0].id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private[0].primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.private.prefix_length
          default_gateway = local.nsxt_edge_subnets.private.default_gateway
          public_ips = ""
          vlan_id = var.edge_uplink_private_vlan_id
        }
        public_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public[0].id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public[0].primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.public.prefix_length
          default_gateway = local.nsxt_edge_subnets.public.default_gateway
          public_ips = ""
          vlan_id = var.edge_uplink_public_vlan_id
        }
      }
      edge_1 = {
        private_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private[1].id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private[1].primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.private.prefix_length
          default_gateway = local.nsxt_edge_subnets.private.default_gateway
          public_ips = ""
          vlan_id = var.edge_uplink_private_vlan_id

        }
        public_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public[1].id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public[1].primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.public.prefix_length
          default_gateway = local.nsxt_edge_subnets.public.default_gateway
          public_ips = ""
          vlan_id = var.edge_uplink_public_vlan_id
        }
      }
      ha-vip = {
        private_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private_vip.id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_private_vip.primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.private.prefix_length
          default_gateway = local.nsxt_edge_subnets.private.default_gateway
          public_ips = ""
          vlan_id = var.edge_uplink_private_vlan_id

        }
        public_uplink = {
          id = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public_vip.id
          ip_address = module.zone_nxt_t_edge_vi_workload[k].t0_uplink_public_vip.primary_ip[0].address
          prefix_length = local.nsxt_edge_subnets.public.prefix_length
          default_gateway = local.nsxt_edge_subnets.public.default_gateway
          #public_ips = var.vpc_t0_public_ips == 0 ? [] : ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip[*].address
          public_ips = var.zone_clusters[k].public_ips == 0 ? [] : [for k,v in local.zone_clusters_vi_vi_nsx_t_t0_flips_map : ibm_is_bare_metal_server_network_interface_floating_ip.t0_public_vip_floating_ip_vi_workload[k].address]
          vlan_id = var.edge_uplink_public_vlan_id
        }
      }
    } if v.name !=  "mgmt" && v.nsx_t_edges == true
  }
}





##############################################################
#  DNS records for VI Workload Domain Appliances 
##############################################################


locals {
  zone_clusters_vi_dns_records = {
    for cluster_k, cluster_v in var.zone_clusters : cluster_v.name => [
      concat(
        [for k, v in local.zone_clusters_vi_vcenters_values : { name = v.host_name, ip_address = v.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_managers_values : { name = v.nsx_t_0.host_name, ip_address = v.nsx_t_0.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_managers_values : { name = v.nsx_t_1.host_name, ip_address = v.nsx_t_1.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_managers_values : { name = v.nsx_t_2.host_name, ip_address = v.nsx_t_2.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_managers_values : { name = v.nsx_t_vip.host_name, ip_address = v.nsx_t_vip.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_edges_values : { name = v.edge_0.host_name, ip_address = v.edge_0.mgmt.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_vi_nsx_t_edges_values : { name = v.edge_1.host_name, ip_address = v.edge_1.mgmt.ip_address} if k == cluster_v.name],
      )
    ] if cluster_v.name !=  "mgmt"
  }
}







##############################################################
##############################################################
#  Outputs
##############################################################
##############################################################



##############################################################
#  Output VI Workload vcenters
##############################################################


output "vi_workload_vcenters" {
  value = local.zone_clusters_vi_vcenters_values
}



##############################################################
#  Output VI Workload VI Workload NSX-T Managers
##############################################################


output "vi_workload_nsx_t_managers" {
  value = local.zone_clusters_vi_nsx_t_managers_values
}



##############################################################
#  Output VI Workload VI Workload NSX-T Edges
##############################################################


output "vi_workload_nsx_t_edges" {
  value = local.zone_clusters_vi_nsx_t_edges_values
}



##############################################################
#  Output VI Workload VI Workload NSX-T T0s
##############################################################


output "vi_workload_nsx_t_t0s" {
  value = local.zone_clusters_vi_nsx_t_t0_values
}
