
##############################################################
# Deployed specially for VCF deployments
##############################################################


##############################################################
# Count number IPs required
##############################################################

locals {
  hosts_total = sum(flatten([
      for cluster_name in keys(var.zone_clusters): 
          var.zone_clusters[cluster_name].host_count
      ]))
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

*/


##############################################################
# Create IP pool reservations for vcf
##############################################################

# Reserve IP addresses from subnets to be used 
# as IP pools when creating VLAN interfaces.

resource "ibm_is_subnet_reserved_ip" "zone_vcf_vmot_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0 # Note one IP per host needed in VCF
    subnet = local.subnets_map.infrastructure.vmot.subnet_id
    name   = "pool-vcf-vmot-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets_map.infrastructure.vmot.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet 

    depends_on = [
      module.vpc_subnets,
    ]
}

resource "ibm_is_subnet_reserved_ip" "zone_vcf_vsan_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size : 0 # Note one IP per host needed in VCF
    subnet = local.subnets_map.infrastructure.vsan.subnet_id
    name   = "pool-vcf-vsan-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets_map.infrastructure.vsan.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet

    depends_on = [
      module.vpc_subnets,
    ]
}

resource "ibm_is_subnet_reserved_ip" "zone_vcf_tep_pool" {
    count = var.enable_vcf_mode ? var.vcf_host_pool_size * 2 : 0 # Note two TEPs per host in VCF
    subnet = local.subnets_map.infrastructure.tep.subnet_id
    name   = "pool-vcf-tep-${format("%03s", count.index)}"
    auto_delete = false

    address = cidrhost(local.subnets_map.infrastructure.tep.cidr, count.index + 4) # Reserve IP addresses from 4th onwards on a subnet

    depends_on = [
      module.vpc_subnets,
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

    subnet = local.subnets_map.infrastructure.vmot.subnet_id
    vlan = var.vmot_vlan_id

    name   = "vlan-nic-vmot-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["vmot"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool[count.index].reserved_ip
    }

    depends_on = [
      module.vpc_subnets,
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

    subnet = local.subnets_map.infrastructure.vsan.subnet_id
    vlan = var.vsan_vlan_id
    
    name   = "vlan-nic-vsan-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["vsan"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool[count.index].reserved_ip
    }

    depends_on = [
      module.vpc_subnets,
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

    subnet = local.subnets_map.infrastructure.tep.subnet_id
    vlan = var.tep_vlan_id
    
    name   = "vlan-nic-tep-pool-${format("%03s", count.index)}"
    security_groups = [ibm_is_security_group.sg["tep"].id]
    allow_ip_spoofing = false

    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.zone_vcf_tep_pool[count.index].reserved_ip
    } 

    depends_on = [
      module.vpc_subnets,
      ibm_is_security_group.sg,
      module.zone_bare_metal_esxi["cluster_0"],
      ibm_is_subnet_reserved_ip.zone_vcf_tep_pool
    ] 
}



##############################################################
# Define VCF output maps
##############################################################



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
  }
}



locals {
  vcf_pool_ip_lists = {
    vmot     = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool[*].address : []
    vsan     = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool[*].address : []
    tep      = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_tep_pool[*].address : []
  }
}


locals {
  vcf_pools = {
    vmot     = {
      ip_list = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vmot_pool[*].address : []
      start_ip = var.enable_vcf_mode ? local.vcf_pool_ip_lists.vmot[0] : ""
      end_ip = var.enable_vcf_mode ?  local.vcf_pool_ip_lists.vmot[length(local.vcf_pool_ip_lists.vmot)-1] : ""
      cidr = local.subnets_map.infrastructure.vmot.cidr
      prefix_length = local.subnets_map.infrastructure.vmot.prefix_length
      default_gateway = local.subnets_map.infrastructure.vmot.default_gateway
    }
    vsan     = {
      ip_list = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_vsan_pool[*].address : []
      start_ip = var.enable_vcf_mode ? local.vcf_pool_ip_lists.vsan[0] : ""
      end_ip = var.enable_vcf_mode ?  local.vcf_pool_ip_lists.vsan[length(local.vcf_pool_ip_lists.vsan)-1] : ""
      cidr = local.subnets_map.infrastructure.vsan.cidr
      prefix_length = local.subnets_map.infrastructure.vsan.prefix_length
      default_gateway = local.subnets_map.infrastructure.vsan.default_gateway
    }
    tep      = {
      ip_list = var.enable_vcf_mode ? ibm_is_subnet_reserved_ip.zone_vcf_tep_pool[*].address : []
      start_ip = var.enable_vcf_mode ? local.vcf_pool_ip_lists.tep[0] : ""
      end_ip = var.enable_vcf_mode ?  local.vcf_pool_ip_lists.tep[length(local.vcf_pool_ip_lists.tep)-1] : ""
      cidr = local.subnets_map.infrastructure.tep.cidr
      prefix_length = local.subnets_map.infrastructure.tep.prefix_length
      default_gateway = local.subnets_map.infrastructure.tep.default_gateway
    }
  }
}






