
##############################################################
# Create VLAN NICs for NSX-T Edge / T0 Private Uplinks
##############################################################

// Important for private uplinks :
//   allow_ip_spoofing = true 
//   enable_infrastructure_nat = true
//   allow_interface_to_float = true

resource "ibm_is_bare_metal_server_network_interface_allow_float" "t0_uplink_private" {
    count = 2
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_priv_subnet_id
    name   = "vlan-nic-t0-uplink-private-edge-${count.index}"
    security_groups = [var.vmw_sg_uplink]
    allow_ip_spoofing = true
    enable_infrastructure_nat = true
    vlan = var.vmw_edge_uplink_private_vlan_id
}

resource "ibm_is_bare_metal_server_network_interface_allow_float" "t0_uplink_private_vip" {
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_priv_subnet_id
    name   = "vlan-nic-t0-uplink-private-vip"
    security_groups = [var.vmw_sg_uplink]
    allow_ip_spoofing = true
    enable_infrastructure_nat = true
    vlan = var.vmw_edge_uplink_private_vlan_id
}

output "t0_uplink_private" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.t0_uplink_private[*]
}

output "t0_uplink_private_vip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.t0_uplink_private_vip
}



##############################################################
# Create VLAN NICs for NSX-T Edge / T0 Public Uplinks
##############################################################

// Important for public uplinks :
//   allow_ip_spoofing = false 
//   enable_infrastructure_nat = false
//   allow_interface_to_float = true


resource "ibm_is_bare_metal_server_network_interface_allow_float" "t0_uplink_public" {
    count = 2
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_pub_subnet_id
    name   = "vlan-nic-t0-uplink-public-edge-${count.index}"
    security_groups = [var.vmw_sg_uplink]
    allow_ip_spoofing = false
    enable_infrastructure_nat = false
    vlan = var.vmw_edge_uplink_public_vlan_id
}


resource "ibm_is_bare_metal_server_network_interface_allow_float" "t0_uplink_public_vip" {
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_pub_subnet_id
    name   = "vlan-nic-t0-uplink-public-vip"
    security_groups = [var.vmw_sg_uplink]
    allow_ip_spoofing = false
    enable_infrastructure_nat = false
    vlan = var.vmw_edge_uplink_public_vlan_id
}

output "t0_uplink_public" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.t0_uplink_public[*]
}

output "t0_uplink_public_vip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.t0_uplink_public_vip
}

