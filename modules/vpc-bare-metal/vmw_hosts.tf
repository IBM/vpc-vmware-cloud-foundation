
##############################################################
# Create reserved subnet IP for VCF vmk1
##############################################################


# Reserve an IP from instance mgmt subnet and use that in the userdata/cloud-init to re-configure vmk1 for vcf

resource "ibm_is_subnet_reserved_ip" "esx_host_vcf_mgmt" {
    count = var.vmw_enable_vcf_mode ? var.vmw_host_count : 0
    subnet = var.vmw_mgmt_subnet
    name   = "vlan-nic-vcf-mgmt-${format("%03s", count.index)}-vmk1"
    auto_delete = false
}

output "esx_host_vcf_mgmt_reserved_ips_list" {
  value = ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[*].address
}


##############################################################
# Create private Bare Metal Servers
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
  count = var.vmw_host_count
  template = var.vmw_enable_vcf_mode ? "${file("${path.module}/esx_vcf_init.sh.tpl")}" : "${file("${path.module}/esx_init.sh.tpl")}"

  vars = {
    hostname_fqdn = "${local.hostname}-${format("%03s", count.index)}.${var.vmw_dns_root_domain}"
    mgmt_vlan = 100
    #new_mgmt_ip_address = local.mgmt_ip_list[count.index]
    new_mgmt_ip_address = var.vmw_enable_vcf_mode ? ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[count.index].address : ""
    new_mgmt_netmask = var.vmw_enable_vcf_mode ? cidrnetmask(data.ibm_is_subnet.vmw_mgmt_subnet.ipv4_cidr_block) : ""
    new_mgmt_default_gateway = var.vmw_enable_vcf_mode ? cidrhost(data.ibm_is_subnet.vmw_mgmt_subnet.ipv4_cidr_block,1) : ""
    old_mgmt_default_gateway = var.vmw_enable_vcf_mode ? cidrhost(data.ibm_is_subnet.vmw_host_subnet.ipv4_cidr_block,1) : ""
  }
}




# Interface name        | Interface type | VLAN ID | Subnet              | Allow float
# ----------------------|----------------|---------|---------------------|--------------
# pci-nic-vmnic0-vmk0   | pci            | 0       | vmw_host_subnet     | false
# pci-nic-vmnic0-vmk0   | pci            | 0       | vmw_host_subnet     | false


resource "ibm_is_bare_metal_server" "esx_host" {
    count = var.vmw_host_count
    profile = var.vmw_host_profile
    user_data = data.template_file.userdata[count.index].rendered
    name = "${local.hostname}-${format("%03s", count.index)}"
    resource_group  = var.vmw_resource_group_id
    image = var.vmw_esx_image
    zone = var.vmw_vpc_zone
    keys = [var.vmw_key]
    primary_network_interface {
      subnet = var.vmw_host_subnet
      allowed_vlans = [100, 200, 300, 400, 700, 710]
      name = var.vmw_enable_vcf_mode ? "pci-nic-vmnic1-uplink2" : "pci-nic-vmnic0-vmk0"
      #name = "pci-nic-vmnic0-vmk0"
      security_groups = [var.vmw_sg_mgmt]
      enable_infrastructure_nat = true
    }
    ## vcf hack ##
    /* vmk1 done with ibm_is_bare_metal_server_network_interface
    dynamic "network_interfaces" {
      for_each = var.vmw_enable_vcf_mode ? ["vlan-nic-vcf-vmk1"] : []
      content {
       # vcf mgmt
       subnet = var.vmw_mgmt_subnet
       vlan = 100
       name   = "vlan-nic-vcf-vmk1"
       security_groups = [var.vmw_sg_mgmt]
       enable_infrastructure_nat = true
       # allow_interface_to_float = false
       primary_ip {
           reserved_ip = ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[count.index].reserved_ip
       } 
      }
    }
    #*/
    dynamic "network_interfaces" {
      for_each = var.vmw_enable_vcf_mode ? ["pci-nic-vmnic1"] : []
      content {
        # pci2
        subnet = var.vmw_host_subnet
        # allowed_vlans = [100, 200, 300, 400, 700, 710] ## this currently works only in dev
        allowed_vlans = [10]
        name = "pci-nic-vmnic1-uplink2"
        security_groups = [var.vmw_sg_mgmt]
        enable_infrastructure_nat = true
      }
    }
    
    ## end of vcf hack ## 
    vpc = var.vmw_vpc
    timeouts {
      create = "30m"
      update = "30m"
      delete = "30m"
    }
}

output "ibm_is_bare_metal_server_id" {
  value = ibm_is_bare_metal_server.esx_host[*].id
}

output "ibm_is_bare_metal_server_mgmt_interface" {
  value = ibm_is_bare_metal_server.esx_host[*].primary_network_interface
}

