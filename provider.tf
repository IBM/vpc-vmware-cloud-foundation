##############################################################
# Terraform declaration
##############################################################


terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.43.0"
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

# Default Provider block parameters
  region = var.ibmcloud_vpc_region
}

