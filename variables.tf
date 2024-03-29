
### Provider

variable "ibmcloud_api_key" {
  description = "Enter your IBM Cloud API Key"
  type = string
}


### Resource group name

variable "resource_group_name" {
  description = "Name of the resource group to deploy the assets. If left empty, then a resource group will be created for you."
  default = ""
  type = string

}

### Tag


variable "tags" {
  description = "Tag to define environment"
  default = ["vcf"]
  type = list(string)
}


### Resource prefix for each item

variable "resource_prefix" {
  description = "Resource name prefix to create in the IBM Cloud account."
  default = "vcf"
  type = string
}


### Deployment option variables

variable "deploy_iam" {
  description = "Boolean to enable IAM deployment."
  default = false
  type = bool
}

variable "deploy_fileshare" {
  description = "Boolean to enable fileshare deployment. Alternatively customize the cluster map."
  default = false
  type = bool
}

variable "deploy_dns" {
  description = "Boolean to enable DNS service deployment."
  default = true
  type = bool
}

variable "enable_vcf_mode" {
  description = "Boolean to enable VCF options for BMS deployment (dual PCI uplinks and vmk1 in instance management subnet)."
  default = true
  type = bool
}


### DNS root domain

variable "dns_root_domain" {
  description = "Root Domain of Private DNS used with the Virtual Server"
  default = "vcf-example.ibmcloud.local"
  type = string
}

variable "dns_servers" {
  description = "DNS servers."
  default = ["161.26.0.7", "161.26.0.8"]
  type = list(string)
}


variable "dns_records" {
  description = "DNS records to create."
  default = [
    {
      name = "xint-vrslcm01"
      ip_address = "172.27.17.20"
    },
  ]
  type = list(object({
    name = string
    ip_address = string
  }))
}



### NTP

variable "ntp_server" {
  description = "IBM Cloud DNS server"
  default = "161.26.0.6"
  type = string
}

### IBM Cloud Region variables

variable "ibmcloud_vpc_region" {
  description = "Enter the target Region of IBM Cloud"
  default = "eu-de"
  type = string
}

variable "vpc_zone" {
  description = "VPC Zone"
  default     = "eu-de-1"
  type = string
}



variable "vpc_name" {
  description = "Name of the VPC to create."
  default     = "vpc"
  type = string
}


/*to be deleted
variable "vpc_t0_public_ips" {
  description = "Number of public / floating IPs for T0."
  default     = 0 
  type = number
}
*/
  
variable "esxi_image" {
  description = "Base ESXI image name, terraform will find the latest available image id."
  default = "esxi-7-byol"
  type = string
}

variable "esxi_image_name" {
  description = "Use a specific ESXI image version to use for the hosts to override the latest by name."
  default = "ibm-esxi-7-0u3d-19482537-byol-amd64-1"
  type = string
}

# Networks

variable "vpc_zone_prefix" {
  description = "This is the address prefix for VMware components for each zone. /22 is recommended for appx. 120 hosts, /23 for appx. 60 hosts etc."
  default  = "10.100.0.0/22"
  type = string
}

variable "vpc_zone_prefix_t0_uplinks" {
  description = "This is the NSX-T uplink address prefix for each zone."
  default  = "192.168.10.0/24"
  type = string
}

variable "vcf_mgmt_host_pool_size" {
  description = "Size of the host network pool to reserve VPC subnet IPs for # of hosts."
  default = 10  
  type = number

  validation {
    condition = (
        var.vcf_mgmt_host_pool_size >= 8
    )
    error_message = "Reserve enough growth for future growth for the solution. This is required for VCF network pool creation." 
  }
}


variable "vcf_wl_host_pool_size" {
  description = "Size of the host network pool to reserve VPC subnet IPs for # of hosts."
  default = 10
  type = number

}


/* to be deleted - not needed
variable "vcf_edge_pool_size" {
  description = "Size of the edge network pool to reserve VPC subnet IPs # of edge nodes."
  default = 2  # Note two TEPs per edge nodes in VCF >> double reservation done in resource 
  type = number
}
*/


