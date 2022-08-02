##############################################################
# Terraform declaration
##############################################################


terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.44.0"
    }
  }
}


/*
terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source  = "localdomain/provider/ibm" // ~/.terraform.d/plugins/localdomain/provider/ibm/1.39.2/darwin_amd64
      version = "1.41.4"
    }
  }
}
*/


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


