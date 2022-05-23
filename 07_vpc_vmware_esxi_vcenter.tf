##############################################################
# Create VLAN interface resources for vCenter
##############################################################

# This will create VLAN nic for the first host of the first cluster "cluster_0". 
# Please do not change the key. vCenter must initially be provisioned to that host. 

module "zone_vcenter" {
  source = "./modules/vpc-vcenter"
  vmw_resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  vmw_inst_mgmt_subnet = local.subnets.inst_mgmt.subnet_id
  vmw_vcenter_esx_host_id = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
  vmw_sg_mgmt = ibm_is_security_group.sg["mgmt"].id
#  vmw_dns_instance_guid = ibm_resource_instance.dns_services_instance.guid
#  vmw_dns_zone_id = ibm_dns_zone.dns_services_zone.zone_id
  depends_on = [
    module.vpc-subnets,
    ibm_is_security_group.sg,
    module.zone_bare_metal_esxi["cluster_0"]
  ]
}

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
# Must contain at least one special character, for
# example, a dollar sign ($), hash key (#), at sign (@), period (.), or exclamation mark (!)


resource "random_string" "vcenter_password" {
  length           = 16
  special          = true
  number           = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "$#@.!"
}


##############################################################
# Define output maps and output
##############################################################

locals {
  vcenter = {
    fqdn = "vcenter.${var.dns_root_domain}"
    ip_address = module.zone_vcenter.vmw_vcenter_ip
    prefix_length = local.subnets.inst_mgmt.prefix_length
    default_gateway = local.subnets.inst_mgmt.default_gateway
    vlan_id = "100"
    vpc_subnet_id = local.subnets.inst_mgmt.subnet_id
    username = "administrator@${var.dns_root_domain}"
    password = random_string.vcenter_password.result
  }
}

