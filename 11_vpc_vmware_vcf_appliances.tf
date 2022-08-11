
##############################################################
# Deployed specially for VCF deployments
##############################################################


##############################################################
# Create random password for cloud_builder and sddc_manager
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


resource "random_string" "cloud_builder_password" {
  length           = 16
  special          = true
  numeric          = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "@!#$%?"
}


resource "random_string" "sddc_manager_password" {
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
# Create VLAN NIC for Cloud Builder
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "cloud_builder" {
    count = var.enable_vcf_mode ? 1 : 0
    
    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
    
    subnet = local.subnets_map.infrastructure.mgmt.subnet_id
    vlan = var.mgmt_vlan_id
    
    name   = "vlan-nic-cloud-builder"
    security_groups = [ibm_is_security_group.sg["mgmt"].id]
    allow_ip_spoofing = false
    
    depends_on = [
      module.vpc_subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"]
    ]
}


##############################################################
# Create VLAN NIC for SDDC Manager
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "sddc_manager" {
    count = var.enable_vcf_mode ? 1 : 0
    
    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
    
    subnet = local.subnets_map.infrastructure.mgmt.subnet_id
    vlan = var.mgmt_vlan_id
    
    name   = "vlan-nic-sddc-manager"
    security_groups = [ibm_is_security_group.sg["mgmt"].id]
    allow_ip_spoofing = false
    
    depends_on = [
      module.vpc_subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"]
    ]
}



##############################################################
# Define VCF output maps
##############################################################

locals {
  vcf = {
    cloud_builder = {
      hostname = "cloud-builder"
      fqdn = "cloud-builder.${var.dns_root_domain}"
      ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address : "0.0.0.0"
      prefix_length = local.subnets_map.infrastructure.mgmt.prefix_length
      default_gateway = local.subnets_map.infrastructure.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets_map.infrastructure.mgmt.subnet_id
      username = "admin"
      password = var.vcf_password == "" ? random_string.cloud_builder_password.result : var.vcf_password
    },
    sddc_manager = {
      hostname = "sddc-manager"
      fqdn = "sddc-manager.${var.dns_root_domain}"
      ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address : "0.0.0.0"
      prefix_length = local.subnets_map.infrastructure.mgmt.prefix_length
      default_gateway = local.subnets_map.infrastructure.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets_map.infrastructure.mgmt.subnet_id
      username = "admin"
      password = var.vcf_password == "" ? random_string.sddc_manager_password.result : var.vcf_password
    },
  }
}





