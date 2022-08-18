##############################################################################
# Provision a Windows and/or a Linux server for jump, AD/DNS etc.
##############################################################################


##############################################################################
# Read/validate vsi profile
##############################################################################

data "ibm_is_instance_profile" "vsi_profile_bastion" {
  name = var.vsi_profile_bastion
}

data "ibm_is_instance_profile" "vsi_profile_bastion_linux" {
  name = var.vsi_profile_bastion_linux
}


##############################################################################
# Calculate the most recently available OS Image Name for the 
# OS Provided
##############################################################################

data "ibm_is_images"  "os_images_bastion" {
    visibility = "public"
}

# Windows

locals {
    os_images_filtered_bastion = [
        for image in data.ibm_is_images.os_images_bastion.images:
            image if ((image.architecture == var.vsi_image_architecture) && (image.os == var.vsi_image_os) && (image.status == "available"))
    ]
}

data "ibm_is_image" "bastion_image" {
  name = local.os_images_filtered_bastion[0].name
}

# Linux

locals {
    os_images_filtered_bastion_linux = [
        for image in data.ibm_is_images.os_images_bastion.images:
            image if ((image.architecture == var.vsi_image_architecture) && (image.os == var.vsi_image_os_linux) && (image.status == "available"))
    ]
}

data "ibm_is_image" "bastion_image_linux" {
  name = local.os_images_filtered_bastion_linux[0].name
}


##############################################################################
# Provision bastion Virtual Server Windows
##############################################################################

resource "ibm_is_instance" "bastion" {
  count          = var.number_of_bastion_hosts

  name           = "${local.resources_prefix}-bastion-windows-${format("%02s", count.index)}"
  image          = data.ibm_is_image.bastion_image.id
  profile        = data.ibm_is_instance_profile.vsi_profile_bastion.name
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  primary_network_interface {
    name = "eth0"
    subnet = local.subnets_map.infrastructure["mgmt"]["subnet_id"]
    security_groups = [ibm_is_security_group.sg["bastion"].id, ibm_is_security_group.sg["mgmt"].id]
  }
 
  vpc  = ibm_is_vpc.vmware_vpc.id
  zone = var.vpc_zone
  keys = [ibm_is_ssh_key.bastion_key[0].id]
  
  user_data      = templatefile("scripts/bastion_windows_userdata.tpl", { dns_suffix_list = var.dns_root_domain })

  tags = local.resource_tags.vsi_bastion

  depends_on = [
    module.security_group_rules
  ]
}


##############################################################################
# Provision bastion Virtual Server Linux
##############################################################################

resource "ibm_is_instance" "bastion_linux" {
  count          = var.number_of_bastion_hosts_linux

  name           = "${local.resources_prefix}-bastion-linux-${format("%02s", count.index)}"
  image          = data.ibm_is_image.bastion_image_linux.id
  profile        = data.ibm_is_instance_profile.vsi_profile_bastion_linux.name
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  primary_network_interface {
    name = "eth0"
    subnet = local.subnets_map.infrastructure["mgmt"]["subnet_id"]
    security_groups = [ibm_is_security_group.sg["bastion"].id, ibm_is_security_group.sg["mgmt"].id]
  }
 
  vpc  = ibm_is_vpc.vmware_vpc.id
  zone = var.vpc_zone
  keys = concat([ibm_is_ssh_key.bastion_key[0].id],[for k,v in data.ibm_is_ssh_key.user_provided_ssh_keys : v.id])
  
  tags = local.resource_tags.vsi_bastion

  depends_on = [
    module.security_group_rules
  ]
}


##############################################################################
# Get bastion Virtual Server data for decrypting password 
##############################################################################


data "ibm_is_instance" "bastion" {
  count = var.number_of_bastion_hosts
  name = var.number_of_bastion_hosts == 0 ? ibm_is_instance.bastion[count.index].name : ""
  private_key = tls_private_key.bastion_rsa.private_key_pem
}


##############################################################################
# Attach Floating IP to Bastion Virtual Servers
##############################################################################

resource "ibm_is_floating_ip" "bastion_floating_ip" {
  count = var.number_of_bastion_hosts

  name           = "${local.resources_prefix}-bastion-windows-floating-ip-${format("%02s", count.index)}"
  target         = ibm_is_instance.bastion[count.index].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  tags = local.resource_tags.floating_ip_bastion
}

resource "ibm_is_floating_ip" "bastion_linux_floating_ip" {
  count = var.number_of_bastion_hosts_linux

  name           = "${local.resources_prefix}-bastion-linux-floating-ip-${format("%02s", count.index)}"
  target         = ibm_is_instance.bastion_linux[count.index].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  tags = local.resource_tags.floating_ip_bastion
}

##############################################################################
# Define Bastion output maps
##############################################################################


locals {
  bastion_hosts = { 
    windows = [
      for bastion_host in range(var.number_of_bastion_hosts) : {
        name = var.number_of_bastion_hosts == 0 ? ibm_is_instance.bastion[bastion_host].name : "none"
        private_ip_address =  var.number_of_bastion_hosts == 0? ibm_is_instance.bastion[bastion_host].primary_network_interface[0].primary_ip[0].address : "0.0.0.0"
        public_ip_address = var.number_of_bastion_hosts == 0 ? ibm_is_floating_ip.bastion_floating_ip[bastion_host].address : "0.0.0.0"
        username = "Administrator"
        password = var.number_of_bastion_hosts == 0 ? nonsensitive(data.ibm_is_instance.bastion[bastion_host].password) : ""
        #password = var.number_of_bastion_hosts == 0 ? data.ibm_is_instance.bastion[bastion_host].password : ""
      }
    ],
    linux = [
      for bastion_host in range(var.number_of_bastion_hosts_linux) : {
        name = var.number_of_bastion_hosts_linux == 0 ? ibm_is_instance.bastion_linux[bastion_host].name : "none"
        private_ip_address = var.number_of_bastion_hosts_linux == 0 ? ibm_is_instance.bastion_linux[bastion_host].primary_network_interface[0].primary_ip[0].address : "0.0.0.0"
        public_ip_address = var.number_of_bastion_hosts_linux == 0 ? ibm_is_floating_ip.bastion_linux_floating_ip[bastion_host].address : "0.0.0.0"
        username = "root"
        password = "use-SSH-key"
      }
    ],
  }
}

# Note to allow printout though IBM Cloud Schematics, nonsensitive() function is used with local.bastion_hosts[].password.
