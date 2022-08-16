##############################################################
# Create workspace
##############################################################


resource "ibm_schematics_workspace" "schematics_workspace_vcf" {
  name = "ibmcloud-for-vmware-cloud-foundation-0-9"
  description = "Terraform template to provision VPC assets for VCF deployment."
  location = var.schematics_workspace_location
  resource_group = var.schematics_workspace_rg
  template_type = var.schematics_workspace_template_type

  template_git_url = var.template_git_url

  template_inputs  {
            name = "deploy_dns"
            type = "bool"
            value = var.deploy_dns

      }  

  template_inputs  {
            name = "deploy_iam"
            type = "bool"
            value = var.deploy_iam
      } 

  template_inputs  {
            name = "enable_vcf_mode"
            type = "bool"
            value = var.deploy_iam
      } 


  template_inputs  {
            name = "resource_group_name"
            type = "string"
            value = var.resource_group_name
      } 

  template_inputs  {
            name = "resource_prefix"
            type = "string"
            value = var.resource_prefix
      } 

  template_inputs  {
            name = "tags"
            type = "list(string)"
            value = jsonencode(var.tags)
      }  


  template_inputs  {
            name = "dns_root_domain"
            type = "string"
            value = var.dns_root_domain
      }  


  template_inputs  {
            name = "dns_servers"
            type = "list(string)"
            value = jsonencode(var.dns_servers)
      }  
  
  template_inputs  {
            name = "dns_records"
            type = "list(object({name = string, ip_address = string}))"
            value = jsonencode(var.dns_records)

      }  
  

  template_inputs  {
            name = "ntp_server"
            type = "string"
            value = var.ntp_server
      }  


  template_inputs  {
            name = "ibmcloud_vpc_region"
            type = "string"
            value = var.ibmcloud_vpc_region
      }

  template_inputs  {
            name = "vpc_zone"
            type = "string"
            value = var.vpc_zone
      }  

  template_inputs  {
            name = "vcf_architecture"
            type = "string"
            value = var.vcf_architecture
      }  

  template_inputs  {
            name = "vcf_mgmt_host_pool_size"
            type = "string"
            value = var.vcf_mgmt_host_pool_size
      }  


  template_inputs  {
            name = "zone_clusters"
            type = "map"
            value = jsonencode(var.zone_clusters)
            #value = var.zone_clusters
      }  

  template_inputs  {
            name = "esxi_image"
            type = "string"
            value = var.esxi_image
      }

  template_inputs  {
            name = "esxi_image_name"
            type = "string"
            value = var.esxi_image_name
      }

  template_inputs  {
            name = "number_of_bastion_hosts"
            type = "string"
            value = var.number_of_bastion_hosts
      }  

  template_inputs  {
            name = "number_of_bastion_hosts_linux"
            type = "string"
            value = var.number_of_bastion_hosts_linux
      }  

  template_inputs  {
            name = "vsi_profile_bastion_linux"
            type = "string"
            value = var.vsi_profile_bastion_linux
      }  

  template_inputs  {
            name = "vsi_image_os_linux"
            type = "string"
            value = var.vsi_image_os_linux
      }  

  template_inputs  {
            name = "vpc_zone_prefix"
            type = "string"
            value = var.vpc_zone_prefix
      }  

  template_inputs  {
            name = "vpc_zone_prefix_t0_uplinks"
            type = "string"
            value = var.vpc_zone_prefix_t0_uplinks
      }  

  template_inputs  {
            name = "user_provided_ssh_keys"
            type = "list(strings)"
            value = jsonencode(var.user_provided_ssh_keys)
      }  

  template_inputs  {
            name = "mgmt_vlan_id"
            type = "number"
            value = var.mgmt_vlan_id
      }  

  template_inputs  {
            name = "vmot_vlan_id"
            type = "number"
            value = var.vmot_vlan_id
      }  

  template_inputs  {
            name = "vsan_vlan_id"
            type = "number"
            value = var.vsan_vlan_id
      }  

  template_inputs  {
            name = "tep_vlan_id"
            type = "number"
            value = var.tep_vlan_id
      }  

  template_inputs  {
            name = "edge_uplink_public_vlan_id"
            type = "number"
            value = var.edge_uplink_public_vlan_id
      }  

  template_inputs  {
            name = "edge_uplink_private_vlan_id"
            type = "number"
            value = var.edge_uplink_private_vlan_id
      }  

  template_inputs  {
            name = "edge_tep_vlan_id"
            type = "number"
            value = var.edge_tep_vlan_id
      }  

  template_inputs  {
            name = "wl_mgmt_vlan_id"
            type = "number"
            value = var.wl_mgmt_vlan_id
      }  

  template_inputs  {
            name = "wl_vmot_vlan_id"
            type = "number"
            value = var.wl_vmot_vlan_id
      }  

  template_inputs  {
            name = "wl_vsan_vlan_id"
            type = "number"
            value = var.wl_vsan_vlan_id
      }  

  template_inputs  {
            name = "wl_tep_vlan_id"
            type = "number"
            value = var.wl_tep_vlan_id
      }  

  template_inputs  {
            name = "wl_edge_uplink_private_vlan_id"
            type = "number"
            value = var.wl_edge_uplink_private_vlan_id
      }  

  template_inputs  {
            name = "wl_edge_uplink_public_vlan_id"
            type = "number"
            value = var.wl_edge_uplink_public_vlan_id
      }  

  template_inputs  {
            name = "wl_edge_tep_vlan_id"
            type = "number"
            value = var.wl_edge_tep_vlan_id
      }  

  template_inputs  {
            name = "vcf_password"
            type = "string"
            value = var.vcf_password
      }  

  template_inputs  {
            name = "vcf_mgmt_domain_name"
            type = "string"
            value = var.vcf_mgmt_domain_name
      }  

  template_inputs  {
            name = "xvcf_cluster_namexx"
            type = "string"
            value = var.vcf_cluster_name
      }  

  template_inputs  {
            name = "vcf_dc_name"
            type = "string"
            value = var.vcf_dc_name
      }  

  template_inputs  {
            name = "sddc_manager_license"
            type = "string"
            value = var.sddc_manager_license
      }  

  template_inputs  {
            name = "nsx_t_license"
            type = "string"
            value = var.nsx_t_license
      }  

  template_inputs  {
            name = "vsan_license"
            type = "string"
            value = var.vsan_license
      }  

  template_inputs  {
            name = "vcenter_license"
            type = "string"
            value = var.vcenter_license
      }  

  template_inputs  {
            name = "esx_license "
            type = "string"
            value = var.esx_license 
      }  

  template_inputs  {
            name = "security_group_rules"
            type = "object({mgmt = list(object({name=string, direction=string})),vmot = list(object({name=string, direction=string})),vsan = list(object({name=string, direction=string})),tep = list(object({name=string, direction=string})),uplink-pub = list(object({name=string, direction=string})),uplink-priv = list(objec({name=string, direction=string})),bastion = list(object({name=string, direction=string}))})"
            value = jsonencode(var.security_group_rules)
      }  
}



