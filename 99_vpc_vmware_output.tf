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
  description = "Random resource prefix used for the VPC asset names."
}


##############################################################
#  Output resource group id
##############################################################

output "resource_group_id" {
  value = data.ibm_resource_group.resource_group_vmw.id
  description = "Resource group ID used for deployed assets."

}
   

##############################################################
#  Output zone VPC subnets
##############################################################

output "zone_subnets" {
  value = local.subnets
  description = "Created VPC subnets."
}


##############################################################
#  Output DNS root domain
##############################################################

output "dns_root_domain" {
  value = var.dns_root_domain
  description = "Used DNS root domain."

}


output "dns_servers" {
  value = var.dns_servers
  description = "Used DNS server IP addresses."
}


##############################################################
#  Output NTP server
##############################################################


output "ntp_server" {
  value = var.ntp_server
  description = "Used NTP server IP addresses."
}






##############################################################
#  Output cluster hosts
##############################################################

output "cluster_hosts" {
  value = local.cluster_host_map
  description = "Deployed VPC bare metal servers per cluster including created VLAN network interface information for VMkernel adapters."
}


/*

locals {
    cluster_host_map_out_json = jsonencode(local.cluster_host_map)
}


output "cluster_host_map_out_json" {
  value = local.cluster_host_map_out_json
}

*/

##############################################################
#  Output vcenter
##############################################################

output "vcenter" {
  value = local.vcenter
  description = "Deployed DNS and VLAN network interface information for vCenter Server virtual appliance(es)."
}


##############################################################
#  Output NSX-T
##############################################################


output "zone_nsx_t_mgr" {
  value = local.nsx_t_mgr
  description = "Deployed DNS and VLAN network interface information for NSX-T Manager virtual appliance(es)."
}



##############################################################
#  Output NSX-T edge and T0
##############################################################

output "zone_nsx_t_edge" {
  value = local.nsx_t_edge
  description = "Deployed DNS and VLAN network interface information for NSX-T Edge virtual appliance(es)."
}

output "zone_subnets_edge" {
  value = local.nsxt_edge_subnets
}

output "nsx_t_t0" {
  value = local.nsx_t_t0
  description = "Deployed VLAN network interface information for NSX-T Tier-0 gateway uplinks."
}

output "t0_public_ips" {
  value = ibm_is_floating_ip.floating_ip[*].address
  description = "Deployed public IPs for NSX-T Tier-0 gateway public uplink."
}


##############################################################
# Output VCF 
##############################################################



output "vcf" {
  value = var.enable_vcf_mode ? local.vcf : {}
  description = "Deployed DNS and network interface information for VCF virtual appliance(es)."
}

output "vcf_network_pools" {
  value = var.enable_vcf_mode ? local.vcf_pools : {}
  description = "Lists of deployed IP addresses for VCF network pools."
}

output "vcf_vlan_nics" {
  value = var.enable_vcf_mode ? local.vcf_vlan_nics : {}
  description = "Lists of deployed VLAN network interfaces for VCF network pools."
}


##############################################################
# Output bringup json
##############################################################


output "vcf_bringup_json" {
  value = var.enable_vcf_mode ? data.template_file.vcf_bringup_json[0].rendered : ""
  sensitive = true
} 



##############################################################
# Output Windows server
##############################################################


output "vpc_bastion_hosts" {
  value = var.deploy_bastion ? local.bastion_hosts : []
  sensitive = true
  description = "Access information for deployed bastion hosts."
}




##############################################################
# Output VPC routes
##############################################################


output "routes_default_egress_per_zone" {
  value = local.vpc_egress_routes_per_zone
  description = "Deployed VPC egress route table (readonly data) per zone."

}


output "routes_tgw_dl_ingress_egress_per_zone" {
  value = local.vpc_tgw_dl_ingress_routes_per_zone
  description = "Deployed VPC ingress route table (readonly data) per zone."
}




##############################################################
# Testing
##############################################################


output "cos_bucket_test_key" {
  value = var.cos_bucket_test_key
}

