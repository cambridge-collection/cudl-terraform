# CUDL Infrastructure Configuration

This is the Terraform configuration for the Cambridge Digital Library Platform.
Initially this will only cover the setting up the data loading process.

## Prerequisites 

Install Terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli

## Commands

First select the environment you want to work in: dev, stage or prod.  It's recommended you 
work and test and changes in dev first!

    cd cudl-dev

To initialise the working directory run the following in the root directory of this project.

    terraform init

You can confirm the configuration is valid with 

    terraform validate 

You can see what changes have occurred from the terraform file state to the current state by running
It saves the plan generated to a binary file.

    terraform plan -out=myplan 

You can inspect the plan file using the command

    terraform show myplan 

To apply those changes run  **warning this will update the system** 

    terraform apply myplan 

If you want to bring down all components **warning this will detroy all managed components**
    
    terraform destroy 

For more information see

https://www.terraform-best-practices.com/

## State

State is stored in S3, and will be picked up automatically from the init command.
It is backend "s3" section of the main.tf file.

## Data Loading Process Infrastructure.

The data loading process converts the data from the input format into the output format.
This consists of for example lambda functions that convert the item TEI into JSON suitable for
display in the viewer. For more detail on the loading process see:
https://github.com/cambridge-collection/data-lambda-transform

This diagram shows the AWS infrastructure setup required for the data loading process. 
![](docs/images/CUDL_data_processing.jpg)

### AWS Resources created are:

- IAM policies
- S3 buckets (shown in green)
- SQS, SNS and Lambda functions (shown in yellow)
- EFS volume (shown in dark green)

### Existing resources (not created by Terraform) are: 

- Cudl viewer and Services and RDS database (shown in blue)

## Puppet 
In addition to the Terraform setup, Puppet is used to control the software 
installed on the architecture, and is used for example to sync the data between EFS and S3.
See https://gitlab.developers.cam.ac.uk/lib/dev/dev-puppet