
variable "template_git_url" {
  default = "https://github.com/IBM/vpc-vmware-iaas"
  #default = "https://github.com/IBM/vpc-vmware-cloud-foundation"
}



variable "schematics_workspace_location" {
  default = "us-south"
  description = "Enter the schematics workspace location."
}


variable "schematics_workspace_rg" {
  #default = "Default"
  description = "Enter a resource group name for the schematics workspace."

}


variable "schematics_workspace_template_type" {
  default = "terraform_v1.1"
}
