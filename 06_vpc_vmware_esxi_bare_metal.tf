
##############################################################
# Calculate the most recently available OS Image Name for the 
# OS Provided
##############################################################



data "ibm_is_images"  "os_images" {
    visibility = "public"
}

locals {
    os_images_filtered_esxi = [
        for image in data.ibm_is_images.os_images.images:
            image if ((image.os == var.esxi_image) && (image.status == "available"))
    ]
}

data "ibm_is_image" "vmw_esx_image" {
  name = var.esxi_image_name == "" ? local.os_images_filtered_esxi[0].name : var.esxi_image_name
}


##############################################################
# Order BMSs for Clusters in Zone
##############################################################




module "zone_bare_metal_esxi" {
  source = "./modules/vpc-bare-metal"
  for_each = var.zone_clusters

  vmw_host_list = each.value.host_list

  vmw_enable_vcf_mode = var.enable_vcf_mode
  vmw_resource_group_id = data.ibm_resource_group.resource_group_vmw.id

  vmw_vpc = ibm_is_vpc.vmware_vpc.id
  vmw_vpc_zone = var.vpc_zone
  vmw_esx_image = data.ibm_is_image.vmw_esx_image.id
  vmw_host_profile = each.value.vmw_host_profile
  #vmw_resources_prefix = local.resources_prefix
  vmw_resources_prefix = var.resource_prefix ## need to add random here
  vmw_cluster_prefix = each.value.name
  vmw_dns_servers = var.dns_servers
  vmw_host_subnet = local.subnets_map.infrastructure.host.subnet_id
  vmw_mgmt_subnet = local.subnets_map.infrastructure.mgmt.subnet_id
  vmw_vmot_subnet = local.subnets_map.infrastructure.vmot.subnet_id
  vmw_vsan_subnet = local.subnets_map.infrastructure.vsan.subnet_id
  vmw_tep_subnet = local.subnets_map.infrastructure.tep.subnet_id
  vmw_mgmt_vlan_id = var.mgmt_vlan_id
  vmw_vmot_vlan_id = var.vmot_vlan_id
  vmw_vsan_vlan_id = var.vsan_vlan_id
  vmw_tep_vlan_id = var.tep_vlan_id
  wmv_allow_vlan_list = var.vcf_architecture == "standard" ? each.value.domain == "mgmt" ? [var.wl_mgmt_vlan_id] : [] : []   # On standard deployments, add workload mgmt vlan ID to mgmt domain hosts 
  vmw_edge_tep_vlan_id = var.edge_tep_vlan_id
  vmw_edge_uplink_public_vlan_id = var.edge_uplink_public_vlan_id
  vmw_edge_uplink_private_vlan_id = var.edge_uplink_private_vlan_id
  vmw_sg_mgmt = ibm_is_security_group.sg["mgmt"].id
  vmw_sg_vmot = ibm_is_security_group.sg["vmot"].id
  vmw_sg_vsan = ibm_is_security_group.sg["vsan"].id
  vmw_sg_tep = ibm_is_security_group.sg["tep"].id
  vmw_key = ibm_is_ssh_key.host_ssh_key.id
  vmw_dns_root_domain = var.dns_root_domain
  vmw_instance_ssh_private_key = tls_private_key.host_ssh.private_key_pem
  vmw_ntp_server = var.ntp_server

  vmw_tags = local.resource_tags.bms_esx

  depends_on = [
    module.vpc_subnets,
    ibm_is_security_group.sg,
  ]
}





##############################################################
# Define cluster host setups / details 
##############################################################


locals {
 cluster_list = [ for cluster_key, cluster_value in var.zone_clusters: { cluster_key=cluster_key, name=cluster_value.name } ]
}



