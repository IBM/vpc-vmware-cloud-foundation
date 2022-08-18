

##############################################################
# Create private SSH key for Bare Metal Server
# Name of SSH Public Key stored in IBM Cloud must be unique within the Account
##############################################################

resource "tls_private_key" "host_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_private_key" {
  content         = tls_private_key.host_ssh.private_key_pem
  filename        = "SSH_KEYS/${local.resources_prefix}-esx_host_rsa"
  file_permission = 0600
}

resource "ibm_is_ssh_key" "host_ssh_key" {

  name       = "${local.resources_prefix}-host-ssh-key"
  public_key = trimspace(tls_private_key.host_ssh.public_key_openssh)
  resource_group = data.ibm_resource_group.resource_group_vmw.id

  tags = local.resource_tags.ssh_key
}



##############################################################
# Create private SSH key only for Bastion Server Use
# Name of SSH Public Key stored in IBM Cloud must be unique within the Account
##############################################################


locals {
  deploy_bastion = var.number_of_bastion_hosts > 0 ? var.number_of_bastion_hosts_linux > 0 ? true : true : false
}



# Public/Private key for accessing the instance

resource "tls_private_key" "bastion_rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "write_bastion_private_key" {
  content         = tls_private_key.bastion_rsa.private_key_pem
  filename        = "SSH_KEYS/${local.resources_prefix}-bastion_rsa"
  file_permission = 0600
}


resource "ibm_is_ssh_key" "bastion_key" {
  count = local.deploy_bastion ? 1 : 0
  name = "${local.resources_prefix}-bastion-ssh-key"
  public_key = trimspace(tls_private_key.bastion_rsa.public_key_openssh)

  tags = local.resource_tags.ssh_key
}


data "ibm_is_ssh_key" "user_provided_ssh_keys" {
  for_each = toset(var.user_provided_ssh_keys) 
  name = each.key
}



