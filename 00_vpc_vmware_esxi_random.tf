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