locals {
 zone_clusters_hosts_values = {
   clusters = {
     for k, v in local.cluster_list: v.name => {
         name = "${v.name}",
         hosts = [
          for host_k in var.zone_clusters[v.cluster_key].host_list : {
            key = host_k
            hostname = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_hostname[host_k],
            fqdn = "${module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_hostname[host_k]}.${var.dns_root_domain}",
            username = "root",
            password = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_initialization[host_k].user_accounts[0].password,
            id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_id[host_k],
            mgmt = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_mgmt_interface_ip_address[host_k],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_mgmt_interface_id[host_k],
              cidr = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.cidr : local.subnets_map.infrastructure.host.cidr,
              prefix_length = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.prefix_length : local.subnets_map.infrastructure.host.prefix_length ,
              default_gateway = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.default_gateway : local.subnets_map.infrastructure.host.default_gateway,
              vlan_id = var.enable_vcf_mode ? var.mgmt_vlan_id : 0
            },
            vmot = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vmot_ip_address[host_k],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vmot_id[host_k],
              cidr = local.subnets_map.infrastructure.vmot.cidr,
              prefix_length = local.subnets_map.infrastructure.vmot.prefix_length,
              default_gateway = local.subnets_map.infrastructure.vmot.default_gateway,
              vlan_id = var.vmot_vlan_id
            },
            vsan = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vsan_ip_address[host_k],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vsan_id[host_k],
              cidr = local.subnets_map.infrastructure.vsan.cidr,
              prefix_length = local.subnets_map.infrastructure.vsan.prefix_length,
              default_gateway = local.subnets_map.infrastructure.vsan.default_gateway,
              vlan_id = var.vsan_vlan_id
            },
            tep = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_tep_ip_address[host_k],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_tep_id[host_k],
              cidr = local.subnets_map.infrastructure.tep.cidr,
              prefix_length = local.subnets_map.infrastructure.tep.prefix_length,
              default_gateway = local.subnets_map.infrastructure.tep.default_gateway,
              vlan_id = var.tep_vlan_id
            }
          }
        ]
      }
    }
  }
}

#*/






/*backup sami

locals {
 zone_clusters_hosts_values = {
   clusters = {
     for k, v in local.cluster_list: v.name => {
         name = "${v.name}",
         hosts = [
          for host in var.zone_clusters[v.cluster_key].host_list : {
            key = host
            hostname = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_hostname[host],
            fqdn = "${module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_hostname[host]}.${var.dns_root_domain}",
            username = "root",
            password = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_initialization[host].user_accounts[0].password,
            id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_id[host],
            mgmt = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_mgmt_interface_ip_address[host],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_mgmt_interface_id[host],
              cidr = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.cidr : local.subnets_map.infrastructure.host.cidr,
              prefix_length = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.prefix_length : local.subnets_map.infrastructure.host.prefix_length ,
              default_gateway = var.enable_vcf_mode ? local.subnets_map.infrastructure.mgmt.default_gateway : local.subnets_map.infrastructure.host.default_gateway,
              vlan_id = var.enable_vcf_mode ? var.mgmt_vlan_id : 0
            },
            vmot = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vmot_ip_address[host],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vmot_id[host],
              cidr = local.subnets_map.infrastructure.vmot.cidr,
              prefix_length = local.subnets_map.infrastructure.vmot.prefix_length,
              default_gateway = local.subnets_map.infrastructure.vmot.default_gateway,
              vlan_id = var.vmot_vlan_id
            },
            vsan = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vsan_ip_address[host],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_vsan_id[host],
              cidr = local.subnets_map.infrastructure.vsan.cidr,
              prefix_length = local.subnets_map.infrastructure.vsan.prefix_length,
              default_gateway = local.subnets_map.infrastructure.vsan.default_gateway,
              vlan_id = var.vsan_vlan_id
            },
            tep = {
              ip_address = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_tep_ip_address[host],
              vlan_nic_id = module.zone_bare_metal_esxi[v.cluster_key].ibm_is_bare_metal_server_network_interface_tep_id[host],
              cidr = local.subnets_map.infrastructure.tep.cidr,
              prefix_length = local.subnets_map.infrastructure.tep.prefix_length,
              default_gateway = local.subnets_map.infrastructure.tep.default_gateway,
              vlan_id = var.tep_vlan_id
            }
          }
        ]
      }
    }
  }
}
*/
