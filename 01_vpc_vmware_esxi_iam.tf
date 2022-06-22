
##############################################################
# Create an IAM Access Group
# Which will contain the IAM Access Policies (which contain an Access an Access Role for the service access and platform access)
##############################################################

resource "ibm_iam_access_group" "vmware_provision_access_group" {
  count       = var.deploy_iam ? 1 : 0 
  name        = "${local.resources_prefix}-vmware-ryo-access-group"
  description = "Personnel who can provision resources into the Resource Group"
}


##############################################################
# IAM Access Policy assigned to IAM Access Group
# For specific Resource Group
# Provides Platform access with Role as Operator
# Provides Service access with Role as Writer
##############################################################

resource "ibm_iam_access_group_policy" "vmware_platform_and_service_access_policy" {
  count           = var.deploy_iam ? 1 : 0
  access_group_id = ibm_iam_access_group.vmware_provision_access_group[count.index].id
  roles           = ["Operator", "Writer"]

  resources {
    resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  }
}

##############################################################
# IAM Access Policy assigned to IAM Access Group
# For specific Resource Group
# Provides Resource Group access with Role as Viewer
##############################################################

resource "ibm_iam_access_group_policy" "vmware_resource_group_access_policy" {
  count           = var.deploy_iam ? 1 : 0
  access_group_id = ibm_iam_access_group.vmware_provision_access_group[count.index].id
  roles           = ["Viewer"]

  resources {
    resource = data.ibm_resource_group.resource_group_vmw.id
    resource_type = "resource-group"
    resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  }

}

