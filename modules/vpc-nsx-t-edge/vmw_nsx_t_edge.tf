##############################################################
# Create VLAN NICs for NSX-T Edge Management
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "nsx_t_edge_mgmt" {
    count = 2
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_mgmt_subnet_id
    name   = "vlan-nic-${var.vmw_edge_name}-${count.index}-mgmt"
    security_groups = [var.vmw_sg_mgmt]
    allow_ip_spoofing = false
    vlan = var.vmw_mgmt_vlan_id
}


output "vmw_nsx_t_edge_mgmt_ip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.nsx_t_edge_mgmt[*]
}

##############################################################
# Create VLAN NICs for NSX-T Edge TEPs
##############################################################

resource "ibm_is_bare_metal_server_network_interface_allow_float" "nsx_t_edge_tep" {
    count = var.vmw_enable_vcf_mode ? 4 : 2
    bare_metal_server = var.vmw_vcenter_esx_host_id
    subnet = var.vmw_tep_subnet_id
    name   = "vlan-nic-tep-${var.vmw_edge_name}-${count.index}"
    security_groups = [var.vmw_sg_tep]
    allow_ip_spoofing = false
    vlan = var.vmw_tep_vlan_id
}

output "vmw_nsx_t_edge_tep_ip" {
   value = ibm_is_bare_metal_server_network_interface_allow_float.nsx_t_edge_tep[*]
}


