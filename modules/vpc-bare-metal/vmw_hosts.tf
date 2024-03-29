
##############################################################
# Create reserved subnet IP for VCF vmk1
##############################################################




# Reserve an IP from instance mgmt subnet and use that in the userdata/cloud-init to re-configure vmk1 for vcf

resource "ibm_is_subnet_reserved_ip" "esx_host_vcf_mgmt" {
    for_each = var.vmw_enable_vcf_mode ? toset(var.vmw_host_list) : toset([])

    subnet = var.vmw_mgmt_subnet
    name   = "vlan-nic-vcf-${var.vmw_cluster_prefix}-${format(each.key)}-vmk1"
    auto_delete = false
}

/* to be deleted
output "esx_host_vcf_mgmt_reserved_ips_list" {
  value = [for k in var.vmw_host_list : ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[k].address]
}
*/

##############################################################
# Create Bare Metal Server userdata
##############################################################


locals {
  # Hostname
  hostname = "${var.vmw_resources_prefix}-${var.vmw_cluster_prefix}-esx"
}


data "ibm_is_subnet" "vmw_mgmt_subnet" {
  identifier = var.vmw_mgmt_subnet
}

data "ibm_is_subnet" "vmw_host_subnet" {
  identifier = var.vmw_host_subnet
}


# Inject values into cloud-init userdata shell template and parse file

data "template_file" "userdata" {
  for_each = toset(var.vmw_host_list)

  template = var.vmw_enable_vcf_mode ? "${file("${path.module}/esx_vcf_init.sh.tpl")}" : "${file("${path.module}/esx_init.sh.tpl")}"

  vars = {
    hostname_fqdn = "${local.hostname}-${format(each.key)}.${var.vmw_dns_root_domain}"
    mgmt_vlan = var.vmw_mgmt_vlan_id
    new_mgmt_ip_address = var.vmw_enable_vcf_mode ? ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[each.key].address : ""
    new_mgmt_netmask = var.vmw_enable_vcf_mode ? cidrnetmask(data.ibm_is_subnet.vmw_mgmt_subnet.ipv4_cidr_block) : ""
    new_mgmt_default_gateway = var.vmw_enable_vcf_mode ? cidrhost(data.ibm_is_subnet.vmw_mgmt_subnet.ipv4_cidr_block,1) : ""
    old_mgmt_default_gateway = var.vmw_enable_vcf_mode ? cidrhost(data.ibm_is_subnet.vmw_host_subnet.ipv4_cidr_block,1) : ""
    dns_server_1 = var.vmw_enable_vcf_mode ? var.vmw_dns_servers[0] : var.vmw_dns_servers[0]
    dns_server_2 = var.vmw_enable_vcf_mode ? var.vmw_dns_servers[1] : var.vmw_dns_servers[1]
    ntp_server = var.vmw_ntp_server
  }

}


##############################################################
# List for allowed VLANs
##############################################################

locals {
  allowed_vlans_list = var.vmw_enable_vcf_mode ? concat(var.wmv_allow_vlan_list,[var.vmw_mgmt_vlan_id, var.vmw_vmot_vlan_id, var.vmw_vsan_vlan_id, var.vmw_tep_vlan_id, var.vmw_edge_uplink_public_vlan_id, var.vmw_edge_uplink_private_vlan_id, var.vmw_edge_tep_vlan_id]) : concat(var.wmv_allow_vlan_list,[var.vmw_mgmt_vlan_id, var.vmw_vmot_vlan_id, var.vmw_vsan_vlan_id, var.vmw_tep_vlan_id, var.vmw_edge_uplink_public_vlan_id, var.vmw_edge_uplink_private_vlan_id])
}


# Interface name        | Interface type | VLAN ID | Subnet              | Allow float
# ----------------------|----------------|---------|---------------------|--------------
# pci-nic-vmnic0-vmk0   | pci            | 0       | vmw_host_subnet     | false
# pci-nic-vmnic0-vmk0   | pci            | 0       | vmw_host_subnet     | false


resource "ibm_is_bare_metal_server" "esx_host" {
    for_each = toset(var.vmw_host_list)

    profile = var.vmw_host_profile
    user_data = data.template_file.userdata[each.key].rendered
    name = "${local.hostname}-${format(each.key)}"
    resource_group  = var.vmw_resource_group_id
    image = var.vmw_esx_image
    zone = var.vmw_vpc_zone
    keys = [var.vmw_key]
    primary_network_interface {
      # pci 1
      subnet = var.vmw_host_subnet
      allowed_vlans = local.allowed_vlans_list
      name = var.vmw_enable_vcf_mode ? "pci-nic-vmnic0-uplink1" : "pci-nic-vmnic0-vmk0"
      security_groups = [var.vmw_sg_mgmt]
      enable_infrastructure_nat = true
    }
    dynamic "network_interfaces" {
      for_each = var.vmw_enable_vcf_mode ? toset(var.vmw_host_list) : toset([])
      content {
        # pci 2 for vcf
        subnet = var.vmw_host_subnet
        allowed_vlans = local.allowed_vlans_list 
        name = "pci-nic-vmnic1-uplink2"
        security_groups = [var.vmw_sg_mgmt]
        enable_infrastructure_nat = true
      }
    }

    tags = var.vmw_tags

    vpc = var.vmw_vpc
    timeouts {
      create = "30m"
      update = "30m"
      delete = "30m"
    }

    lifecycle {
      ignore_changes = [user_data,image]
    }
}