/*
variable "nsx_t_overlay_networks" {
  description = "NSX-T overlay network prefixes to create VPC routes"
  type = map
  default = {
    customer_overlay_1 = {
      name = "customer-overlay"
      destination = "172.16.0.0/16"
    },
  }
}
*/



### ESX virtual switch networking / VLAN IDs

variable "host_vlan_id" {
  description = "VLAN ID for host network"
  default     = 0 
  type = number
}

variable "mgmt_vlan_id" {
  description = "VLAN ID for management network"
  # default     = 100 ## IBM Cloud ref arch
  default     = 1611 ## VCF default
  type = number
}

variable "vmot_vlan_id" {
  description = "VLAN ID for vMotion network"
  # default     = 200
  default     = 1612 ## VCF default
  type = number
}

variable "vsan_vlan_id" {
  description = "VLAN ID for vSAN network"
  # default     = 300
  default     = 1613 ## VCF default
  type = number
}

variable "tep_vlan_id" {
  description = "VLAN ID for TEP network"
  # default     = 400
  default     = 1614 ## VCF default
  type = number
}


variable "edge_uplink_public_vlan_id" {
  description = "VLAN ID for T0 public uplink network"
  # default     = 700
  default     = 2711 ## VCF default
  type = number
}

variable "edge_uplink_private_vlan_id" {
  description = "VLAN ID for T0 private uplink network"
  # default     = 710
  default     = 2712 ## VCF default
  type = number
}

variable "edge_tep_vlan_id" {
  description = "VLAN ID for TEP network"
  default     = 2713 ## VCF default
  type = number
}

###

variable "wl_mgmt_vlan_id" {
  description = "VLAN ID for management network"
  # default     = 100 ## IBM Cloud ref arch
  default     = 1631 ## VCF default
  type = number
}

variable "wl_vmot_vlan_id" {
  description = "VLAN ID for vMotion network"
  # default     = 200
  default     = 1632 ## VCF default
  type = number
}

variable "wl_vsan_vlan_id" {
  description = "VLAN ID for vSAN network"
  # default     = 300
  default     = 1633 ## VCF default
  type = number
}

variable "wl_tep_vlan_id" {
  description = "VLAN ID for TEP network"
  # default     = 400
  default     = 1634 ## VCF default
  type = number
}

variable "wl_edge_uplink_public_vlan_id" {
  description = "VLAN ID for T0 public uplink network"
  # default     = 700
  default     = 2731 ## VCF default
  type = number
}

variable "wl_edge_uplink_private_vlan_id" {
  description = "VLAN ID for T0 private uplink network"
  # default     = 710
  default     = 2732 ## VCF default
  type = number
}

variable "wl_edge_tep_vlan_id" {
  description = "VLAN ID for TEP network"
  default     = 2733 ## VCF default
  type = number
}


