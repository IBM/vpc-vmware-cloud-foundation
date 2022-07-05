

terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = "1.43.0"
    }
  }
}


/*
terraform {
  required_version = ">= 0.14"
  required_providers {
    ibm = {
      source  = "localdomain/provider/ibm" // ~/.terraform.d/plugins/localdomain/provider/ibm/1.39.2/darwin_amd64
      version = "1.39.2"
      #source = "IBM-Cloud/ibm"
      #version = "1.40.0"      
    }
  }
}
*/


resource "ibm_is_instance" "instances" {
  count          = var.vmw_instance_no_of_instances
  name           = var.vmw_instance_name
  vpc            = var.vmw_instance_vpc_id
  zone           = var.vmw_instance_location
  image          = var.vmw_instance_image
  profile        = var.vmw_instance_profile
  keys           = [var.vmw_instance_ssh_keys]
  resource_group = var.vmw_instance_resource_group_id

  primary_network_interface {
    subnet = var.vmw_instance_vmw_subnet_inst_mgmt_id
  #  security_groups = [ var.vmw_instance_vmw_sg_mgmt ]
  }
#   dynamic primary_network_interface {
#     for_each = var.primary_network_interface
#     content {
#       subnet               = primary_network_interface.value.subnet
#       name                 = (primary_network_interface.value.interface_name != "" ? primary_network_interface.value.interface_name : null)
#       security_groups      = (primary_network_interface.value.security_groups != null ? primary_network_interface.value.security_groups : [])
#       primary_ipv4_address = (primary_network_interface.value.primary_ipv4_address != "" ? primary_network_interface.value.primary_ipv4_address : null)
#     }
#   }

  user_data = (var.vmw_instance_user_data != null ? var.vmw_instance_user_data : null)
  volumes   = (var.vmw_instance_data_volumes != null ? var.vmw_instance_data_volumes : [])
  tags      = var.vmw_instance_tags

#   dynamic network_interfaces {
#     for_each = (var.network_interfaces != null ? var.network_interfaces : [])
#     content {
#       subnet               = network_interfaces.value.subnet
#       name                 = (network_interfaces.value.interface_name != "" ? network_interfaces.value.interface_name : null)
#       security_groups      = (network_interfaces.value.security_groups != null ? network_interfaces.value.security_groups : [])
#       primary_ipv4_address = (network_interfaces.value.primary_ipv4_address != "" ? network_interfaces.value.primary_ipv4_address : null)
#     }
#   }
#   dynamic boot_volume {
#     for_each = (var.boot_volume != null ? var.boot_volume : [])
#     content {
#       name       = (boot_volume.value.name != "" ? boot_volume.value.name : null)
#       encryption = (boot_volume.value.encryption != "" ? boot_volume.value.encryption : null)
#     }
#   }
}

resource "ibm_is_floating_ip" "bastion_floatingip" {
  count          = var.vmw_instance_no_of_instances
  name   = "${var.vmw_instance_resources_prefix}-${var.vmw_instance_name}-ip"
  target = ibm_is_instance.instances[count.index].primary_network_interface[0].id
}

# output "random_password_vc_os" {
#   value = random_password.vc_os_password.result
# # }
# resource "random_password" "vc_sso_password" {
#   length            = 16
#   special           = true
#   min_lower         = "2"
#   min_numeric       = "2"
#   min_special       = "2"
#   min_upper         = "2"
#   number            = true
#   override_special = "_%@"
# }
# output "random_password_vc_sso" {
#   value = random_password.vc_sso_password.result
# }

# // Inject values into cloud-init userdata shell template and parse file
# data "template_file" "vcenter_json" {
#   template = "${file("${path.module}/vca_vpc_esxi.json.tpl")}"
#   vars = {
#     # vc_deployment_esxi_fqdn = "${var.vc_deployment_name}.${var.vc_deployment_domain}"
#     vc_deployment_esxi_fqdn = "esx-bb-000.ibm.com"
#     vc_deployment_esxi_password = "vcenter_magic_password"
#     vc_deployment_network = "pg-mgmt"
#     vc_deployment_datastore = "datastore1"
#     vc_deployment_name = "vcenter"
#     vc_deployment_domain = "vmw-terraform.ibmcloud.local"
#     vc_deployment_hostname_ip = "10.97.0.132"
#     vc_deployment_hostname_prefix = "25"
#     vc_deployment_hostname_gateway = "10.97.0.129"
#     vc_deployment_os_password = random_password.vc_os_password.result
#     vc_deployment_sso_password = random_password.vc_sso_password.result

#   }
# }

# data "ibm_is_subnet" "vcenter_subnet" {
#   identifier = module.vpc_zone_networks.vpc_subnet_zone_inst_mgmt_id
# }

data "template_file" "vcenter_json" {
  template = "${file("${path.module}/vca_vpc_esxi.json.tpl")}"
  vars = {
    vcenter_esx_hostname_fqdn = var.vmw_instance_vcenter_esx_hostname_fqdn
    vcenter_esx_pwd = var.vmw_instance_vcenter_esx_pwd
    domain = var.vmw_instance_domain
    vcenter_ip = var.vmw_instance_vcenter_ip
    network_cidrprefix = var.vmw_instance_network_cidrprefix
    network_gateway = var.vmw_instance_network_gateway
    vcenter_pwd = var.vmw_instance_vcenter_pwd
  }
}

resource "null_resource" "bastion-host-command-1" {
  depends_on = [ibm_is_floating_ip.bastion_floatingip]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = var.vmw_instance_ssh_private_key
    host        = ibm_is_floating_ip.bastion_floatingip[0].address
 
  }  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'yum install wget bind-utils yum-utils libnsl -y'",
      "sudo bash -c 'sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo'",
      "sudo bash -c 'yum install terraform  -y'",
      "sudo bash -c 'wget https://cloud-object-storage-vmw-cos-static-web-hosting-6we.s3.direct.eu-de.cloud-object-storage.appdomain.cloud/VMware-VCSA-all-7.0.2-17958471.iso'",
      "sudo bash -c 'cd / && mkdir vcenter'",
      "sudo bash -c 'mount -t iso9660 -o loop VMware-VCSA-all-7.0.2-17958471.iso /vcenter'",
      "sudo bash -c 'ls -lrt /vcenter'"
    #   "sudo bash -c ''",
    ]
  }
  provisioner "file" {
    content      = data.template_file.vcenter_json.rendered
    destination = "/root/vcenter_deployment.json"
  }
}
resource "null_resource" "bastion-host-command-2" {
  depends_on = [null_resource.bastion-host-command-1]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = var.vmw_instance_ssh_private_key
    host        = ibm_is_floating_ip.bastion_floatingip[0].address
 
  }  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'cd /'",
      "sudo bash -c '/vcenter/vcsa-cli-installer/lin64/vcsa-deploy install --accept-eula --verify-template-only /root/vcenter_deployment.json'"
    ]
  }
}

resource "null_resource" "bastion-host-command-3" {
  depends_on = [null_resource.bastion-host-command-1]

  # Specify the ssh connection
  connection {
    user        = "root"
    private_key = var.vmw_instance_ssh_private_key
    host        = ibm_is_floating_ip.bastion_floatingip[0].address
 
  }  # Execute the script remotely
  provisioner "remote-exec" {
    inline = [
      "sudo bash -c 'cd /'",
      "sudo bash -c '/vcenter/vcsa-cli-installer/lin64/vcsa-deploy install --accept-eula --no-ssl-certificate-verification /root/vcenter_deployment.json'"
    ]
  }
}