## vcf hack ##
/*
output "ibm_is_bare_metal_server_network_interface_vcf_mgmt" {
  value = ibm_is_bare_metal_server.esx_host[*].network_interfaces
}
#*/
## end of vcf hack ## 



output "ibm_is_bare_metal_server_fqdn" {
  value = ibm_is_bare_metal_server.esx_host[*].name
}




##############################################################
# Get host root passwords
##############################################################

data "ibm_is_bare_metal_server_initialization" "esx_host_init_values" {
    count       = var.vmw_host_count
    bare_metal_server = ibm_is_bare_metal_server.esx_host[count.index].id
    private_key = var.vmw_instance_ssh_private_key
}


output "ibm_is_bare_metal_server_initialization" {
  value = data.ibm_is_bare_metal_server_initialization.esx_host_init_values[*]
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
# Create VLAN NIC for VCF vmk1
##############################################################

#/*
resource "ibm_is_bare_metal_server_network_interface" "esx_host_vcf_mgmt" {
    count = var.vmw_enable_vcf_mode ? var.vmw_host_count : 0
    bare_metal_server = ibm_is_bare_metal_server.esx_host[count.index].id
    subnet = var.vmw_mgmt_subnet
    name   = "vlan-nic-vcf-vmk1"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = 100
    primary_ip {
        reserved_ip = ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt[count.index].reserved_ip
    } 
    allow_interface_to_float = false
    depends_on = [
      ibm_is_bare_metal_server.esx_host,
      ibm_is_subnet_reserved_ip.esx_host_vcf_mgmt
    ]
}


output "ibm_is_bare_metal_server_network_interface_vcf_mgmt" {
  value = ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt[*]
}



# Note. Create a dummy list for IPs and IDs to return IF the VCF mode is NOT ceated for conditinal checks in outputs.

output "ibm_is_bare_metal_server_network_interface_vcf_mgmt_ip_address" {
  value = var.vmw_enable_vcf_mode ? ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt[*].primary_ip[0].address : [ for host in range(var.vmw_host_count): "0.0.0.0" ]
}

output "ibm_is_bare_metal_server_network_interface_vcf_mgmt_id" {
  value = var.vmw_enable_vcf_mode ? ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt[*].id : [ for host in range(var.vmw_host_count): "none" ]
}



##############################################################
# Create VLAN NIC for vMotion
##############################################################

resource "ibm_is_bare_metal_server_network_interface" "esx_host_vmot" {
    count = var.vmw_host_count
    bare_metal_server = ibm_is_bare_metal_server.esx_host[count.index].id
    subnet = var.vmw_vmot_subnet
    name   = "vlan-nic-vmotion-vmk1"
    security_groups = [var.vmw_sg_vmot]
    allow_ip_spoofing = false
    vlan = 200
    allow_interface_to_float = false

    
    depends_on = [
      ibm_is_bare_metal_server.esx_host,
      #ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt
    ]
}

output "ibm_is_bare_metal_server_network_interface_vmot" {
  value = ibm_is_bare_metal_server_network_interface.esx_host_vmot[*]
}




##############################################################
# Create VLAN NIC for vSAN
##############################################################


resource "ibm_is_bare_metal_server_network_interface" "esx_host_vsan" {
    count = var.vmw_host_count
    bare_metal_server = ibm_is_bare_metal_server.esx_host[count.index].id
    subnet = var.vmw_vsan_subnet
    name   = "vlan-nic-vsan-vmk2"
    security_groups = [var.vmw_sg_vsan]
    allow_ip_spoofing = false
    vlan = 300
    allow_interface_to_float = false

    depends_on = [
      ibm_is_bare_metal_server.esx_host,
      #ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt
    ]
}

output "ibm_is_bare_metal_server_network_interface_vsan" {
  value = ibm_is_bare_metal_server_network_interface.esx_host_vsan[*]
}


##############################################################
# Create VLAN NIC for TEP
##############################################################

# Note...TEPs provisioned as follows do not allow floating - must be configured per host 

resource "ibm_is_bare_metal_server_network_interface" "esx_host_tep" {
    count = var.vmw_host_count
    bare_metal_server = ibm_is_bare_metal_server.esx_host[count.index].id
    subnet = var.vmw_tep_subnet
    name   = "vlan-nic-tep-vmk10-${format("%03s", count.index)}"
    security_groups = [var.vmw_sg_tep]
    allow_ip_spoofing = false
    vlan = 400
    allow_interface_to_float = false

    depends_on = [
      ibm_is_bare_metal_server.esx_host,
      #ibm_is_bare_metal_server_network_interface.esx_host_vcf_mgmt
    ]
}

output "ibm_is_bare_metal_server_network_interface_tep" {
  value = ibm_is_bare_metal_server_network_interface.esx_host_tep[*]
}





