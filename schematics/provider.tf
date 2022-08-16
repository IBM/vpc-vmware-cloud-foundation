##############################################################
# Terraform declaration
##############################################################


terraform {
  #required_version = ">= 0.15"
  required_version = ">= 1.00"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.44.0"
    }
  }
}


##############################################################
# Terraform Provider declaration
##############################################################

provider "ibm" {

# Define Provider inputs manually
#  ibmcloud_api_key = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Define Provider inputs from given Terraform Variables
  ibmcloud_api_key = var.ibmcloud_api_key

  region = var.schematics_workspace_location
# Default Provider block parameters
}

