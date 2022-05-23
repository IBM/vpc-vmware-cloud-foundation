##############################################################
##############################################################
# Define outputs
##############################################################
##############################################################



##############################################################
# Output resources_prefix
##############################################################

output "resources_prefix" {
  value = local.resources_prefix
}


##############################################################
#  Output resource group id
##############################################################

output "resource_group_id" {
    value = data.ibm_resource_group.resource_group_vmw.id
}
   

##############################################################
#  Output zone VPC subnets
##############################################################

output "zone_subnets" {
  value = local.subnets
}


##############################################################
#  Output DNS root domain
##############################################################

output "dns_root_domain" {
  value = var.dns_root_domain
}


##############################################################
#  Output cluster hosts
##############################################################

output "cluster_host_map_out" {
  value = local.cluster_host_map
}


locals {
    cluster_host_map_out_json = jsonencode(local.cluster_host_map)
}

output "cluster_host_map_out_json" {
  value = local.cluster_host_map_out_json
}

##############################################################
#  Output vcenter
##############################################################

output "vcenter" {
  value = local.vcenter
}


##############################################################
#  Output NSX-T
##############################################################


output "zone_nsx_t_mgr" {
  value = local.nsx_t_mgr
}

#/*
output "zone_host_tep_list" {
  value = [ibm_is_bare_metal_server_network_interface_allow_float.zone_host_teps[*].primary_ip[0].address]
}

output "zone_host_teps" {
  value = local.zone_host_teps
}
#*/

##############################################################
#  Output NSX-T edge and T0
##############################################################

output "zone_nsx_t_edge" {
  value = local.nsx_t_edge
}

output "zone_subnets_nsxt_uplinks" {
  value = local.nsxt_uplink_subnets
}

output "nsx_t_t0" {
  value = local.nsx_t_t0
}