/* old
output "ibm_is_bare_metal_server_id" {
  value = [for k in var.vmw_host_list : ibm_is_bare_metal_server.esx_host[k].id]
}



output "ibm_is_bare_metal_server_hostname" {
  value = [for k in var.vmw_host_list : ibm_is_bare_metal_server.esx_host[k].name]
}
*/


output "ibm_is_bare_metal_server_id" {
  value = { for k in var.vmw_host_list : k => ibm_is_bare_metal_server.esx_host[k].id }
}

output "ibm_is_bare_metal_server_hostname" {
  value = { for k in var.vmw_host_list : k => ibm_is_bare_metal_server.esx_host[k].name }
}



##############################################################
# Create VLAN NIC for VCF vmk1
##############################################################

#/*
resource "ibm_is_bare_metal_server_network_interface_allow_float" "esx_host_vcf_mgmt" {
    for_each = var.vmw_enable_vcf_mode ? toset(var.vmw_host_list) : toset([])

    bare_metal_server = ibm_is_bare_metal_server.esx_host[each.key].id
    subnet = var.vmw_mgmt_subnet
    name   = "vlan-nic-vcf-${var.vmw_cluster_prefix}-${format(each.key)}-vmk1"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = var.vmw_mgmt_vlan_id
    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[each.key].reserved_ip
    } 
    depends_on = [
      ibm_is_bare_metal_server.esx_host,
      ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt
    ]
}



##############################################################
# Output vmk0 for non-VCF and vmk1 for VCF
##############################################################



# Note. Create a dummy list for IPs and IDs to return IF the VCF mode is NOT ceated for conditinal checks in outputs.

/* old

output "ibm_is_bare_metal_server_mgmt_interface_ip_address" {
  value = var.vmw_enable_vcf_mode ? [for k in var.vmw_host_list : ibm_is_bare_metal_server_network_interface_allow_float.esx_host_vcf_mgmt[k].primary_ip[0].address] : [for k in var.vmw_host_list : ibm_is_bare_metal_server.esx_host[k].primary_network_interface[0].primary_ip[0].address]
}


output "ibm_is_bare_metal_server_mgmt_interface_id" {
  value = var.vmw_enable_vcf_mode ? [for k in var.vmw_host_list : ibm_is_bare_metal_server_network_interface_allow_float.esx_host_vcf_mgmt[k].id] : [ for host in range(length(var.vmw_host_list)): "primary PCI interface" ]
}
*/

output "ibm_is_bare_metal_server_mgmt_interface_ip_address" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k =>  ibm_is_bare_metal_server_network_interface_allow_float.esx_host_vcf_mgmt[k].primary_ip[0].address } :  { for k in var.vmw_host_list : k => ibm_is_bare_metal_server.esx_host[k].primary_network_interface[0].primary_ip[0].address }
}


output "ibm_is_bare_metal_server_mgmt_interface_id" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k =>  ibm_is_bare_metal_server_network_interface_allow_float.esx_host_vcf_mgmt[k].id } : { for k in var.vmw_host_list : k =>  "primary PCI interface" }
}


##############################################################
# Get host root passwords
##############################################################

data "ibm_is_bare_metal_server_initialization" "esx_host_init_values" {
    for_each = toset(var.vmw_host_list)
    bare_metal_server = ibm_is_bare_metal_server.esx_host[each.key].id
    private_key = var.vmw_instance_ssh_private_key
}

/* old
output "ibm_is_bare_metal_server_initialization" {
  value = [for k in var.vmw_host_list : data.ibm_is_bare_metal_server_initialization.esx_host_init_values[k]]
}
*/

output "ibm_is_bare_metal_server_initialization" {
  value = { for k in var.vmw_host_list : k => data.ibm_is_bare_metal_server_initialization.esx_host_init_values[k] }
}


##############################################################
# Create VLAN NICs
##############################################################

# Interface name        | Interface type | VLAN ID | Subnet              | Allow float
# ----------------------|----------------|---------|---------------------|--------------
# vlan-nic-vcf-vmk0     | vlan           | 100     | vmw_mgmt_subnet     | false
# vlan-nic-vmotion-vmk1 | vlan           | 200     | vmw_vmot_subnet     | false
# vlan-nic-vsan-vmk2    | vlan           | 300     | vmw_vsan_subnet     | false
# vlan-nic-tep-vmk10    | vlan           | 400     | vmw_tep_subnet      | false





