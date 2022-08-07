
##############################################################
# Deployed specially for VCF deployments
##############################################################


##############################################################
# Create random password for cloud_builder and sddc_manager
##############################################################

# Note use random_password instead...this is for testing only.

# Password for the root user of the appliance operating system
# Must contain only lower ASCII characters without spaces.
# Must be at least 8 characters, but no more than 20 characters in length
# Must contain at least one uppercase letter
# Must contain at least one lowercase letter
# Must contain at least one number
# Must contain at least one special character, 
# for example @!#$%?^


resource "random_string" "cloud_builder_password" {
  length           = 16
  special          = true
  numeric          = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "@!#$%?"
}


resource "random_string" "sddc_manager_password" {
  length           = 16
  special          = true
  numeric          = true
  min_special      = 1
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  override_special = "@!#$%?"
}






##############################################################
# Count number IPs required
##############################################################

locals {
  hosts_total = sum(flatten([
      for cluster_name in keys(var.zone_clusters): 
          var.zone_clusters[cluster_name].host_count
      ]))
  #edges_total = var.vcf_edge_pool_size # hardcoded to var.vcf_edge_pool_size nodes
}


/* todo...try with Terraform v1.2.0 and later...

resource "null_resource" "check_host_pool" {
  count = var.enable_vcf_mode ? 1 : 0
  lifecycle {
    postcondition {
      condition     = var.vcf_host_pool_size >= local.hosts_total
      error_message = "Network pool size (${var.vcf_edge_pool_size})is smaller than total number of hosts (${local.hosts_total})."
    }
  }
}

resource "null_resource" "check_edge_pool" {
  count = var.enable_vcf_mode ? 1 : 0
  lifecycle {
    postcondition {
      condition     = var.vcf_edge_pool_size >= local.edges_total
      error_message = "Network pool size (${var.vcf_edge_pool_size})is smaller than total number of edges (${local.edges_total})."
    }
  }
}

*/


##############################################################
# Create IP pool reservations for vcf
##############################################################

# Reserve IP addresses from subnets to be used 
# as IP pools when creating VLAN interfaces.

resource "ibm_is_subnet_reserved_ip" "zone_vcf_vmot_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0 # Note one IP per host needed in VCF
    subnet = local.subnets.vmot.subnet_id
    name   = "pool-vcf-vmot-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets.vmot.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet 

    depends_on = [
      module.vpc-subnets,
    ]
}

resource "ibm_is_subnet_reserved_ip" "zone_vcf_vsan_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0 # Note one IP per host needed in VCF
    subnet = local.subnets.vsan.subnet_id
    name   = "pool-vcf-vsan-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets.vsan.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet

    depends_on = [
      module.vpc-subnets,
    ]
}

resource "ibm_is_subnet_reserved_ip" "zone_vcf_tep_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size * 2 : 0 # Note two TEPs per host in VCF
    subnet = local.subnets.tep.subnet_id
    name   = "pool-vcf-tep-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets.tep.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet

    depends_on = [
      module.vpc-subnets,
    ]
}


/*
resource "ibm_is_subnet_reserved_ip" "zone_vcf_edge_tep_pool" {
    count = var.enable_vcf_mode ? var.vcf_edge_pool_size * 2 : 0 # Note two TEPs per edge nodes in VCF
    subnet = local.nsxt_edge_subnets.edge_tep.subnet_id
    name   = "pool-vcf-edge-tep-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.nsxt_edge_subnets.edge_tep.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet

    depends_on = [
      module.vpc-subnets,
    ]
}
*/

##############################################################
# Create VLAN NIC for Cloud Builder
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "cloud_builder" {
    count = var.enable_vcf_mode ? 1 : 0
    
    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
    
    subnet = local.subnets.mgmt.subnet_id
    vlan = var.mgmt_vlan_id
    
    name   = "vlan-nic-cloud-builder"
    security_groups = [ibm_is_security_group.sg["mgmt"].id]
    allow_ip_spoofing = false
    
    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"]
    ]
}


##############################################################
# Create VLAN NIC for SDDC Manager
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "sddc_manager" {
    count = var.enable_vcf_mode ? 1 : 0
    
    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]
    
    subnet = local.subnets.mgmt.subnet_id
    vlan = var.mgmt_vlan_id
    
    name   = "vlan-nic-sddc-manager"
    security_groups = [ibm_is_security_group.sg["mgmt"].id]
    allow_ip_spoofing = false
    
    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"]
    ]
}


##############################################################
# Create VLAN interface resources for host vmot (vcf)
##############################################################

# Note. VLAN nics provisioned to allow floating - can be used 
# in a VCF pool and configured in any host

# Note. VLAN nics with allow float can be provisioned on any host,
# and count.index is used to distribute is used here.  

resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_host_vmot" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0

    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]

    subnet = local.subnets.vmot.subnet_id
    vlan = var.vmot_vlan_id

    name   = "vlan-nic-vmot-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["vmot"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool[count.index].reserved_ip
    }

    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool
    ] 
}


##############################################################
# Create VLAN interface resources for host vsan (vcf)
##############################################################

# Note...VLAN nics provisioned to allow floating - can be used 
# in a VCF pool and configured in any host

resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_host_vsan" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0

    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]

    subnet = local.subnets.vsan.subnet_id
    vlan = var.vsan_vlan_id
    
    name   = "vlan-nic-vsan-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["vsan"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool[count.index].reserved_ip
    }

    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool
    ]  
}



##############################################################
# Create VLAN interface resources for host TEPs (vcf)
##############################################################

# Note...VLAN nics provisioned to allow floating - can be used 
# in a VCF pool and configured in any host

resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_host_teps" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size * 2 : 0  # Note two TEPs per host in VCF

    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]

    subnet = local.subnets.tep.subnet_id
    vlan = var.tep_vlan_id
    
    name   = "vlan-nic-tep-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["tep"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_tep_pool[count.index].reserved_ip
    } 

    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_subnet_reserved_ip.zone_vcf_tep_pool
    ] 
}



##############################################################
# Create VLAN interface resources for edge TEPs (vcf)
##############################################################

# Note...VLAN nics provisioned to allow floating - can be used 
# in a VCF pool and configured in any edge

/*

resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_edge_teps" {
    count = var.enable_vcf_mode ? var.vcf_edge_pool_size * 2 : 0  # Note two TEPs per edge nodes in VCF

    bare_metal_server = module.zone_bare_metal_esxi["cluster_0"].ibm_is_bare_metal_server_id[0]

    subnet = local.nsxt_edge_subnets.edge_tep.subnet_id
    vlan = var.edge_tep_vlan_id
    
    name   = "vlan-nic-edge-tep-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["tep"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_edge_tep_pool[count.index].reserved_ip 
    } 

    depends_on = [
      module.vpc-subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_subnet_reserved_ip.zone_vcf_edge_tep_pool
    ] 
}

*/




##############################################################
# Define VCF output maps
##############################################################

locals {
  vcf = {
    cloud_builder = {
      host_name = "cloud-builder"
      fqdn = "cloud-builder.${var.dns_root_domain}"
      ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.cloud_builder[0].primary_ip[0].address : "0.0.0.0"
      prefix_length = local.subnets.mgmt.prefix_length
      default_gateway = local.subnets.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets.mgmt.subnet_id
      username = "admin"
      password = var.vcf_password == "" ? random_string.cloud_builder_password.result : var.vcf_password
    },
    sddc_manager = {
      host_name = "sddc-manager"
      fqdn = "sddc-manager.${var.dns_root_domain}"
      ip_address = var.enable_vcf_mode ? ibm_is_bare_metal_server_network_interface_allow_float.sddc_manager[0].primary_ip[0].address : "0.0.0.0"
      prefix_length = local.subnets.mgmt.prefix_length
      default_gateway = local.subnets.mgmt.default_gateway
      vlan_id = var.mgmt_vlan_id
      vpc_subnet_id = local.subnets.mgmt.subnet_id
      username = "admin"
      password = var.vcf_password == "" ? random_string.sddc_manager_password.result : var.vcf_password
    },
  }
}

locals {
  vcf_pools = {
    vmot     = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool[*].address : []
    vsan     = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool[*].address : []
    tep      = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_tep_pool[*].address : []
    #edge_tep = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_edge_tep_pool[*].address : []
  }
}


locals {
  vcf_vlan_nics = {
    vmot     = var.enable_vcf_mode ? [for vnic in ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_host_vmot : {
        ip_address = vnic.primary_ip[0].address
        reserved_ip = vnic.primary_ip[0].reserved_ip
        vlan_nic_id = vnic.id
        vlan_nic_name = vnic.name
      }] : []
    vsan     = var.enable_vcf_mode ? [for vnic in ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_host_vsan : {
        ip_address = vnic.primary_ip[0].address
        reserved_ip = vnic.primary_ip[0].reserved_ip
        vlan_nic_id = vnic.id
        vlan_nic_name = vnic.name
      }] : []
    tep      = var.enable_vcf_mode ? [for vnic in ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_host_teps : {
        ip_address = vnic.primary_ip[0].address
        reserved_ip = vnic.primary_ip[0].reserved_ip
        vlan_nic_id = vnic.id
        vlan_nic_name = vnic.name
      }] : []
    #edge_tep = var.enable_vcf_mode ? [for vnic in ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_edge_teps : {
    #    ip_address = vnic.primary_ip[0].address
    #    reserved_ip = vnic.primary_ip[0].reserved_ip
    #    vlan_nic_id = vnic.id
    #    vlan_nic_name = vnic.name
    #  }] : []
  }
}




