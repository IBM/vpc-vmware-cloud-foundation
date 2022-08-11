
##############################################################
# Create VLAN NIC for vCenter
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "vcenter" {
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_mgmt_subnet
    name   = "vlan-nic-${var.vmw_vcenter_name}"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = var.vmw_mgmt_vlan_id
    #allow_interface_to_float = true
}

output "vmw_vcenter_ip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.vcenter.primary_ip[0].address
}
