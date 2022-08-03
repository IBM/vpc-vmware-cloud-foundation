

##############################################################
# Create bringup json
##############################################################


data "template_file" "vcf_bringup_json" {
  count = var.enable_vcf_mode ? 1 : 0 
  template = "${file("TEMPLATE/vcf-ibm-ems-template_json.tpl")}"

  vars = {
      vcf_mgmt_domain = "${var.vpc_zone}-${var.vcf_mgmt_domain_name}"
      vcf_cluster_name = var.vcf_cluster_name
      vcf_dc_name = var.vcf_dc_name

      sddc_manager_password = var.vcf_password == "" ? random_string.sddc_manager_password.result : var.vcf_password
      vcenter_password = var.vcf_password == "" ? random_string.vcenter_password.result : var.vcf_password
      nsx_password = var.vcf_password == "" ? random_string.nsxt_password.result : var.vcf_password

      dns_domain = var.dns_root_domain
      dns_server_1 = var.dns_servers[0]
      dns_server_2 = var.dns_servers[1]

      ntp_server = var.ntp_server

      sddc_manager_ip = local.vcf.sddc_manager.ip_address
      sddc_manager_mask = cidrnetmask(local.subnets.mgmt.cidr)

      sddc_manager_license = var.sddc_manager_license
      nsx_t_license = var.nsx_t_license
      vsan_license = var.vsan_license
      vcenter_license = var.vcenter_license
      esx_license = var.esx_license

      vcenter_ip = local.vcenter.ip_address

      nsx_t_0_ip = local.nsx_t_mgr.nsx_t_0.ip_address
      nsx_t_1_ip = local.nsx_t_mgr.nsx_t_1.ip_address
      nsx_t_2_ip = local.nsx_t_mgr.nsx_t_2.ip_address
      nsx_t_vip = local.nsx_t_mgr.nsx_t_vip.ip_address

      network_mgmt_cidr = local.subnets.mgmt.cidr
      network_mgmt_gateway = local.subnets.mgmt.default_gateway

      network_vmot_cidr = local.subnets.vmot.cidr
      network_vmot_gateway = local.subnets.vmot.default_gateway
      network_vmot_start = local.vcf_pools.vmot[0]
      network_vmot_end = local.vcf_pools.vmot[length(local.vcf_pools.vmot)-1]

      network_vsan_cidr = local.subnets.vsan.cidr
      network_vsan_gateway = local.subnets.vsan.default_gateway
      network_vsan_start = local.vcf_pools.vsan[0]
      network_vsan_end = local.vcf_pools.vsan[length(local.vcf_pools.vsan)-1]

      network_tep_cidr = local.subnets.tep.cidr
      network_tep_gateway = local.subnets.tep.default_gateway
      network_tep_start = local.vcf_pools.tep[0]
      network_tep_end = local.vcf_pools.tep[length(local.vcf_pools.tep)-1]

      vlan_mgmt = var.mgmt_vlan_id
      vlan_vmot = var.vmot_vlan_id
      vlan_vsan = var.vsan_vlan_id
      vlan_tep = var.tep_vlan_id

      host_000_ip = local.cluster_host_map.clusters[0].hosts[0].mgmt.ip_address
      host_000_password = local.cluster_host_map.clusters[0].hosts[0].password
      host_000_hostname = local.cluster_host_map.clusters[0].hosts[0].host

      host_001_ip = local.cluster_host_map.clusters[0].hosts[1].mgmt.ip_address
      host_001_password = local.cluster_host_map.clusters[0].hosts[1].password
      host_001_hostname = local.cluster_host_map.clusters[0].hosts[1].host

      host_002_ip = local.cluster_host_map.clusters[0].hosts[2].mgmt.ip_address
      host_002_password = local.cluster_host_map.clusters[0].hosts[2].password
      host_002_hostname = local.cluster_host_map.clusters[0].hosts[2].host

      host_003_ip = local.cluster_host_map.clusters[0].hosts[3].mgmt.ip_address
      host_003_password = local.cluster_host_map.clusters[0].hosts[3].password
      host_003_hostname = local.cluster_host_map.clusters[0].hosts[3].host
  }

}

##############################################################
# Write bringup json to file
##############################################################


resource "local_file" "write_vcf_bringup_json" {
  count = var.enable_vcf_mode ? 1 : 0 

  content         = data.template_file.vcf_bringup_json[0].rendered
  filename        = "OUTPUT/${local.resources_prefix}-ibm-ems-bringup.json"
  file_permission = 0600
}








