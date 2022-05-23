

##############################################################
# Create Resource Group
##############################################################

/* hack
resource "ibm_resource_group" "resource_group_vmw" {
  name     = "${local.resources_prefix}-rg"
}


data "ibm_resource_group" "resource_group_vmw" {
  name     = "${local.resources_prefix}-rg"
  depends_on = [
    ibm_resource_group.resource_group_vmw
  ]
}
*/
  
data "ibm_resource_group" "resource_group_vmw" {
  name     = "default"
}
