##############################################################
# Provision a Windows server for jump, AD/DNS etc.
##############################################################


##############################################################################
# vsi_profile - The profile of compute CPU and memory resources to use when 
# creating the virtual server instance.
##############################################################################
variable "vsi_profile_bastion" {
  default     = "bx2-2x8"
  description = "The profile of compute CPU and memory resources to use when creating the virtual server instance. To list available profiles, run the `ibmcloud is instance-profiles` command."
}



#####################################################################################################
# environment - The logical environment we are deploying to, either dev, stg or prod.
######################################################################################################

variable "vsi_image_architecture" {
  description = "CPU architecture for VSI deployment"
  default = "amd64"
}

variable "vsi_image_os" {
  description = "OS for VSI deployment"
  default = "windows-2019-amd64"
}



##############################################################
# Create private SSH key only for Bastion Server Use
# Name of SSH Public Key stored in IBM Cloud must be unique within the Account
##############################################################

resource "ibm_is_ssh_key" "bastion_key" {
     name = "${local.resources_prefix}-bastion-ssh-key"
     public_key = trimspace(tls_private_key.bastion_rsa.public_key_openssh)
}

# Public/Private key for accessing the instance

resource "tls_private_key" "bastion_rsa" {
  algorithm = "RSA"
}

##############################################################################
# Read/validate vsi profile
##############################################################################

data "ibm_is_instance_profile" "vsi_profile_bastion" {
  name = var.vsi_profile_bastion
}


##############################################################
# Create Security Group for Bastion Host
##############################################################

# Security Group for Bastion/Jump Host - Allow Connection from remote (i.e. Public Internet)
resource "ibm_is_security_group" "vpc_security_group_bastion" {
  name           = "${local.resources_prefix}-bastion-sg"
  vpc            = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  resource_group = data.ibm_resource_group.resource_group_vmw.id
}

# Security Group Rule for bastion Host - Allow Inbound SSH Port 22 connection from remote (i.e. Public Internet)

resource "ibm_is_security_group_rule" "vpc_security_group_bastion_inbound_rdp" {
  depends_on = [ibm_is_security_group.vpc_security_group_bastion]
  group     = ibm_is_security_group.vpc_security_group_bastion.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 3389
    port_max = 3389
  }
}

/*
resource "ibm_is_security_group_rule" "vpc_security_group_bastion_inbound_winrm" {
  depends_on = [ibm_is_security_group.vpc_security_group_bastion]
  group     = ibm_is_security_group.vpc_security_group_bastion.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 5985
    port_max = 5986
  }
}
*/

# Allow Outbound connection
resource "ibm_is_security_group_rule" "vpc_security_group_bastion_outbound_all" {
  depends_on = [ibm_is_security_group.vpc_security_group_bastion]
  group     = ibm_is_security_group.vpc_security_group_bastion.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

##############################################################
# Calculate the most recently available OS Image Name for the 
# OS Provided
##############################################################

data "ibm_is_images"  "os_images_bastion" {

    visibility = "public"
}

locals {

    os_images_filtered_bastion = [
        for image in data.ibm_is_images.os_images.images:
            image if ((image.architecture == var.vsi_image_architecture) && (image.os == var.vsi_image_os) && (image.status == "available"))
    ]
}

data "ibm_is_image" "bastion_image" {
  name = local.os_images_filtered[0].name
}

##############################################################
# Provision bastion VSI
##############################################################

resource "ibm_is_instance" "bastion" {
  depends_on = [ibm_is_security_group_rule.vpc_security_group_bastion_outbound_all]
  name           = "${local.resources_prefix}-bastion-windows"
  image          = data.ibm_is_image.bastion_image.id
  profile        = data.ibm_is_instance_profile.vsi_profile_bastion.name
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  primary_network_interface {
    name = "eth0"
    subnet = local.subnets["inst_mgmt"]["subnet_id"]
    security_groups = [ibm_is_security_group.vpc_security_group_bastion.id, ibm_is_security_group.sg["mgmt"].id]
  }
 
  vpc  = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  zone = var.vpc_zone
  keys = [ibm_is_ssh_key.bastion_key.id]
  user_data = file("${path.root}/bastion_windows_userdata")
}


data "ibm_is_instance" "bastion" {
  name = ibm_is_instance.bastion.name
}


##############################################################
# Attach Floating IP to bastion Host Virtual Server on Gen 2
# Enables the Internet to initiate a connection directly with the instance
##############################################################

# Create Floating IP on public internet for the bastion Host Virtual Server Instance
resource "ibm_is_floating_ip" "bastion_floating_ip" {
  name           = "${local.resources_prefix}-bastion-windows-floating-ip"
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group_vmw.id
}

locals { 
  vpc_bastion_password  = rsadecrypt(data.ibm_is_instance.bastion.password, tls_private_key.bastion_rsa.private_key_pem)
  vpc_bastion_public_ip = ibm_is_floating_ip.bastion_floating_ip.address
}

##############################################################
# Define Outputs
##############################################################


output "vpc_bastion_password" {
  value = local.vpc_bastion_password
  sensitive = false
}

output "vpc_bastion_public_ip" {
  value = local.vpc_bastion_public_ip
}