##############################################################
# Create Non-VCF VLAN NICs
##############################################################

##############################################################
# Create VLAN NIC for vMotion
##############################################################

resource "ibm_is_bare_metal_server_network_interface" "esx_host_vmot" {
    for_each = var.vmw_enable_vcf_mode ? toset([]) : toset(var.vmw_host_list)
    bare_metal_server = ibm_is_bare_metal_server.esx_host[each.key].id
    subnet = var.vmw_vmot_subnet
    name   = "vlan-nic-vmotion-vmk1"
    security_groups = [var.vmw_sg_vmot]
    allow_ip_spoofing = false
    vlan = var.vmw_vmot_vlan_id
    allow_interface_to_float = false

    
    depends_on = [
      ibm_is_bare_metal_server.esx_host,
    ]
}

/* old
output "ibm_is_bare_metal_server_network_interface_vmot_id" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "none" ] : ibm_is_bare_metal_server_network_interface.esx_host_vmot[*].id
}

output "ibm_is_bare_metal_server_network_interface_vmot_ip_address" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "use-vcf-pool" ] : ibm_is_bare_metal_server_network_interface.esx_host_vmot[*].primary_ip[0].address
}
*/

output "ibm_is_bare_metal_server_network_interface_vmot_id" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "none" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_vmot[k].id }
}

output "ibm_is_bare_metal_server_network_interface_vmot_ip_address" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "use-vcf-pool" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_vmot[k].primary_ip[0].address }
}


##############################################################
# Create VLAN NIC for vSAN
##############################################################


resource "ibm_is_bare_metal_server_network_interface" "esx_host_vsan" {
    for_each = var.vmw_enable_vcf_mode ? toset([]) : toset(var.vmw_host_list)
    bare_metal_server = ibm_is_bare_metal_server.esx_host[each.key].id
    subnet = var.vmw_vsan_subnet
    name   = "vlan-nic-vsan-vmk2"
    security_groups = [var.vmw_sg_vsan]
    allow_ip_spoofing = false
    vlan = var.vmw_vsan_vlan_id
    allow_interface_to_float = false

    depends_on = [
      ibm_is_bare_metal_server.esx_host,
    ]
}

/* old
output "ibm_is_bare_metal_server_network_interface_vsan_id" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "none" ] : ibm_is_bare_metal_server_network_interface.esx_host_vsan[*].id
}

output "ibm_is_bare_metal_server_network_interface_vsan_ip_address" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "use-vcf-pool" ] : ibm_is_bare_metal_server_network_interface.esx_host_vsan[*].primary_ip[0].address
}
*/

output "ibm_is_bare_metal_server_network_interface_vsan_id" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "none" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_vsan[k].id }
}

output "ibm_is_bare_metal_server_network_interface_vsan_ip_address" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "use-vcf-pool" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_vsan[k].primary_ip[0].address }
}

##############################################################
# Create VLAN NIC for TEP
##############################################################

# Note...TEPs provisioned as follows do not allow floating - must be configured per host 

resource "ibm_is_bare_metal_server_network_interface" "esx_host_tep" {
    for_each = var.vmw_enable_vcf_mode ? toset([]) : toset(var.vmw_host_list)
    bare_metal_server = ibm_is_bare_metal_server.esx_host[each.key].id
    subnet = var.vmw_tep_subnet
    name   = "vlan-nic-tep-vmk10-${format("%03s", each.key)}"
    security_groups = [var.vmw_sg_tep]
    allow_ip_spoofing = false
    vlan = var.vmw_tep_vlan_id
    allow_interface_to_float = false

    depends_on = [
      ibm_is_bare_metal_server.esx_host,
    ]
}

/* old
output "ibm_is_bare_metal_server_network_interface_tep_id" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "none" ] : ibm_is_bare_metal_server_network_interface.esx_host_tep[*].id
}

output "ibm_is_bare_metal_server_network_interface_tep_ip_address" {
  value = var.vmw_enable_vcf_mode ? [ for host in range(length(var.vmw_host_list)): "use-vcf-pool" ] : ibm_is_bare_metal_server_network_interface.esx_host_tep[*].primary_ip[0].address
}
*/


output "ibm_is_bare_metal_server_network_interface_tep_id" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "none" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_tep[k].id }
}

output "ibm_is_bare_metal_server_network_interface_tep_ip_address" {
  value = var.vmw_enable_vcf_mode ? { for k in var.vmw_host_list : k => "use-vcf-pool" } : { for k in var.vmw_host_list : k => ibm_is_bare_metal_server_network_interface.esx_host_tep[k].primary_ip[0].address }
}


