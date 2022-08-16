# Deploying IUBM Cloud for VMware Cloud Foundation with terraform

VMware Cloud Foundation™ (VCF) provides a ubiquitous hybrid cloud platform for both traditional enterprise apps and modern apps. The IBM Cloud VPC provides the underlying infrastructure for running VCF in IBM Cloud. The architecture for the VMware Cloud Foundation™ in IBM Cloud VPC  is explained in [IBM Cloud Docs](https://cloud.ibm.com/docs/vmwaresolutions?topic=vmwaresolutions-vpc-vcf-overview).

The IBM Cloud bare metal server is integrated with the VPC network, and you can take advantage of the network, storage, and security capabilities provided by IBM Cloud VPC. Use VMware vSAN™ for storage and VMware NSX-T™ for network capabilities. You can easily and quickly add and remove ESXi hosts. Also, add, configure, and remove VMware vSphere® clusters as you like. If your storage needs grow, you can add and attach IBM Cloud VPC file shares. For more information on Bare Metal Servers on VPC and VMware solution on VPC architecture, see [About Bare Metal Servers for VPC](https://cloud.ibm.com/docs/vpc?topic=vpc-about-bare-metal-servers&interface=ui).

This repository includes terraform templetes to deploy VPC assets following [VMware Cloud Foundation (VCF)](https://docs.vmware.com/en/VMware-Cloud-Foundation/index.html) architecture in IBM Cloud. You can run this terraform through [IBM Cloud Schematics](https://cloud.ibm.com/docs/schematics?topic=schematics-workspace-setup&interface=ui) or using terraform locally. After the bare metal server provisioning and initial VMware configurations, you can access and manage the environment through the bastion hosts and download the VMware Cloud Builder from [https://customerconnect.vmware.com](https://customerconnect.vmware.com), deploy the OVA, and start the Cloud Builder bringup process. To do this step, you can use VMware clients, command line interface (CLI), existing scripts, or other familiar vSphere API-compatible tools.

![VCF Architecture](images/arch-vcf.png)

For the required common services, such as NTP and DNS, IBM Cloud VPC services and solutions are used. For Active Directory™, you can use IBM Cloud VPC compute resources to build your Active Directory in IBM Cloud VPC, or interconnect with your existing Active Directory infrastructure after the initial deployment is completed.

For connectivity needs, you can use IBM Cloud VPC and IBM Cloud interconnectivity solutions. For public internet network access capabilities, the options include floating IP addresses and Public Gateway configurations within your VPC. VPC routes are used to route traffic to NSX-T overlay through Tier 0 Gateway. On-premises connectivity over public internet can be arranged by using IBM Cloud VPC VPN services (site-to-site and client-to-site), or alternatively NSX-T built-in VPN capabilities. For private networking, you can use IBM Cloud interconnectivity services to connect your VMware workloads with IBM Cloud classic infrastructure, other VPCs, and on-premises networks.


## Compatibility

- Terraform 1.1 and above.
- IBM Cloud Terraform provider 1.44.0 and above

## Install

### Install using terraform through Schematics

You can run this terraform through [Schematics](https://cloud.ibm.com/docs/schematics?topic=schematics-workspace-setup&interface=ui). Create a workspace on Schematics and import this terraform template. See more in a [helper sheet](IBM_CLOUD_SCHEMATICS.md).


### Install using terraform locally

Be sure you have the correct Terraform version, you can choose the binary here for your operating system:

- https://releases.hashicorp.com/terraform/

Be sure that you have access to the IBM Cloud terraform provider plugins through Internet or that you have downloaded and compiled the plugins for your operating system on $HOME/.terraform.d/plugins/

- [terraform-provider-ibm](https://github.com/IBM-Cloud/terraform-provider-ibm)

### Terraform outputs

The terraform provides the following output values for deployed assets and randomly generated values:

```bash
vpc_bastion_hosts                       # Provides bastion host acccess details 
ssh_private_key_bastion                 # Provides genererated SSH private key for bastion hosts 
ssh_private_key_host                    # Provides genererated SSH private key for ESXi hosts

dns_records                             # Provides deployed DNS records
dns_root_domain                         # Used DNS root domain
dns_servers                             # Used DNS server IP addresses
ntp_server                              # Used NTP server IP addresses

resource_group_id                       # Used resource group's id
resources_prefix                        # Used random resources prefix

zone_subnets                            # Provisioned VPC subnets

vcf                                     # Provisioned VLAN interface details and other values for VCF Cloud Builder and SDDC Manager
vcf_bringup_json                        # VCF Cloud Builder bringup json

cluster_hosts                           # Provisioned ESXi host details and their VLAN interfaces per cluster

vcenters                                # Provisioned ESXi host details and their VLAN interfaces per cluster

nsx_t_managers                          # Provisioned VLAN interface details and other values for NSX-T Managers
nsx_t_edges                             # Provisioned VLAN interface details and other values for NSX-T Edge Nodes
nsx_t_t0s                               # Provisioned VLAN interface details and other values for NSX-T T0 Gateways 

vcf_network_pools                       # Provisioned vcf_network_pools details
vcf_vlan_nics                           # Provisioned VLAN interface details for vcf_network_pools

routes_default_egress_per_zone          # Provisioned VPC egress routes for overlay networks
routes_tgw_dl_ingress_egress_per_zone   # Provisioned VPC ingress routes for overlay networks
```

*Please Note*: When you deploy this through Schematics, you can use this [helper sheet](IBM_CLOUD_SCHEMATICS.md) to get the required output values.


## Running this template

### IBM Cloud API key

The *ibmcloud_api_key* terraform variable must be generated prior to running this template. Please refer to [IBM Cloud API Key](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-creating-cloud-api-key). 

You can create an environmental variable for the API key, for example:

```bash
export TF_VAR_ibmcloud_api_key=<put_your_key_here>
```


### Deployment location

The following variables dictate the location of the deployent.

```hcl
variable "ibmcloud_vpc_region" {
  description = "Enter the target Region of IBM Cloud"
  default = "eu-de"
}

variable "vpc_zone" {
  description = "VPC Zone"
  default     = "eu-de-1"
}
```

*Please Note:* Currently, Bare Metal Servers for VPC are supported in Frankfurt (eu-de), Dallas (us-south) and Washington DC (us-east) only. Check the latest availability information per region in [IBM Cloud Docs](https://cloud.ibm.com/docs/vpc?topic=vpc-bare-metal-servers-profile&interface=ui#bare-metal-profile-availability-by-region). 

### Resource creation

Resources created by this template are based on the *resource_prefix* and a random number assigned at execution.

The *resource_prefix* should be changed for each new deployment:

```hcl
variable "resource_prefix" {
  description = "Resource Group Prefix to create in the IBM Cloud account"
  default = "vmw"
}
```

The calculated resource prefix that is actually used in resource created is defined as follows:

```hcl
resource "random_string" "resource_code" {
  length  = 3
  special = false
  upper   = false
}

locals {
  resources_prefix = "${var.resource_prefix}-${random_string.resource_code.result}"
}
```

The terraform will use tag for each created resource supporting tags. The tag consists of a instance or deployment specific tag and a list of customer configurable common tags specified in a variable.

```hcl
variable "tags" {
  description = "Tag to define environment"
  default = []
}
```

If needed, you can customize tag generation with a local variable `local.resource_tags.<resource>` in `00_vpc_vmware_esxi_random_tagging.tf`.

```hcl
locals {
  resource_tags = {
    ssh_key             = concat(["vmware:${local.resources_prefix}"], var.tags)
    vpc                 = concat(["vmware:${local.resources_prefix}"], var.tags)
    subnets             = concat(["vmware:${local.resources_prefix}"], var.tags)
    public_gateway      = concat(["vmware:${local.resources_prefix}"], var.tags)
    security_group      = concat(["vmware:${local.resources_prefix}"], var.tags)
    bms_esx             = concat(["vmware:${local.resources_prefix}"], var.tags, ["esx"])
    vsi_bastion         = concat(["vmware:${local.resources_prefix}"], var.tags, ["bastion"])
    dns_services        = concat(["vmware:${local.resources_prefix}"], var.tags)
    floating_ip_t0      = concat(["vmware:${local.resources_prefix}"], var.tags, ["tier0-gateway"])
    floating_ip_bastion = concat(["vmware:${local.resources_prefix}"], var.tags, ["bastion"])
  }
}
```


### Deployment customization

The following variables dictate the boolean inclusion of certain optional features.

```hcl
variable "deploy_iam" {
  description = "Boolean to enable IAM deployment."
  default = true
}

variable "deploy_fileshare" {
  description = "Boolean to enable fileshare deployment. Alternatively customize the cluster map."
  default = false
}

variable "deploy_dns" {
  description = "Boolean to enable DNS service deployment."
  default = true
}

variable "enable_vcf_mode" {
  description = "Boolean to enable VCF options for BMS deployment (dual PCI uplinks and vmk1 in instance management subnet)."
  default = true
}

```

*Please Note:* The inclusion of file share is not yet available on the public version of the IBM Cloud VPC Terraform provider. Please set to false.

### VPC network architecture

The terraform deploys the network infrastucture as described in the [reference architecture for VMware deployment in VPC](https://cloud.ibm.com/docs/vmwaresolutions?topic=vmwaresolutions-vpc-ryo-vpc-vmw). The `vpc_zone_prefix` and `vpc_zone_prefix_t0_uplinks` variables describe the prefixes used for *infrastucture and NSX-T T0 uplink subnets*.

```hcl
variable "vpc_zone_prefix" {
  description = "This is the address prefix for VMware components for each zone. /22 is recommended for appx. 120 hosts, /23 for appx. 60 hosts etc."
  default  = "10.100.0.0/22"
}

variable "vpc_zone_prefix_t0_uplinks" {
  description = "This is the NSX-T uplink address prefix for each zone."
  default  = "192.168.10.0/24"
}
```

`xyz_vlan_id` variables define the VLAN IDs used with BMS VLAN interfaces for `vmks`, SDDC appliances or NSX-T Tier 0 Gateway uplinks. Note that these VLAN IDs have only local significance to the BMS and ESXi host. The following lists the default values for VLAN ID variables used in the `consolidated architecture`.

```hcl
variable "host_vlan_id" {
  description = "VLAN ID for host network"
  default     = 0 
}

variable "mgmt_vlan_id" {
  description = "VLAN ID for management network"
  # default     = 100 ## IBM Cloud ref arch
  default     = 1611 ## VCF default
}

variable "vmot_vlan_id" {
  description = "VLAN ID for vMotion network"
  # default     = 200 ## IBM Cloud ref arch
  default     = 1612 ## VCF default
}

variable "vsan_vlan_id" {
  description = "VLAN ID for vSAN network"
  # default     = 300 ## IBM Cloud ref arch
  default     = 1613 ## VCF default
}

variable "tep_vlan_id" {
  description = "VLAN ID for TEP network"
  # default     = 400 ## IBM Cloud ref arch
  default     = 1614 ## VCF default
}

variable "edge_uplink_public_vlan_id" {
  description = "VLAN ID for T0 public uplink network"
  # default     = 700 ## IBM Cloud ref arch
  default     = 2711 ## VCF default
}

variable "edge_uplink_private_vlan_id" {
  description = "VLAN ID for T0 private uplink network"
  # default     = 710 ## IBM Cloud ref arch
  default     = 2712 ## VCF default
}

variable "edge_tep_vlan_id" {
  description = "VLAN ID for TEP network" ## not used in IBM Cloud ref arch
  default     = 2713 ## VCF default
}
```

The variables `vpc_vcf_consolidated` and `vpc_vcf_standard` define the structure of the VPC, and *subnets* to be created using the created *VPC prefixes*. The terraform creates the subnets with the subnet size as defined in the variable (e.g. `vpc_zone_subnet_size = 3` for a `/22` prefix means a subnet mask `/25` and likewise a `4` for a `/24` prefix means a subnet mask `/28`). The following shows an example for a VPC structure for `consolidated architecture` deployment.

```hcl
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
```

### Deployment architecture

The `zone_clusters` variable describes the architecture of the deployment, including the *clusters*, *hosts* and *file shares*.

In this example we will deploy a single cluster with a single host of profile *bx2d-metal-96x384*. We can increase the number of hosts or clusters by manipulating this variable.

```hcl
variable "zone_clusters" {
  description = "Clusters in VPC"
  type        = map

  default     = {
    cluster_0 = {              # Value must "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"          # Value must "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 4           # Define a host count for this cluster.
      vcenter = true           # Value must "true" for the first cluster
      nsx_t_managers = true    # Value must "true" for the first cluster
      nsx_t_edges = true       # Value must "true" for the first cluster
      public_ips = 2           # Orders # of Floating IPs for the T0. 
      overlay_networks = [     # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []     # Future use.
    },
  }
}
```

*Please Note:* Provisioning VPC file shares is not yet available in the public version of IBM Cloud terraform plugin.

The ESXI image type is the same across all Bare Metal servers and is described as follows:

```hcl
variable "esxi_image" {
  description = "Base ESXI image name, terraform will find the latest available image id"
  default = "esxi-7-byol"
}
```

You can optionally name a specific image with:

```hcl
variable "esxi_image_name" {
  description = "Use a specific ESXI image version to use for the hosts to override the latest by name."
  default = "ibm-esxi-7-0u3d-19482537-byol-amd64-1"
  type = string
}
```

You can use either bring your own lisence and use byol image (`ibm-esxi-7-byol`) or you can use IBM Cloud provided ESXi lisences (`ibm-esxi-7-byol`) which are montly billed. Terraform will find the latest available ESXi version based on the selected image type.

In order to determine the available image types, run the following IBM Cloud console command:

```bash
> ibmcloud is images | grep esx

r006-a40de20b-f936-454b-94de-395a2f4cf940   ibm-esxi-7-amd64-4                                 available    amd64   esxi-7                               7.x                                         1               public       provider     none         -   
r006-199c5cfc-a692-4682-a3c6-a81cfafd3755   ibm-esxi-7-byol-amd64-4                            available    amd64   esxi-7-byol                          7.x                                         1               public       provider     none         -   
r006-2d1f36b0-df65-4570-82eb-df7ae5f778b1   ibm-esxi-7-amd64-1                                 deprecated   amd64   esxi-7                               7.x                                         1               public       provider     none         -   
r006-95325076-0a3a-4e2e-8678-56908ddfcea0   ibm-esxi-7-byol-amd64-1                            deprecated   amd64   esxi-7-byol                          7.x                                         1               public       provider     none         -   

```

The key *vmw_host_profile* represents the host profile and may be customised for each cluster. Available profiles and values may be determined fromt the IBM Cloud console or with CLI:

```bash
>  ibmcloud is bm-prs 
Listing bare metal server profiles in region us-south under account IBM - IC4VS - Architecture as user ...
Name                 Architecture   Family     CPU socket count   CPU core count   Memory(GiB)   Network(Mbps)   Storage(GB)   
bx2-metal-96x384     amd64          balanced   2                  48               384           100000          1x960   
bx2d-metal-96x384    amd64          balanced   2                  48               384           100000          1x960, 8x3200   
bx2-metal-192x768    amd64          balanced   4                  96               768           100000          1x960   
bx2d-metal-192x768   amd64          balanced   4                  96               768           100000          1x960, 16x3200   
cx2-metal-96x192     amd64          compute    2                  48               192           100000          1x960   
cx2d-metal-96x192    amd64          compute    2                  48               192           100000          1x960, 8x3200   
mx2-metal-96x768     amd64          memory     2                  48               768           100000          1x960   
mx2d-metal-96x768    amd64          memory     2                  48               768           100000          1x960, 8x3200   
```

*Please Note:* Use the profiles ending with d, for example bx2d or cx2d for hosts with local SSDs for vSAN.

### VPC routing tables and routes

The terraform template uses the [default routing table](https://cloud.ibm.com/docs/vpc?topic=vpc-about-custom-routes) for `egress routing` and it will create an additional routing table for `ingress routing` to enable routing with [Transit Gateway](https://cloud.ibm.com/docs/transit-gateway?topic=transit-gateway-getting-started) and [Direct Link](https://cloud.ibm.com/docs/dl?topic=dl-get-started-with-ibm-cloud-dl) with VPC routes and NSX-T overlay.

You can add your own routes with the `zone_clusters` variable:

```hcl
      overlay_networks = [     # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
```

This terraform template uses this map to create both `egress` and `ingress` VPC routes with the `NSX-T T0 HA VIP` as the next-hop. In this example, the VPC routes are created automatically for each `zone` to provide an easy way to add connectivity though routes in and out of your VPC.  

*Please Note:* IBM Cloud® Virtual Private Cloud (VPC) automatically generates a default routing table for the VPC to manage traffic in the `zone`. By default, this routing table is empty. You can add routes to the default routing table, or create one or more custom routing tables and then add routes to it. For example, if you want a specialized routing policy for a specific subnet, you can create a routing table and associate it with one or more subnets. Routes are also always specific to a `zone`.

*Please Note:* When VPC is attached to Transit Gateway or Direct link, it currently only advertises VPC prefixes. For example, individual VPC subnets nor VPC routes are not currently advertised. For routing to work properly, you first need to create VPC ingress routes for each NSX-T overlay network prefix (or preferably summarize/aggregate the NSX-T networks). Currently, you also need to create a prefix in the zone to enable advertising VPC ingress routes towards Transit Gateway and Direct Link. 

*Please Note:* This terraform creates a VPC prefix for each NSX-T overlay route automatically to simplify the process, but at the same time sacrificing scalability. When adding multiple routes, please consider aggregating routing information in VPC. See the [VPC quotas and service limits](https://cloud.ibm.com/docs/vpc?topic=vpc-quotas#vpc-quotas) for VPC prefixes and routes.


### Security groups

The terraform template will create a variable number of security groups, the default set is provided below. These groups should not be removed, however, it is possible to add custom groups to for example open a port from a Bastion Server to the Bare Metal hosts.

```hcl

variable "security_group_rules" {

    description = "Security groups and rules rules to create"
    #type        = map
    default = {
        "mgmt" = [
          {
            name      = "allow-all-mgmt"
            direction = "inbound"
            remote_id = "mgmt"
          },
          {
            name      = "allow-inbound-10-8"
            direction = "inbound"
            remote    = "10.0.0.0/8"
          },
          {
            name      = "allow-inbound-t0-uplink"
            direction = "inbound"
            remote_id = "uplink-priv"
          },
          {
            name      = "allow-outbound-any"
            direction = "outbound"
            remote    = "0.0.0.0/0"
          }
        ],
        "vmot" = [
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
        "vsan" = [
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
        "tep" = [
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
        "uplink-pub" = [
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
        "uplink-priv" = [
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
        "bastion" = [
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
```

### DNS Service

The terraform template will optionally provision IBM Cloud DNS service. it will create the zone for the DNS root domain (for example `vcf.ibmcloud.local`) as defined in the following variable.

```hcl
variable "dns_root_domain" {
  description = "Root Domain of Private DNS used with the Virtual Server"
  default = "vcf.ibmcloud.local"
}
```

Then the terraform will create the following A-records and related PTR-records:

* vCenter Server : `vcenter`
* NSX-T Manager 0 : `nsx-t-0`
* NSX-T Manager 1 : `nsx-t-1`
* NSX-T Manager 2 : `nsx-t-2`
* NSX-T Manager VIP : `nsx-t-vip`
* NSX-T Edge 0 : `edge-0`
* NSX-T Edge 1 : `edge-1`

Each entry in the above list will use the created Bare Metal Server VLAN interface IP as the target. 

In VCF deployment option, in addition to the list above, the following A-records and related PTR-records are created:

* Cloud Builder : `cloud-builder`
* SDDC Manager : `sddc-manager`

Each entry in the above list will use the created Bare Metal Server VLAN interface IP as the target. 

In VCF deployment option, you can optionally define additional DNS entries (for example VCF assets running on the AVN overlay networks) 

```hcl
variable "dns_records" {
  description = "DNS records to create."
  default = [
    {
      name = "xint-vrslcm01"
      ip_address = "172.27.17.20"
    },
  ]
```

The above example map would create the following A-record and the related PTR-record for the specified IP address:

* vRealize Suite Lifecycle Manager : `xint-vrslcm01`


## VCF bring-up json

The terraform creates a json file for initial bringup. This file can be passed to VCF Cloud Builder.

Template file location:
```
TEMPLATE/vcf-ibm-ems-template_json.tpl
```

Output file location:
```
OUTPUT/vcf-<resource_prefix>-ibm-ems-bringup.json
```

Json file content is also output on a output called `vcf_bringup_json`. 

Note. Each IBM Cloud bare metal server for VPC has a random password provided by IBM Cloud and are encrypted with the provided SSH key. The passwords are decrypted by the terraform and passed to created json file   

## Logical Template Flow

The terraform file names have been named to indicate the logical order of the resource creation and to group resource types into a single file, this has been done for convenience only.

```
00_vpc_vmware_esxi_random_tagging.tf
01_vpc_vmware_esxi_iam.tf
02_vpc_vmware_esxi_rg.tf
03_vpc_vmware_esxi_vpc.tf
04_vpc_vmware_esxi_dns_service.tf
05_vpc_vmware_esxi_ssh_key.tf
06_vpc_vmware_esxi_bare_metal.tf
07_vpc_vmware_esxi_vcenter.tf
08_vpc_vmware_esxi_nsxt.tf
10_vpc_vmware_esxi_dns_records.tf
11_vpc_vmware_vcf_appliances.tf
12_vpc_vmware_vcf_net_pools.tf
13_vpc_vmware_bastion_hosts.tf
14_vpc_vmware_routes.tf
15_vpc_vmware_routes_show.tf
90_vpc_vmware_vcf_json.tf
99_vpc_vmware_output.tf
```


## Example terraform.tfvars for VCF deployment

### Consolidated architecture deployment

When deploying `consolidated architecture` deployment, see the `terraform.tfvars.vcf-consolidated` for example variable values.

The key variables for `consolidated architecture` deployment are listed below: 

```hcl
# Define vcf deployment architecture option (valid only for VCF deployments when 'enable_vcf_mode=true')

vcf_architecture = "consolidated" # Deploys a 'consolidated' VCF deployment.

# Define en estimate of a number of hosts per domain

vcf_mgmt_host_pool_size = 8    # Creates VPC BMS VLAN interfaces for a pool for N hosts total for mgmt domain

# Define deployment structure

zone_clusters = {
    cluster_0 = {              # Value must "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"          # Value must "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 4           # Define a host count for this cluster.
      vcenter = true           # Value must "true" for the first cluster
      nsx_t_managers = true    # Value must "true" for the first cluster
      nsx_t_edges = true       # Value must "true" for the first cluster
      public_ips = 2           # Orders # of Floating IPs for the T0. 
      overlay_networks = [     # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []     # Future use.
    },   
  }


# Note. 'overlay_networks' list creates VPC egress and ingress routes with a T0 HA VIP as the next-hop. 
# You must manually configure routing in T0 with static routes.  
```

The following shows an example with two clusters on `consolidated architecture` deployment. You can optionally deploy NSX-T edge nodes on the 2nd cluster.

```hcl
# Example with two clusters on consolidated architecture. You can optionally deploy NSX-T edge nodes on the 2nd cluster.

zone_clusters = {
    cluster_0 = {              # value must "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"          # value must "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 4           # Define a host count for this cluster.
      vcenter = true           # value must "true" for the first cluster
      nsx_t_managers = true    # value must "true" for the first cluster
      nsx_t_edges = true       # value must "true" for the first cluster
      public_ips = 2           
      overlay_networks = [
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []
    },   
    cluster_1 = {
      name = "mgmt-cl-1"
      domain = "mgmt"         
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 1          # Define a host count for this cluster.
      vcenter = false         # Value must "false" for the 2nd cluster in the management domain.   
      nsx_t_managers = false  # Value must "false" for the 2nd cluster in the management domain.   
      nsx_t_edges = false     # You can optionally deploy a new edge cluster.
      public_ips = 0          # You can optionally order public IPs, if you selected nsx-t edges on this cluster. 
      overlay_networks = [    # You can optionally add routes to overlay, if you selected nsx-t edges on this cluster. 
        ]
      vpc_file_shares = []
    },

# Note. 'overlay_networks' list creates VPC egress and ingress routes with a T0 HA VIP as the next-hop. 
# You must manually configure routing in T0 with static routes. 
```

### Standard architecture deployment

When deploying `standard architecture` deployment, see the `terraform.tfvars.vcf-standard` for example variable values.

The key variables for `standard architecture` deployment are listed below: 

```hcl
# Define vcf deployment architecture option (valid only for VCF deployments when 'enable_vcf_mode=true')

vcf_architecture = "standard"    # Deploys a 'standard' VCF deployment.

# Define en estimate of a number of hosts per domain

vcf_mgmt_host_pool_size = 8    # Creates VPC BMS VLAN interfaces for a pool for N hosts total for mgmt domain
vcf_wl_host_pool_size = 10     # Creates VPC BMS VLAN interfaces for a pool for N hosts total for workload domain

# Define deployment structure

zone_clusters = {
    cluster_0 = {              # Value must "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"          # Value must "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 4
      vcenter = true           # Value must "true" for the first cluster
      nsx_t_managers = true    # Value must "true" for the first cluster
      nsx_t_edges = true       # Value must "true" for the first cluster
      public_ips = 2           # Orders # of Floating IPs for the T0. 
      overlay_networks = [     # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []     # Future use.
    },   
    cluster_1 = {
      name = "vi-wl-1"
      domain = "workload"     # Value must be set as 'workload' for the workload domain.     
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 3          # Define a host count for this cluster.
      vcenter = true          # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      nsx_t_managers = true   # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      nsx_t_edges = true      # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      public_ips = 3          # Orders # of Floating IPs for the T0. 
      overlay_networks = [    # Add networks to be routed on the overlay for the T0 on workload overlay though the T0 on this domain/cluster. 
          { name = "customer-overlay", destination = "172.17.0.0/16" },
        ]
      vpc_file_shares = []    # Future use.
    },
  }

# Note. 'overlay_networks' list creates VPC egress and ingress routes with a T0 HA VIP as the next-hop. 
# You must manually configure routing in T0 with static routes.  
```

The following shows an example with two clusters on the VI workload domaain in the `standard architecture` deployment.


```hcl
# Define deployment structure

zone_clusters = {
    cluster_0 = {              # Value must "cluster_0" for the first cluster
      name = "mgmt"          
      domain = "mgmt"          # Value must "mgmt" for the first cluster
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 4
      vcenter = true           # Value must "true" for the first cluster
      nsx_t_managers = true    # Value must "true" for the first cluster
      nsx_t_edges = true       # Value must "true" for the first cluster
      public_ips = 2           # Orders # of Floating IPs for the T0. 
      overlay_networks = [     # Add networks to be routed on the overlay for the T0 on mgmt domain/cluster. 
          { name = "customer-overlay", destination = "172.16.0.0/16" },
          { name = "vcf-avn-local-network", destination = "172.27.16.0/24" },
          { name = "avn-x-region-network", destination = "172.27.17.0/24" },
        ]
      vpc_file_shares = []     # Future use.
    },   
    cluster_1 = {
      name = "vi-wl-1"
      domain = "workload"     # Value must be set as 'workload' for the workload domain.     
      vmw_host_profile = "bx2d-metal-96x384"
      host_count = 3          # Define a host count for this cluster.
      vcenter = true          # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      nsx_t_managers = true   # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      nsx_t_edges = true      # Value must "true" for the first vi-workload cluster. Deploys VLAN interfaces on the mgmt domain. 
      public_ips = 3          # Orders # of Floating IPs for the T0. 
      overlay_networks = [    # Add networks to be routed on the overlay for the T0 on workload overlay though the T0 on this domain/cluster. 
          { name = "customer-overlay", destination = "172.17.0.0/16" },
        ]
      vpc_file_shares = []    # Future use.
    },
    cluster_1 = {
      name = "vi-wl-2"
      domain = "workload"     # Value must be set as 'workload' for the workload domain.     
      vmw_host_profile = "cx2d-metal-96x192"
      host_count = 3          # Define a host count for this cluster.
      vcenter = false         # Value must "false" for the 2nd cluster in the vi-workload domain. 
      nsx_t_managers = false  # Value must "false" for the 2nd cluster in the vi-workload domain.
      nsx_t_edges = false     # You can optionally deploy a new edge cluster.
      public_ips = 0          # You can optionally order public IPs, if you selected nsx-t edges on this cluster. 
      overlay_networks = [    # You can optionally add routes to overlay, if you selected nsx-t edges on this cluster. 
        ]
      vpc_file_shares = []    # Future use.
    },
  }

# Note. 'overlay_networks' list creates VPC egress and ingress routes with a T0 HA VIP as the next-hop. 
# You must manually configure routing in T0 with static routes.  
```