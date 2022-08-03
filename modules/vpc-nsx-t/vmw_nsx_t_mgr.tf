##############################################################
# Create VLAN NICs for NSX-T Managers
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "nsx_t_manager" {
    count = 3
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_mgmt_subnet_id
    name   = "vlan-nic-nsx-t-${count.index}"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = var.vmw_mgmt_vlan_id
}

output "vmw_nsx_t_manager_ip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.nsx_t_manager[*]
}


resource "ibm_is_bare_metal_server_network_interface_allow_float" "nsx_t_manager_vip" {
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_mgmt_subnet_id
    name   = "vlan-nic-nsx-t-vip"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = var.vmw_mgmt_vlan_id
}

output "vmw_nsx_t_manager_ip_vip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.nsx_t_manager_vip
}


