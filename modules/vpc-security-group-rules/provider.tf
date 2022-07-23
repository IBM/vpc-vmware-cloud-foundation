
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


