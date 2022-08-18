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
#  Output VPC
##############################################################

output "vpc_summary" {
  value = local.vpc
}

##############################################################
#  Output zone VPC subnets
##############################################################

output "zone_subnets" {
  value = local.subnets_map
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
#  Output DNS records
##############################################################


output "dns_records" {
  value = local.dns_records
  description = "List of DNS recerds to be created if you have selected not to deploy IBM Cloud DNS service."
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
  value = local.zone_clusters_hosts_values
  description = "Deployed VPC bare metal servers per cluster including created VLAN network interface information for VMkernel adapters."
}


##############################################################
#  Output vcenter
##############################################################

output "vcenters" {
  value = local.zone_clusters_vcenters_values
}


##############################################################
#  Output NSX-T managers
##############################################################


output "nsx_t_managers" {
  value = local.zone_clusters_nsx_t_managers_values
  description = "Deployed DNS and VLAN network interface information for NSX-T Manager virtual appliance(es)."
}


##############################################################
#  Output NSX-T edge and T0
##############################################################


output "nsx_t_edges" {
  value = local.zone_clusters_nsx_t_edges_values
  description = "Deployed DNS and VLAN network interface information for NSX-T Edge virtual appliance(es)."
}


output "nsx_t_t0s" {
  value = local.zone_clusters_nsx_t_t0_values
  description = "Deployed VLAN network interface information for NSX-T Tier-0 gateway uplinks."
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

/*

output "vcf_bringup_json" {
  value = var.enable_vcf_mode ? data.template_file.vcf_bringup_json[0].rendered : ""
  #sensitive = true
  description = "VCF bringup json file."
} 

#*/

# Note to allow printout though IBM Cloud Schematics.



##############################################################
# Output Windows server
##############################################################


output "vpc_bastion_hosts" {
  value = local.deploy_bastion ? local.bastion_hosts : {}
  sensitive = false
  description = "Access information for deployed bastion hosts."
}

# Note to allow printout though IBM Cloud Schematics.



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
# Output NSX-T T0 routes
##############################################################



output "routes_for_t0s_per_cluster_domain" {
  value = local.nsx_t_t0_routes_to_be_created_per_cluster_domain
  description = "Static routes to be created in T0s."
}



##############################################################
# Output private SSH keys for host and bastion
##############################################################


output "ssh_private_key_host" {
  value = nonsensitive(tls_private_key.host_ssh.private_key_openssh)
  #sensitive = true
}

# Note to allow printout though IBM Cloud Schematics.


output "ssh_private_key_bastion" {
  value = nonsensitive(tls_private_key.bastion_rsa.private_key_openssh)
  #sensitive = true
}

# Note to allow printout though IBM Cloud Schematics.


##############################################################
# Testing
##############################################################


output "cos_bucket_test_key" {
  value = var.cos_bucket_test_key
  sensitive = true
}





