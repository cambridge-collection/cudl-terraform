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

## Running Terraform in sandbox environment

Resource naming in the sandbox environment (AWS Account 563181399728) has been changed to include the user's CRSid. When running Terraform commands, you will be prompted to enter a value for the `owner` for which the CRSid should be provided. This will be added as a prefix in resource names. Other environments, dev, staging and production are not prefixed with the owner value. In the sandbox environment, a tag Owner will also be added to resources. This will not be used in dev, staging and production.

## Running Terraform Tests

Before applying the Terraform in each environment, it is advisable to run tests to validate that the modules being used generate expected outputs.

Terraform tests can be run in cudl-dev, cudl-staging and cudl-production. This can be done by entering the directory of choice, e.g.

    cd cudl-dev

Then entering a command 

    terraform test dev

Which will run a suite of tests against that environment. The test file in this case is located in the path `cudl-dev/tests/dev.tftest.hcl`.

Currently the tests are intended to be run using an IAM role from the sandbox environment (AWS Account 563181399728). Variables from each environment are used, with overrides from the test file enabling the tests to be run in the sandbox environment.

Currently all tests run Terraform plan, although they could be adapted to run apply if desired.

## Data Loading Process Infrastructure.

The data loading process converts the data from the input format into the output format.
This consists of for example lambda functions that convert the item TEI into JSON suitable for
display in the viewer. For more detail on the loading process see:
https://github.com/cambridge-collection/data-lambda-transform

This diagram shows the AWS infrastructure setup required for the data loading process. 
![](docs/images/CUDL_data_processing.jpg)

## Lambda Definitions

| Lambda name                                           | Type      | Runtime | Source Code                                                   |
| :---------------------------------------------------- | :-------- | :------ | :------------------------------------------------------------ |
| AWSLambda_CUDLPackageData_Collection_SOLR_Listener    | Container | Docker  | https://github.com/cambridge-collection/cudl-solr-listener    |
| AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS         | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_DATASET_JSON                | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY         | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_SOLR_Listener               | Container | Docker  | https://github.com/cambridge-collection/cudl-solr-listener    |
| AWSLambda_CUDLPackageData_TEI_Processing              | Container | Docker  | https://github.com/cambridge-collection/transkribus-import    |
| AWSLambda_CUDL_Transkribus_Ingest                     | Container | Docker  | ??                                                            |
| AWSLambda_CUDLPackageData_UI_JSON                     | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_UPDATE_DB                   | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |


### AWS Resources created are:

- IAM policies
- S3 buckets (shown in green)
- SQS, SNS and Lambda functions (shown in yellow)
- EFS volume (shown in dark green)

### Existing resources (not created by Terraform) are: 

- Cudl viewer and Services and RDS database (shown in blue)

## EXTERNAL RESOURCES REQUIRED BY THIS TERRAFORM SCRIPT

- Existing VPN
- Secret Manager secrets - for DB passwords
- S3 maven bucket which contains the compiled and deployed lambdas from https://github.com/cambridge-collection/data-lambda-transform
- RDS database (required if using viewer)
- S3 bucket for containing the zipped xslt used for transformations from https://github.com/cambridge-collection/cudl-data-processing-xslt 
- (Transkribus extension) S3 bucket for containing the zipped xslt used for transformations from https://github.com/cambridge-collection/transkribus-to-cudl

When created, update the appropriate terraform.tfvars properties to point to these resources.