variable "customer_private_routes" {
  description = "List of customers routes in at on-premises, other VPCs, advertised through TGW etc."
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "customer_public_routes" {
  description = "List of customers routes in at on-premises, other VPCs, advertised through TGW etc."
  default = ["0.0.0.0/0"]
}



# vCenter will be deployed in the first cluster "cluster_0". Please do not change the key if adding new clusters. See examples for alternate configs. 

# Use 'ibmcloud is bare-metal-server-profiles' to get the profiles.

variable "zone_clusters" {
  description = "Clusters in VPC"
  type        = map

  validation {
    condition = (
      anytrue([for k,v in var.zone_clusters : contains(["cluster_0"],k)])
    )
    error_message = "First cluster key must be 'cluster_0'." 
  }

#/*
  validation {
    condition = (
        length(var.zone_clusters["cluster_0"].host_list) >= 4
    )
    error_message = "The number of hosts must be greater than 4." 
  }
#*/

  validation {
    condition = (
        var.zone_clusters["cluster_0"].vcenter == true &&
        var.zone_clusters["cluster_0"].nsx_t_managers == true &&
        var.zone_clusters["cluster_0"].nsx_t_edges == true
    )
    error_message = "VMware VCF management components must be deployed on the initial cluster." 
  }

  validation {
    condition = (
        alltrue([for k,v in var.zone_clusters : length(v.host_list) == length(distinct(v.host_list))])  
        )
    error_message = "Host keys must be unique." 
  }

  #validation {
  #  condition = (
  #      var.zone_clusters["cluster_0"].name == "mgmt"
  #  )
  #  error_message = "The first cluster must be named 'mgmt'." 
  #}

  default     = {
    cluster_0 = {                             # Value must be "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"                         # Value must be "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      #host_count = 4                         # Define a host count for this cluster.      
      host_list = ["000","001","002","003"]   # Define a host count for this cluster.
      vcenter = true                          # Value must be "true" for the first cluster
      nsx_t_managers = true                   # Value must be "true" for the first cluster
      nsx_t_edges = true                      # Value must be "true" for the first cluster
      public_ips = 2                          # Orders # of Floating IPs for the T0. 
      overlay_networks = [                    # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []     # Future use.
    },
  }
}



# Security Groups Rules


/*

# Examples for Security group rules 

variable "security_group_rules" {

    description = "Example for Security groups and rules to create"
    type        = map
    default = {
        "security-group-1" = [              # security group to create
          {
            name      = "allow-all-from-security-group-1"
            direction = "inbound"
            remote_id = "security-group-1"     # name of local group
          },
          {
            name      = "allow-inbound-10-8"
            direction = "inbound"
            remote    = "10.0.0.0/8"
          },
          {
            name      = "allow-inbound-tcp-22"
            direction = "inbound"
            remote    = "0.0.0.0/0"
            tcp = {
              port_max = 22
              port_min = 22             
            }
          },
          {
            name      = "allow-icmp-from-security-group-2"
            direction = "inbound"
            remote_id = "security-group-2"  # name of remote group
            icmp = {
              type = 8
            }
          },
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ],
        "security-group-2" = [              # security group to create
                                            # list or rules to create
        ]
    }
}

#*/


variable "security_group_rules" {
    description = "Security groups and rules rules to create"

/*
    type = object({
      mgmt = list(object({name=string, direction=string})),
      vmot = list(object({name=string, direction=string})),
      vsan = list(object({name=string, direction=string})),
      tep = list(object({name=string, direction=string})),
      uplink-pub = list(object({name=string, direction=string})),
      uplink-priv = list(object({name=string, direction=string})),
      bastion = list(object({name=string, direction=string})),
    })
*/

    type = any


    default = {
        mgmt = [
          {
            name      = "allow-all-mgmt"
            direction = "inbound"
            remote_id = "mgmt"
          },
          {
            name      = "allow-inbound-10-0-0-8"
            direction = "inbound"
            remote    = "10.0.0.0/8"
          },
          {
            name      = "allow-inbound-172-16-0-0-12"
            direction = "inbound"
            remote    = "172.16.0.0/12"
          },
          {
            name      = "allow-inbound-192-168-0-0-16"
            direction = "inbound"
            remote    = "192.168.0.0/8"
          },          
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ],
        vmot = [
          {
            name      = "allow-icmp-mgmt"
            direction = "inbound"
            remote_id = "mgmt"
            icmp = {
              type = 8
            }
          },
          {
            name      = "allow-inbound-vmot"
            direction = "inbound"
            remote_id = "vmot"
          },
          {
            name      = "allow-outbound-vmot"
            direction = "outbound"
            remote_id = "vmot"
          }
        ],
        vsan = [
          {
            name      = "allow-icmp-mgmt"
            direction = "inbound"
            remote_id = "mgmt"
            icmp = {
              type = 8
            }
          },
          {
            name      = "allow-inbound-vsan"
            direction = "inbound"
            remote_id = "vsan"
          },
          {
            name      = "allow-outbound-vsan"
            direction = "outbound"
            remote_id = "vsan"
          }
        ],
        tep = [
          {
            name      = "allow-icmp-mgmt"
            direction = "inbound"
            remote_id = "mgmt"
            icmp = {
              type = 8
            }
          },
          {
            name      = "allow-inbound-tep"
            direction = "inbound"
            remote_id = "tep"
          },
          {
            name      = "allow-outbound-tep"
            direction = "outbound"
            remote_id = "tep"
          }
        ],
        uplink-pub = [
          {
            name      = "allow-inbound-any"
            direction = "inbound"
            remote    = "0.0.0.0/0"
            icmp = {
              type = 8
            }
          },
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ],
        uplink-priv = [
          {
            name      = "allow-inbound-any"
            direction = "inbound"
            remote    = "0.0.0.0/0"
          },
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ],
        bastion = [
          {
            name      = "allow-inbound-rdp"
            direction = "inbound"
            remote    = "0.0.0.0/0"
            tcp = {
              port_max = 3389
              port_min = 3389             
            }
          },
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ]
    }
}


### VPC Subnets

### This defines VPC structure for RYO deployment

variable "vpc_vcf_consolidated" {
    description = "VPC Data Structure"
    type        = map
    default = {
      vpc = {
        zones = {
            vpc_zone = {
              infrastructure = {
                  vpc_zone_subnet_size = 4
                  public_gateways = ["subnet-public-gateway"]
                  subnets = {
                    host = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    mgmt = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                        public_gateway = "subnet-public-gateway"
                    },
                    vmot = {
                        cidr_offset = 2
                        ip_version = "ipv4"
                    },
                    vsan = {
                        cidr_offset = 3
                        ip_version = "ipv4"
                    },
                    tep = {
                        cidr_offset = 4
                        ip_version = "ipv4"
                    },
                }
              },
              edges = {
                  vpc_zone_subnet_size = 4
                  subnets = {
                    t0-priv = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    t0-pub = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                    },
                    edge-tep = {
                        cidr_offset = 2
                        ip_version = "ipv4"                      
                    },             
                  }
              }
            }
        }
      }
    }
}


