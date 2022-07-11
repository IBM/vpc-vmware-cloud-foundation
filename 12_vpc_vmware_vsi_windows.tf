##############################################################
# Provision a Windows server for jump, AD/DNS etc.
##############################################################



##############################################################
# Create private SSH key only for Bastion Server Use
# Name of SSH Public Key stored in IBM Cloud must be unique within the Account
##############################################################


# Public/Private key for accessing the instance

resource "tls_private_key" "bastion_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "ibm_is_ssh_key" "bastion_key" {
  count = var.deploy_bastion ? 1 : 0
  name = "${local.resources_prefix}-bastion-ssh-key"
  public_key = trimspace(tls_private_key.bastion_rsa.public_key_openssh)
}



##############################################################################
# Read/validate vsi profile
##############################################################################

data "ibm_is_instance_profile" "vsi_profile_bastion" {
  name = var.vsi_profile_bastion
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
        for image in data.ibm_is_images.os_images_bastion.images:
            image if ((image.architecture == var.vsi_image_architecture) && (image.os == var.vsi_image_os) && (image.status == "available"))
    ]
}

data "ibm_is_image" "bastion_image" {
  name = local.os_images_filtered_bastion[0].name
}

##############################################################
# Provision bastion Virtual Server
##############################################################

resource "ibm_is_instance" "bastion" {
  count = var.deploy_bastion ? var.number_of_bastion_hosts : 0

  name           = "${local.resources_prefix}-bastion-windows-${format("%02s", count.index)}"
  image          = data.ibm_is_image.bastion_image.id
  profile        = data.ibm_is_instance_profile.vsi_profile_bastion.name
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  primary_network_interface {
    name = "eth0"
    subnet = local.subnets["inst_mgmt"]["subnet_id"]
    security_groups = [ibm_is_security_group.sg["bastion"].id, ibm_is_security_group.sg["mgmt"].id]
  }
 
  vpc  = module.vpc-subnets[var.vpc_name].vmware_vpc.id
  zone = var.vpc_zone
  keys = [ibm_is_ssh_key.bastion_key[0].id]
  
  user_data      = templatefile("scripts/bastion_windows_userdata.tpl", { dns_suffix_list = var.dns_root_domain })

  depends_on = [
    module.security_group_rules
  ]
}


##############################################################
# Get bastion Virtual Server data for decrypting password 
##############################################################


data "ibm_is_instance" "bastion" {
  count = var.deploy_bastion ? var.number_of_bastion_hosts : 0
  name = var.deploy_bastion ? ibm_is_instance.bastion[count.index].name : ""
  private_key = tls_private_key.bastion_rsa.private_key_pem
}


##############################################################
# Attach Floating IP to Bastion Virtual Server
##############################################################

resource "ibm_is_floating_ip" "bastion_floating_ip" {
  count = var.deploy_bastion ? var.number_of_bastion_hosts : 0

  name           = "${local.resources_prefix}-bastion-windows-floating-ip-${format("%02s", count.index)}"
  target         = ibm_is_instance.bastion[count.index].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group_vmw.id
}


##############################################################
# Define Bastion output maps
##############################################################

/* to be deleted

locals {
  bastion = {
    private_ip_address = var.deploy_bastion ? ibm_is_instance.bastion[0].primary_network_interface[0].primary_ip[0].address : "0.0.0.0"
    public_ip_address = var.deploy_bastion ? ibm_is_floating_ip.bastion_floating_ip[0].address : "0.0.0.0"
    username = "Administrator"
    password = var.deploy_bastion ? data.ibm_is_instance.bastion[0].password : ""
  }
}
*/

locals {
  bastion_hosts = [
    for bastion_host in range(var.number_of_bastion_hosts) : {
      name = var.deploy_bastion ? ibm_is_instance.bastion[bastion_host].name : "0.0.0.0"
      private_ip_address = var.deploy_bastion ? ibm_is_instance.bastion[bastion_host].primary_network_interface[0].primary_ip[0].address : "0.0.0.0"
      public_ip_address = var.deploy_bastion ? ibm_is_floating_ip.bastion_floating_ip[bastion_host].address : "0.0.0.0"
      username = "Administrator"
      password = var.deploy_bastion ? data.ibm_is_instance.bastion[bastion_host].password : ""
    }
  ]
}
