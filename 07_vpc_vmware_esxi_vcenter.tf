

##############################################################
# Create vCenter random password
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


resource "random_string" "vcenter_password" {
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
# Create VLAN interfaces for vCenters
##############################################################

# This will create VLAN nic for the first host of the VI workload
# cluster, if the cluster map as vcenter = true.  

locals {
  zone_clusters_vcenters = {
    for k, v in var.zone_clusters : k => v if v.vcenter == true
  }
}


module "zone_vcenter" {
  source                      = "./modules/vpc-vcenter"
  for_each                    = local.zone_clusters_vcenters

  vmw_resource_group_id       = data.ibm_resource_group.resource_group_vmw.id
  vmw_mgmt_subnet             = each.value.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].subnet_id : local.subnets_map.infrastructure["wl-mgmt"].subnet_id
  #vmw_vcenter_esx_host_id     = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[var.zone_clusters["cluster_0"].host_list[0]]  # Note deploy vcenters on mgmt cluster.
  vmw_vcenter_esx_host_id     = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[var.zone_clusters["cluster_0"].host_list[0]]  # Note deploy vcenters on mgmt cluster.
  vmw_sg_mgmt                 = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id            = each.value.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id

  vmw_vcenter_name            = "${each.value.name}-vcenter"

  depends_on = [
    module.vpc_subnets,
    ibm_is_security_group.sg,
    module.zone_bare_metal_esxi
  ]
}

##############################################################
# Define output maps for VI Workload vCenters
##############################################################

locals {
  zone_clusters_vcenters_values = {
    for k, v in var.zone_clusters : v.name => {
      hostname = "${v.name}-vcenter"
      fqdn = "${v.name}-vcenter.${var.dns_root_domain}"
      ip_address = module.zone_vcenter[k].vmw_vcenter_ip
      prefix_length = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].prefix_length : local.subnets_map.infrastructure["wl-mgmt"].prefix_length
      default_gateway = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].default_gateway : local.subnets_map.infrastructure["wl-mgmt"].default_gateway
      vlan_id = v.domain == "mgmt" ? var.mgmt_vlan_id : var.wl_mgmt_vlan_id
      vpc_subnet_id = v.domain == "mgmt" ? local.subnets_map.infrastructure["mgmt"].subnet_id : local.subnets_map.infrastructure["wl-mgmt"].subnet_id
      username = "administrator@vsphere.local"
      password = var.vcf_password == "" ? random_string.vcenter_password.result : var.vcf_password
    } if v.vcenter == true
  }
}

