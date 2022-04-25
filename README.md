# CUDL Infrastructure Configuration

This is the Terraform configuration for the Cambridge Digital Library Platform.
Initially this will only cover the setting up the data loading process.

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