variable "vpc_vcf_standard" {
    description = "VPC Data Structure"
    type        = map
    default = {
      vpc = {
        zones = {
            vpc_zone = {
              infrastructure = {
                  vpc_zone_subnet_size = 4
                  public_gateways = ["subnet-public-gateway"]
                  subnets = {
                    host = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    mgmt = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                        public_gateway = "subnet-public-gateway"
                    },
                    vmot = {
                        cidr_offset = 2
                        ip_version = "ipv4"
                    },
                    vsan = {
                        cidr_offset = 3
                        ip_version = "ipv4"
                    },
                    tep = {
                        cidr_offset = 4
                        ip_version = "ipv4"
                    },
                    wl-mgmt = {
                        cidr_offset = 5
                        ip_version = "ipv4"
                        public_gateway = "subnet-public-gateway"
                    },
                    wl-vmot = {
                        cidr_offset = 6
                        ip_version = "ipv4"
                    },
                    wl-vsan = {
                        cidr_offset = 7
                        ip_version = "ipv4"
                    },
                    wl-tep = {
                        cidr_offset = 8
                        ip_version = "ipv4"
                    },
                }
              },
              edges = {
                  vpc_zone_subnet_size = 4
                  subnets = {
                    t0-priv = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    t0-pub = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                    },
                    edge-tep = {
                        cidr_offset = 2
                        ip_version = "ipv4"                      
                    },
                    wl-t0-priv = {
                        cidr_offset = 3
                        ip_version = "ipv4"
                    },
                    wl-t0-pub = {
                        cidr_offset = 4
                        ip_version = "ipv4"
                    },
                    wl-edge-tep = {
                        cidr_offset = 5
                        ip_version = "ipv4"                      
                    },                
                  }
              }
            }
        }
      }
    }
}


