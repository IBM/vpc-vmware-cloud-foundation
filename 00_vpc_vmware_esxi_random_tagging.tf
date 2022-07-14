##############################################################
# Create Random Recource Prefix
##############################################################

# This random prefix will be added to given resource prefix to 
# make sure names are unique.

resource "random_string" "resource_code" {
  length  = 3
  special = false
  upper   = false
#  number = false
}

locals {
  resources_prefix = "${var.resource_prefix}-${random_string.resource_code.result}"
}


##############################################################
# Recource tagging
##############################################################


locals {
  resource_tags = {
    ssh_key             = concat(["vmware:${local.resources_prefix}"], var.tags)
    vpc                 = concat(["vmware:${local.resources_prefix}"], var.tags)
    subnets             = concat(["vmware:${local.resources_prefix}"], var.tags)
    public_gateway      = concat(["vmware:${local.resources_prefix}"], var.tags)
    security_group      = concat(["vmware:${local.resources_prefix}"], var.tags)
    bms_esx             = concat(["vmware:${local.resources_prefix}"], var.tags, ["esx"])
    vsi_bastion         = concat(["vmware:${local.resources_prefix}"], var.tags, ["bastion"])
    dns_services        = concat(["vmware:${local.resources_prefix}"], var.tags)
    floating_ip_t0      = concat(["vmware:${local.resources_prefix}"], var.tags, ["tier0-gateway"])
    floating_ip_bastion = concat(["vmware:${local.resources_prefix}"], var.tags, ["bastion"])
  }
}