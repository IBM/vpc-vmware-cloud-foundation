
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
  vmw_enable_vcf_mode = var.enable_vcf_mode
  vmw_resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  vmw_host_count = each.value.host_count
  vmw_vpc = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  vmw_vpc_zone = var.vpc_zone
  vmw_esx_image = data.ibm_is_image.vmw_esx_image.id
  vmw_host_profile = each.value.vmw_host_profile
  vmw_resources_prefix = var.resource_prefix ## need to add random here
  vmw_cluster_prefix = each.value.name
  vmw_dns_servers = var.dns_servers
  vmw_host_subnet = local.subnets.hosts.subnet_id
  vmw_mgmt_subnet = local.subnets.inst_mgmt.subnet_id
  vmw_vmot_subnet = local.subnets.vmot.subnet_id
  vmw_vsan_subnet = local.subnets.vsan.subnet_id
  vmw_tep_subnet = local.subnets.tep.subnet_id
  vmw_mgmt_vlan_id = var.mgmt_vlan_id
  vmw_vmot_vlan_id = var.vmot_vlan_id
  vmw_vsan_vlan_id = var.vsan_vlan_id
  vmw_tep_vlan_id = var.tep_vlan_id
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
    module.vpc-subnets,
    ibm_is_security_group.sg,
  ]
}





##############################################################
# Define cluster host setups / details 
##############################################################

locals {
 cluster_list = [ for cluster_key, cluster_value in var.zone_clusters: cluster_key ]
}




#/*
locals {
 cluster_host_map = {
   "clusters": [
     for cluster_name in local.cluster_list: {
         "name": "${cluster_name}",
         "hosts": [
           for host in range(length(module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_fqdn[*])): {
             "host" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_fqdn[host],
             "username" : "root",
             "password" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_initialization[host].user_accounts[0].password,
             "id" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_id[host],
             "mgmt" : {
                "ip_address" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_mgmt_interface_ip_address[host],
                "vlan_nic_id" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_mgmt_interface_id[host],
                "cidr" : var.enable_vcf_mode ? local.subnets.inst_mgmt.cidr : local.subnets.hosts.cidr,
                "prefix_length" : var.enable_vcf_mode ? local.subnets.inst_mgmt.prefix_length : local.subnets.hosts.prefix_length ,
                "default_gateway" : var.enable_vcf_mode ? local.subnets.inst_mgmt.default_gateway : local.subnets.hosts.default_gateway,
                "vlan_id" : var.enable_vcf_mode ? var.mgmt_vlan_id : 0
              },
              "vmot" : {
                "ip_address" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_vmot_ip_address[host],
                "vlan_nic_id" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_vmot_id[host],
                "cidr" : local.subnets.vmot.cidr,
                "prefix_length" : local.subnets.vmot.prefix_length,
                "default_gateway" : local.subnets.vmot.default_gateway,
                "vlan_id" : var.vmot_vlan_id
              },
              "vsan" : {
                "ip_address" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_vsan_ip_address[host],
                "vlan_nic_id" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_vsan_id[host],
                "cidr" : local.subnets.vsan.cidr,
                "prefix_length" : local.subnets.vsan.prefix_length,
                "default_gateway" : local.subnets.vsan.default_gateway,
                "vlan_id" : var.vsan_vlan_id
              },
              "tep" : {
                "ip_address" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_tep_ip_address[host],
                "vlan_nic_id" : module.zone_bare_metal_esxi[cluster_name].ibm_is_bare_metal_server_network_interface_tep_id[host],
                "cidr" : local.subnets.tep.cidr,
                "prefix_length" : local.subnets.tep.prefix_length,
                "default_gateway" : local.subnets.tep.default_gateway,
                "vlan_id" : var.tep_vlan_id
              }
            }
         ]
       }
   ]
  }
}
#*/

