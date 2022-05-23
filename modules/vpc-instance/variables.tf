variable "vmw_instance_name" {
  description = "Name of the Instance"
  type        = string
}

variable "vmw_instance_vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vmw_instance_location" {
  description = "Instance zone"
  type        = string
}

variable "vmw_instance_image" {
  description = "Image ID for the instance"
  type        = string
}

variable "vmw_instance_profile" {
  description = "Profile type for the Instance"
  type        = string
}

# variable "vmw_instance_ssh_keys" {
#   description = "List of ssh key IDs the instance"
#   type        = list(string)
# }
variable "vmw_instance_ssh_keys" {
  description = "List of ssh key IDs the instance"
  type        = string
}

variable "vmw_instance_ssh_private_key" {
  
}

# variable "vmw_instance_primary_network_interface" {
#   description = "List of primary_network_interface that are to be attached to the instance"
#   type = list(object({
#     subnet               = string
#     interface_name       = string
#     security_groups      = list(string)
#     primary_ipv4_address = string
#   }))
# }
variable "vmw_instance_resources_prefix" {
  
}
variable "vmw_instance_vmw_subnet_inst_mgmt_id" {
  
}
variable "vmw_instance_vmw_sg_mgmt" {
  
}

#####################################################
# Optional Parameters
#####################################################

variable "vmw_instance_no_of_instances" {
  description = "number of Instances"
  type        = number
  default     = 1
}

variable "vmw_instance_resource_group_id" {
  description = "Resource group ID"
  type        = string
  default     = null
}

variable "vmw_instance_user_data" {
  description = "User Data for the instance"
  type        = string
  default     = null
}

variable "vmw_instance_data_volumes" {
  description = "List of volume ids that are to be attached to the instance"
  type        = list(string)
  default     = []
}

variable "vmw_instance_tags" {
  description = "List of Tags for the Instance"
  type        = list(string)
  default     = null
}

variable "vmw_instance_network_interfaces" {
  description = "List of network_interfaces that are to be attached to the instance"
  type = list(object({
    subnet               = string
    interface_name       = string
    security_groups      = list(string)
    primary_ipv4_address = string
  }))
  default = []
}

variable "vmw_instance_boot_volume" {
  description = "List of boot volume that are to be attached to the instance"
  type = list(object({
    name       = string
    encryption = string
  }))
  default = []
}

## VC VARIABLES

variable "vmw_instance_vcenter_esx_hostname_fqdn" {
  
}
variable "vmw_instance_vcenter_esx_pwd" {
  
}
variable "vmw_instance_domain" {
  
}
variable "vmw_instance_vcenter_ip" {
  
}
variable "vmw_instance_network_cidrprefix" {
  
}
variable "vmw_instance_network_gateway" {
  
}
variable "vmw_instance_vcenter_pwd" {
  
}
