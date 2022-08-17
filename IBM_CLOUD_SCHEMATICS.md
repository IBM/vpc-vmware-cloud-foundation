
# Using IBM Cloud Schematics with IBM Cloud for Vmware Cloud Foundation Terraform templates

## Create a workspace

### Create a VCF workspace with IBM Cloud console

Login into IBM Cloud portal and [create a workspace using the console](https://cloud.ibm.com/docs/schematics?topic=schematics-workspace-setup&interface=ui#create-workspace_ui).

Alter the deployment location and other default values if needed.

### Create a VCF workspace with terraform

You can also create Schematics workspace for VCF using the provided terraform in [schematics folder](./schematics/). The *ibmcloud_api_key* terraform variable must be generated prior to running this template. Please refer to [IBM Cloud API Key](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-creating-cloud-api-key). You can create an environmental variable for the API key, for example:

```bash
export TF_VAR_ibmcloud_api_key=<put_your_key_here>
```

Clone the template to your local workstation.

```bash
git clone https://github.com/IBM/vpc-vmware-cloud-foundation
```

First, create a copy of your desired architecture template tfvars file, e.g. `terraform.tfvars.vcf-consolidated` to `terraform-vcf-consolidated.tfvars` and fill in the desired values. Then you can use [the provided terraform template](./schematics/) to create a workspace with the variables you have chosen.

```bash
cd ./schematics/
terraform plan -var-file="terraform-vcf-consolidated.tfvars"
```

If your plan looks good, you can do apply. Note that this only creates and configures the terraform workspace in IBM Cloud schematics, it does not deploy any assets yet.

```bash
terraform apply -var-file="terraform-vcf-consolidated.tfvars"
```

Check the id for the workspace and its status. Check your variable values if you see any errors. You can now login to IBM Cloud console and check your values in the schematics workspace, and run the `generate plan` or `apply plan` through the IBM Cloud console UI or CLI.


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
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq '.[0].output_values[0].vpc_bastion_hosts | .value'
```


Get ssh private key for bastion hosts:

```bash
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq -r '.[0].output_values[0].ssh_private_key_bastion | .value'
```


Get vcf bringup json:

```bash
ibmcloud schematics output --id $SCHEMATICS_WORKSPACE_ID --json | jq -r '.[0].output_values[0].vcf_bringup_json | .value' | jq
```
