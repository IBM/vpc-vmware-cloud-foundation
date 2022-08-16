
# Using IBM Cloud Schematics with IBM Cloud for Vmware Cloud Foundation Terraform templates

## Create a workspace

Login into IBM Cloud portal and [create a workspace using the console](https://cloud.ibm.com/docs/schematics?topic=schematics-workspace-setup&interface=ui#create-workspace_ui).

Alter the deployment location and other default values if needed.


## IBM Cloud CLI

Download in install [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started).


## List workspaces


Login with CLI and list the schematics workspaces. Find the one you are working with, and note the ID. 

```bash
ibmcloud schematics workspace list
```

```bash
Retrieving workspaces...
Name                                ID                                                           Description   Version            Status       Frozen   
vpc-vcf-example                     eu-de.workspace.vpc-vcf-example.c5276a56                                   Terraform v1.1.9   INPROGRESS   False   
                                    
OK
```

Store the ID value to an environmental variable.

```bash
export SCHEMATICS_WORKSPACE_ID=eu-de.workspace.vpc-vcf-example.c5276a56
```

## Get workspace details

Get details.

```bash
ibmcloud schematics workspace get --id $SCHEMATICS_WORKSPACE_ID
```


```bash                   
ID              eu-de.workspace.vpc-vcf-example.c5276a56   
Name            vpc-vcf-example   
Description        
Status          INPROGRESS   
Version         Terraform v1.1.9   
Creation Time   Wed Aug 10 13:32:57 2022   
Frozen          false   
Locked by       name@xx.yy.local   
Locked Time     Wed Aug 10 13:57:54 2022   
                   
Template ID     f00ea8ed-e7fd-45   
Commit ID       034b40e224092512e79d762d05134c2bf540d677   
                   
Variables 
Name                     Value   
vpc_zone                 eu-de-2   
user_provided_ssh_keys   ["example"]   
ibmcloud_api_key         Sensitive value stored on server   
                         
OK
```

Store Template ID to an environmental variable.

```bash
TEMPLATE_ID=$(ibmcloud schematics workspace get --id $SCHEMATICS_WORKSPACE_ID --json | jq -r .template_data[0].id)
```


## Get logs

```bash
ibmcloud schematics logs --id $SCHEMATICS_WORKSPACE_ID
```

```bash
... continue ...
 2022/08/10 11:15:42 Terraform apply | 
 2022/08/10 11:15:42 Command finished successfully.
 
 2022/08/10 11:15:42 -----  Terraform OUTPUT  -----
 
 2022/08/10 11:15:42 Starting command: terraform1.1 output -no-color -json
 2022/08/10 11:15:42 Starting command: terraform1.1 output -no-color -json
 2022/08/10 11:15:45 Command finished successfully.
 2022/08/10 11:15:51 Done with the workspace action

OK
```

## Get terraform state


Get terraform state.

```bash
ibmcloud schematics state pull --id $SCHEMATICS_WORKSPACE_ID --template $TEMPLATE_ID 
```


## Bastion access information

Get bastion hosts access information:

```bash
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq '.[0].output_values[0].vpc_bastion_hosts.value'
```


Get ssh private key for bastion hosts:

```bash
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq -r '.[0].output_values[0].ssh_private_key_bastion.value'
```


Get vcf bringup json:

```bash
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq -r '.[0].output_values[0].vcf_bringup_json.value' | jq
```
