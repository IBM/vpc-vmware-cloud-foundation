##############################################################
# Create DNS Services instance
# DNS Services creates a DNS Zone which routes private network traffic for a defined Domain Name/s to any selected VPC Zones (in any Region, up to 10 VPCs)
#
# DNS Services is private only and hidden / not accessible from machines outside of IBM Cloud. For provisioning and configuring DNS Resource Records for public DNS resolution, refer to IBM Cloud Internet Services (CIS)
#
# When the DNS Services resolver receives a request, it checks whether the request is for a hostname defined within a private zone for the network where the request originated.
# If so, the hostname is resolved privately. Otherwise, the request is forwarded to a public resolver and the response returned to the requester.
# This allows for a hostname such as www.example.com to resolve differently on the internet versus on IBM Cloud.
#
# Adding the same VPC to two DNS zones of the same name is not allowed.
##############################################################

# https://github.com/IBM-Cloud/terraform-provider-ibm/blob/master/examples/ibm-private-dns/main.tf
resource "ibm_resource_instance" "dns_services_instance" {
  count =  var.deploy_dns ? 1 : 0

  name              = "${local.resources_prefix}-dns-services-for-vpc"
  service           = "dns-svcs"
  plan              = "standard-dns"

  resource_group_id = data.ibm_resource_group.resource_group_vmw.id
  location          = "global"

  #User can increase timeouts
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

##############################################################
# DNS Services - Create a DNS Zone to hold Domain Names
# The DNS Zone Name must be a fully qualified domain name (FQDN) and becomes the "root domain"
# During creation of a DNS Zone Name, only 2-level zones are supported (e.g. example.com)
# After DNS Zone Name is created, subdomains within the zone can be established (e.g. subdomain.example.com)
##############################################################

# Note to disable deployment for VPC DNS, 
# set var.deploy_dns to false



# https://github.com/IBM-Cloud/terraform-provider-ibm/blob/master/examples/ibm-private-dns/main.tf
resource "ibm_dns_zone" "dns_services_zone" {
  count =  var.deploy_dns ? 1 : 0

  depends_on = [ibm_resource_instance.dns_services_instance]
  name        = var.dns_root_domain
  instance_id = ibm_resource_instance.dns_services_instance[0].guid
  description = "VMware Cloud Private DNS Zone"
  label       = "dns_zone"
}

##############################################################
# DNS Services - Add Permitted Network, attach the DNS Zone to a VPC
# Used as an access control mechanism to guarantee that only the VPC that has been added as a permitted network can perform name resolution on the DNS zone
##############################################################

resource "ibm_dns_permitted_network" "dns_services_permitted_network" {
  count =  var.deploy_dns ? 1 : 0

  instance_id = ibm_resource_instance.dns_services_instance[0].guid
  zone_id = ibm_dns_zone.dns_services_zone[0].zone_id
  vpc_crn = module.vpc-subnets[var.vpc_name].vmware_vpc.resource_crn
  type = "vpc"
  depends_on = [
    ibm_dns_zone.dns_services_zone,
    module.vpc-subnets
  ]
}

