
deploy_dns = false
deploy_fileshare = false
deploy_iam = false
enable_vcf_mode = true
deploy_bastion = true


# Resource group name to use
# leave empty if you want to provision a new resource group

resource_group_name = "Default"


# Resource prefix for naming assets

resource_prefix = "vcf"


# DNS root domain

dns_root_domain = "vcf-test-1.ibmcloud.local"


# IBM CLoud Region and VPC Zone

ibmcloud_vpc_region = "us-south"
vpc_zone = "us-south-1"


# Hosts and clusters

zone_clusters = {
                  cluster_0 = { 
                     name = "type1"
                     #vmw_host_profile = "bx2d-metaldev8-192x768"
                     vmw_host_profile = "bx2d-metaldev8-160x768"
                     host_count = 4 
                     vpc_file_shares = [ ] 
                     },
                  cluster_1 = { 
                     name = "type2"
                     vmw_host_profile = "bx2d-metaldev8-160x768"
                     host_count = 0 
                     vpc_file_shares = [ ] 
                     },
                 }


# Networking

vpc_zone_prefix = "10.100.0.0/22"
vpc_zone_prefix_t0_uplinks = "192.168.10.0/24"

mgmt_vlan_id = 1611
vmot_vlan_id = 1612
vsan_vlan_id = 1613
tep_vlan_id	= 1614

edge_uplink_public_vlan_id	= 2711
edge_uplink_private_vlan_id = 2712

vcf_host_pool_size = 10
vcf_edge_pool_size = 4

