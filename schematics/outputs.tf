
##############################################################
# Outputs
##############################################################



output "workspace_id" {
  value = ibm_schematics_workspace.schematics_workspace_vcf.id
}


output "workspace_status" {
  value = ibm_schematics_workspace.schematics_workspace_vcf.status
}