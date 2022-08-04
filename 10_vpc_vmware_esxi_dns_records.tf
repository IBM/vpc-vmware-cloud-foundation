

##############################################################
# Create DNS records for host management IPs
##############################################################

# Note to disable deployment for VPC DNS, 
# set var.deploy_dns to false

# Note the local cluster_host_map must be flattened 
# and converted to a new map create DNS records. 

locals {
  dns_entry_list = flatten ([
    for cluster in local.cluster_host_map.clusters[*]: [ 
      for hosts in cluster.hosts[*] : {
        "hostname" = hosts.host
        "mgmt_ip_address" = hosts.mgmt.ip_address
        }
      ]
    ])
  dns_entry_map = {
    for host in local.dns_entry_list :
      "${host.hostname}" => {
        "mgmt_ip_address" = host.mgmt_ip_address 
      }
    }
}




module "zone_dns_records_for_hosts" {
  source = "./modules/vpc-dns-record"
  for_each = var.deploy_dns ? local.dns_entry_map : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "A"
  vmw_dns_name = each.key
  vmw_ip_address = each.value.mgmt_ip_address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_bare_metal_esxi,
  ]
}


module "zone_dns_ptrs_for_hosts" {
  source = "./modules/vpc-dns-record"
  for_each = var.deploy_dns ? local.dns_entry_map : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "PTR"
  vmw_dns_name = each.key
  vmw_ip_address = each.value.mgmt_ip_address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_records_for_hosts,
    module.zone_bare_metal_esxi
  ]
}



##############################################################
# Create DNS record for vCenter in Zone 1
##############################################################


module "zone_dns_record_for_vcenter" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 1 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_name = "vcenter"
  vmw_dns_type = "A"
  vmw_ip_address = module.zone_vcenter.vmw_vcenter_ip
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_vcenter
  ]
}

module "zone_dns_ptr_for_vcenter" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 1 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_name = "vcenter"
  vmw_dns_type = "PTR"
  vmw_ip_address = module.zone_vcenter.vmw_vcenter_ip
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_vcenter,
    module.zone_dns_record_for_vcenter
  ]
}


##############################################################
# Create DNS record for NSX-T in Zone 1
##############################################################



module "zone_dns_record_for_nsxt_mgr" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 3 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "A"
  vmw_dns_name = "nsx-t-${count.index}"
  vmw_ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[count.index].primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_nxt_t
  ]
}



module "zone_dns_ptr_for_nsxt_mgr" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 3 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "PTR"
  vmw_dns_name = "nsx-t-${count.index}"
  vmw_ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip[count.index].primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_record_for_nsxt_mgr,
    module.zone_nxt_t
  ]
}



module "zone_dns_record_for_nsxt_mgr_vip" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 1 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "A"
  vmw_dns_name = "nsx-t-vip"
  vmw_ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_nxt_t
  ]
}

module "zone_dns_ptr_for_nsxt_mgr_vip" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 1 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_type = "PTR"
  vmw_dns_name = "nsx-t-vip"
  vmw_ip_address = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_record_for_nsxt_mgr_vip,
    module.zone_nxt_t
  ]
}




##############################################################
# Create DNS record for NSX-T edges in Zone 1
##############################################################


module "zone_dns_record_for_nsxt_edge" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 2 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_name = "edge-${count.index}"
  vmw_dns_type = "A"
  vmw_ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[count.index].primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_nxt_t
  ]
}



module "zone_dns_ptr_for_nsxt_edge" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? 2 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid

  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id

  vmw_dns_root_domain = var.dns_root_domain
  vmw_dns_name = "edge-${count.index}"
  vmw_dns_type = "PTR"
  vmw_ip_address = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[count.index].primary_ip[0].address
  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_record_for_nsxt_edge,
    module.zone_nxt_t
  ]
}




##############################################################
# Create DNS records for VCF Cloud Builder
##############################################################


