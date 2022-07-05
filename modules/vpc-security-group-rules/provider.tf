
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


/*
terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source  = "localdomain/provider/ibm" // ~/.terraform.d/plugins/localdomain/provider/ibm/1.39.2/darwin_amd64
      version = "1.39.2"
      #source = "IBM-Cloud/ibm"
      #version = "1.40.0"      
    }
  }
}
*/

