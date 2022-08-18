# Hints and tips

## VLAN interfaces get deleted outside terraform

If you accidentally delete for example a VLAN interface `vlan-nic-vsan-pool-004` and you get errors when running terraform plan/apply like:

```bash
 Error: [ERROR] Error getting Bare Metal Server (02b7-53745858-9e6c-404d-80aa-97fc0085fa87) network interface (02b7-e899d942-ec07-4ea2-a965-85ada19f736f): [ERROR] Error Network interface not found
│ 
│   with ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_host_vsan[4],
│   on 12_vpc_vmware_vcf_net_pools.tf line 221, in resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_host_vsan":
│  221: resource "ibm_is_bare_metal_server_network_interface_allow_float" "zone_vcf_host_vsan" {
│ 
```

You can delete the state of the resource and rerun apply to re-create the interfaces. 

```bash
terraform state rm ibm_is_bare_metal_server_network_interface_allow_float.zone_vcf_host_vsan[4]
terraform apply -auto-approve
```

For Schematics, see [running terraform commands](https://cloud.ibm.com/docs/schematics?topic=schematics-schematics-cli-reference#tf-cmds).