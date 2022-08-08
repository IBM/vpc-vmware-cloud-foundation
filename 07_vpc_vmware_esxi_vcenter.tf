

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
  zone_clusters_vcenters_values = {
    for k, v in var.zone_clusters : v.name => {
      host_name = "${v.name}-vcenter"
      fqdn = "${v.name}-vcenter.${var.dns_root_domain}"
      ip_address = module.zone_vcenter[k].vmw_vcenter_ip
      prefix_length = local.subnets.mgmt.prefix_length
      default_gateway = local.subnets.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets.mgmt.subnet_id
      username = "administrator@vsphere.local"
      password = var.vcf_password == "" ? random_string.vcenter_password.result : var.vcf_password
    } if v.vcenter == true
  }
}


# >>> OLD

##############################################################
# Create VLAN interface resources for vCenter
##############################################################

# This will create VLAN nic for the first host of the first cluster "cluster_0". 
# Please do not change the key. vCenter must initially be provisioned to that host. 

/*

module "zone_vcenter" {
  source = "./modules/vpc-vcenter"
  vmw_resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  vmw_mgmt_subnet = local.subnets.mgmt.subnet_id
  vmw_vcenter_esx_host_id = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt = ibm_is_security_group.sg["mgmt"].id
  vmw_mgmt_vlan_id = var.mgmt_vlan_id

  vmw_vcenter_name = "vcenter"

  depends_on = [
    module.vpc-subnets,
    ibm_is_security_group.sg,
    module.zone_bare_metal_esxi["cluster_0"]
  ]
}

*/


##############################################################
# Define output maps for vCenter
##############################################################

/*

locals {
  vcenter = {
    fqdn = "vcenter.${var.dns_root_domain}"
    host_name = "vcenter"
    #ip_address = module.zone_vcenter.vmw_vcenter_ip
    ip_address = module.zone_vcenter["cluster_0"].vmw_vcenter_ip
    prefix_length = local.subnets.mgmt.prefix_length
    default_gateway = local.subnets.mgmt.default_gateway
    vlan_id = var.mgmt_vlan_id
    vpc_subnet_id = local.subnets.mgmt.subnet_id
    username = "administrator@vsphere.local"
    password = var.vcf_password == "" ? random_string.vcenter_password.result : var.vcf_password
  }
}

*/



