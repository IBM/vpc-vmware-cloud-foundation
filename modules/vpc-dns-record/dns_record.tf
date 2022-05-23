

##############################################################
# Create private DNS records for IP
##############################################################


#/*. 

resource "ibm_dns_resource_record" "a_record" {
     instance_id = var.vmw_dns_instance_guid
     zone_id     = var.vmw_dns_zone_id
     type        = var.vmw_dns_type
     name        = var.vmw_dns_type == "PTR" ? var.vmw_ip_address : var.vmw_dns_name
     rdata       = var.vmw_dns_type == "PTR" ? "${var.vmw_dns_name}.${var.vmw_dns_root_domain}" : var.vmw_ip_address
 }

#*/

