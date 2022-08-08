##############################################################
# Create maps for DNS records to create
##############################################################

# Note to disable deployment for VPC DNS, 
# set var.deploy_dns to false

# Note the local cluster_host_map must be flattened 
# and converted to a new map create DNS records. 





locals {
  zone_clusters_dns_records = {
    for cluster_k, cluster_v in var.zone_clusters : cluster_v.name => [
      concat(
        [for k, v in local.zone_clusters_vcenters_values : { name = v.hostname, ip_address = v.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_managers_values : { name = v.nsx_t_0.hostname, ip_address = v.nsx_t_0.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_managers_values : { name = v.nsx_t_1.hostname, ip_address = v.nsx_t_1.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_managers_values : { name = v.nsx_t_2.hostname, ip_address = v.nsx_t_2.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_managers_values : { name = v.nsx_t_vip.hostname, ip_address = v.nsx_t_vip.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_edges_values : { name = v.edge_0.hostname, ip_address = v.edge_0.mgmt.ip_address} if k == cluster_v.name],
        [for k, v in local.zone_clusters_nsx_t_edges_values : { name = v.edge_1.hostname, ip_address = v.edge_1.mgmt.ip_address} if k == cluster_v.name],
      )
    ] 
  }
}



locals {
  dns_records_mgmt = {
    hosts = flatten ([
    for cluster in local.zone_clusters_hosts_values.clusters: [ 
      for hosts in cluster.hosts : {
        name = hosts.hostname
        ip_address = hosts.mgmt.ip_address
        }
      ]
    ]),
    vcf = [
      { name = local.vcf.cloud_builder.hostname, ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address : "0.0.0.0"},
      { name = local.vcf.sddc_manager.hostname, ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address : "0.0.0.0"},    
    ],
    other = var.dns_records
  }  
}

locals {
  dns_records = merge(local.dns_records_mgmt, local.zone_clusters_dns_records)
}

locals {
  dns_records_list = flatten([for k, v in local.dns_records : v])
  dns_records_map = {
    for v in local.dns_records_list : v.name => {ip_address=v.ip_address, name=v.name} 
  }
}


##############################################################
#  Create DNS records for management appliances 
##############################################################


module "zone_dns_a_records" {
  source = "./modules/vpc-dns-record"
  for_each = var.deploy_dns ? local.dns_records_map : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "A"
  vmw_dns_name = each.value.name
  vmw_ip_address = each.value.ip_address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
  ]
}

module "zone_dns_ptrs" {
  source = "./modules/vpc-dns-record"
  for_each = var.deploy_dns ? local.dns_records_map : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "PTR"
  vmw_dns_name = each.value.name
  vmw_ip_address = each.value.ip_address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_a_records,
  ]
}


