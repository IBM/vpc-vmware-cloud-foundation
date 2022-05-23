
##############################################################
# Create Resource Group
##############################################################

resource "ibm_resource_group" "resource_group_vmw" {
  count =  var.resource_group_name == "" ? 1 : 0
  name     = "${local.resources_prefix}-rg"
}


data "ibm_resource_group" "resource_group_vmw" {
  name     = var.resource_group_name == "" ? "${local.resources_prefix}-rg" : var.resource_group_name
  depends_on = [
    ibm_resource_group.resource_group_vmw
  ]
}


variable "resource_group_name" {
  description = "Name of the resource group to deploy the assets. If left empty, then resource group will be created for you."
}