variable "vpc_ryo" {
    description = "VPC Data Structure"
    type        = map
    default = {
      vpc = {
        zones = {
            vpc_zone = {
              infrastructure = {
                  vpc_zone_subnet_size = 3
                  public_gateways = ["subnet-public-gateway"]
                  subnets = {
                    host = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    mgmt = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                        public_gateway = "subnet-public-gateway"
                    },
                    vmot = {
                        cidr_offset = 2
                        ip_version = "ipv4"
                    },
                    vsan = {
                        cidr_offset = 3
                        ip_version = "ipv4"
                    },
                    tep = {
                        cidr_offset = 4
                        ip_version = "ipv4"
                    }
                }
              },
              edges = {
                  vpc_zone_subnet_size = 4
                  subnets = {
                    t0-priv = {
                        cidr_offset = 0
                        ip_version = "ipv4"
                    },
                    t0-pub = {
                        cidr_offset = 1
                        ip_version = "ipv4"
                    },
                  }
              }
            }
        }
      }
    }
}



### Bastion servers


variable "user_provided_ssh_keys" {
  description = "User provided 'ssh key names'. Must have been uploaded to the IBM ClLoud Region."
  default = []
  type = list
}

variable "vsi_image_architecture" {
  description = "CPU architecture for VSI deployment"
  default = "amd64"
  type = string
}

# Windows


variable "vsi_profile_bastion" {
  description = "The profile of compute CPU and memory resources to use when creating the virtual server instance. To list available profiles, run the `ibmcloud is instance-profiles` command."
  default     = "bx2-2x8"
  type = string
}

variable "vsi_image_os" {
  description = "OS for VSI deployment"
  default = "windows-2019-amd64"
  type = string
}

variable "number_of_bastion_hosts" {
  description = "Number of bastion hosts to deploy."
  default = 1
  type = number
}

# Linux

variable "vsi_profile_bastion_linux" {
  description = "The profile of compute CPU and memory resources to use when creating the virtual server instance. To list available profiles, run the `ibmcloud is instance-profiles` command."
  default     = "bx2-2x8"
  type = string
}

variable "vsi_image_os_linux" {
  description = "OS for VSI deployment"
  default = "centos-7-amd64"
  type = string
}

variable "number_of_bastion_hosts_linux" {
  description = "Number of bastion hosts to deploy."
  default = 1
  type = number
}


variable "github_token" {
  description = "GitHub token to fetch install scripts."  
  default = ""
}


variable "github_url" {
  description = "GitHub URL to fetch install scripts."
  default = ""
}



##############################################################
# VCF variables
##############################################################

### VCF deployment variables

variable "vcf_architecture" {
  description = "Defines VMware Cloud Foundation deployment architecture."
  default = "consolidated"

  validation {
    condition = (
        var.vcf_architecture == "consolidated" ||
        var.vcf_architecture == "standard"
    )
    error_message = "VMware VCF architecture optionas are 'consolidated' or 'standard'." 
  }
}

variable "vcf_password" {
  description = "Define a common password for all elements. Optional, leave empty to get random passwords."
  default = ""
  type = string
}

variable "vcf_mgmt_domain_name" {
  description = "VCF management domain name."
  default = "m01"
  type = string
}

variable "vcf_cluster_name" {
  description = "VCF cluster name."
  default = "cl01" 
  type = string
}

variable "vcf_dc_name" {
  description = "VCF data center name."
  default = "dc01" 
  type = string
}

### VCF license variables

variable "sddc_manager_license" {
  description = "VMware SDDC manager license."
  default = ""
  type = string
}

variable "nsx_t_license" {
  description = "VMware NSX-T manager license."
  default = ""  
  type = string
}

variable "vsan_license" {
  description = "VMware VSAN manager license."
  default = ""  
  type = string
}

variable "vcenter_license" {
  description = "VMware vCenter manager license."
  default = ""  
  type = string
}

variable "esx_license" {
  description = "VMware ESX manager license."
  default = ""  
  type = string
}


##############################################################
# Testing
##############################################################

variable "cos_bucket_test_key" {
  default = ""  
  type = string
}