module "zone_dns_record_for_cloud_builder" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? var.enable_vcf_mode ? 1 : 0 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = "cloud-builder"
  vmw_dns_type = "A"
  vmw_ip_address = ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder
  ]
}

module "zone_dns_ptr_for_cloud_builder" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? var.enable_vcf_mode ? 1 : 0 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = "cloud-builder"
  vmw_dns_type = "PTR"
  vmw_ip_address = ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder,
    module.zone_dns_record_for_cloud_builder,
    module.zone_nxt_t
  ]
}


##############################################################
# Create DNS records for VCF SDDC Manager
##############################################################


module "zone_dns_record_for_sddc_manager" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? var.enable_vcf_mode ? 1 : 0 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = "sddc-manager"
  vmw_dns_type = "A"
  vmw_ip_address = ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager
  ]
}


module "zone_dns_ptr_for_sddc_manager" {
  source = "./modules/vpc-dns-record"
  count =  var.deploy_dns ? var.enable_vcf_mode ? 1 : 0 : 0

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = "sddc-manager"
  vmw_dns_type = "PTR"
  vmw_ip_address = ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager,
    module.zone_dns_record_for_sddc_manager,
    module.zone_nxt_t
  ]
}

##############################################################
# Create DNS records for AVN appliances
##############################################################


module "zone_dns_record_for_avn_appliances" {
  source = "./modules/vpc-dns-record"
  for_each =  var.deploy_dns ? var.dns_records : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = each.value.name
  vmw_dns_type = "A"
  vmw_ip_address = each.value.ip_address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
  ]
}

module "zone_dns_ptr_for_avn_appliances" {
  source = "./modules/vpc-dns-record"
  for_each =  var.deploy_dns ? var.dns_records : {}

  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance[0].guid
  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vmw_dns_root_domain = var.dns_root_domain

  vmw_dns_name = each.value.name
  vmw_dns_type = "PTR"
  vmw_ip_address = each.value.ip_address

  depends_on = [
    ibm_resource_instance.dns_services_instance,
    ibm_dns_zone.dns_services_zone,
    module.zone_dns_record_for_avn_appliances,
    module.zone_nxt_t
  ]
}



##############################################################
# Create a local list of manual DNS entries to create 
##############################################################

locals {
  dns_records = {
    hosts = flatten ([
      for cluster in local.cluster_host_map.clusters[*]: [ 
        for hosts in cluster.hosts[*] : {
          "name" = hosts.host
          "ip_address" = hosts.mgmt.ip_address
          }
        ]
      ]),
    mgmt = [  
      { name = "vcenter", "ip_address" = module.zone_vcenter.vmw_vcenter_ip },
      { name = "nsx-t-0", "ip_address" = module.zone_nxt_t.vmw_nsx_t_manager_ip[0].primary_ip[0].address },
      { name = "nsx-t-1", "ip_address" = module.zone_nxt_t.vmw_nsx_t_manager_ip[1].primary_ip[0].address },
      { name = "nsx-t-2", "ip_address" = module.zone_nxt_t.vmw_nsx_t_manager_ip[2].primary_ip[0].address },
      { name = "nsx-t-vip", "ip_address" = module.zone_nxt_t.vmw_nsx_t_manager_ip_vip.primary_ip[0].address },
      { name = "edge-0", "ip_address" = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[0].primary_ip[0].address },
      { name = "edge-1", "ip_address" = module.zone_nxt_t_edge.vmw_nsx_t_edge_mgmt_ip[1].primary_ip[0].address },
    ],
    vcf = [
      { name = "cloud-builder", "ip_address" = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address : "0.0.0.0"},
      { name = "sddc-manager", "ip_address" = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address : "0.0.0.0"},    
    ],
    other = [ 
      for record in var.dns_records : {
        "name=" = record.name
        "ip_address" = record.ip_address
      }
    ]
  }  
}
