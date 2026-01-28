# CUDL Terraform Environment Setup

This page lists the AWS resources and configuration that must exist **before** you run `terraform init` / `terraform apply` for any CUDL environment (sandbox, staging, production).

Use it as a checklist when bringing up a new environment or rebuilding an existing one.

---

## 1. Global Terraform backend (once per AWS account)

These are shared by all environments in this repo.

- **S3 state bucket**
  - Name: `cul-cudl-terraform-state`
  - Region: `eu-west-1`
  - Purpose: stores Terraform state for all environments (see `terraform { backend "s3" ... }` blocks).

- **DynamoDB state lock table**
  - Name: `terraform-state-lock-cudl`
  - Region: `eu-west-1`
  - Primary key: partition key named `LockID` (type `String`).
  - Purpose: used by Terraform for state locking (configured in the backend blocks).

Create these once (via AWS Console or CLI) before running `terraform init` for any environment.

---

## 2. Shared AWS setup

These prerequisites are also outside this repo and are reused across environments.

- **AWS account & IAM**
  - An AWS account with access to `eu-west-1` and `us-east-1`.
  - An IAM role or user with permissions for:
    - S3, DynamoDB, EC2, ECS, ECR, CloudFront, ACM, Route53, Lambda, EFS, SQS, SNS, WAFv2, DataSync, CloudWatch Logs / Dashboards, SSM Parameter Store, and IAM (for role/policy creation).

- **DNS (Route 53)**
  - A public hosted zone for `cudl.lib.cam.ac.uk.` or whatever value you set in `registered_domain_name`.
  - The zone ID referenced by:
    - `route53_zone_id_existing`
    - `cloudfront_route53_zone_id`
    - `rti_image_server_route53_zone_id_existing`

- **TLS certificates (ACM)**
  - `eu-west-1` ACM certificate for the main CUDL domain:
    - ARN used in `acm_certificate_arn` in each environment’s `terraform.tfvars`.
  - `us-east-1` ACM certificate for CloudFront:
    - ARN used in `acm_certificate_arn_us-east-1`.

---

## 3. Application prerequisites (per environment)

Each environment directory (for example `cul-cudl-staging`) has a `terraform.tfvars` file. The values there assume the following resources already exist.

### 3.1 Container images (ECR)

**ECS services**

Create ECR repositories and push images for:

- `cudl/content-loader-db`
- `cudl/content-loader-ui`
- `cudl/solr`
- `cudl/solr-api`
- `cudl/services`
- `cudl/viewer`

The `cul-cudl-<env>/terraform.tfvars` file supplies `sha256` digests for each of these via:

- `content_loader_ecr_repositories`
- `solr_ecr_repositories`
- `cudl_services_ecr_repositories`
- `cudl_viewer_ecr_repositories`

**Lambda container functions**

For any entries in `transform-lambda-information` that use `image_uri`, the referenced images must exist in ECR, for example (from staging):

- `cudl/tei-processing`
- `cudl/solr-listener`
- `cudl/transkribus-processing`

You do **not** need to create the ECS cluster or services themselves – those are created by Terraform via the `terraform-aws-workload-ecs` modules.

### 3.2 Lambda JAR artifacts (S3)

For `transform-lambda-information` entries that use `jar_path`:

- **Maven/JAR bucket**
  - Name (staging example): `cul-cudl.mvn.cudl.lib.cam.ac.uk`
  - Must contain the JARs referenced in `jar_path`, e.g.:
    - `release/uk/ac/cam/lib/cudl/awslambda/AWSLambda_Data_Transform/1.0/AWSLambda_Data_Transform-1.0-jar-with-dependencies.jar`
  - This bucket is referenced via `lambda-jar-bucket` in `terraform.tfvars`.

You do **not** need to pre-create the main CUDL data buckets for source, destination, or enhancements – Terraform will create those (`modules/cudl-data-processing/s3.tf`) using:

- `source-bucket-name`
- `destination-bucket-name`
- `enhancements-bucket-name`

### 3.3 XSLT / transformation support buckets

These are used by the wider data-processing pipeline (not all are directly referenced in this repo, but are required for end-to-end operation):

- An S3 bucket containing the compiled XSLT for data processing:
  - Built from https://github.com/cambridge-collection/cudl-data-processing-xslt
- (Transkribus extension) An S3 bucket containing XSLT for Transkribus imports:
  - Built from https://github.com/cambridge-collection/transkribus-to-cudl

Configure the pipeline or Lambda images so they know where to fetch these artefacts from.

### 3.4 Database (RDS)

For environments where the viewer and services are enabled, you need an existing Postgres database:

- An RDS instance reachable from the VPC that Terraform will create.
- Database, schema, and users that match the configuration baked into `cudl-services`, e.g. in staging:
  - Host: `cudl-postgres.cmzjzpssbgnq.eu-west-1.rds.amazonaws.com`
  - Database name: `dev_cudl_viewer` (see `CUDL_SERVICES_DB_NAME` in `cudl_services_container_def.tf`)
  - User: `cudl_viewer_dev_user_1`
  - Password: stored in SSM Parameter Store (see next section).

Terraform does **not** create the RDS instance; it only reads the connection details from environment variables and SSM parameters.

### 3.5 SSM Parameter Store (secrets & config)

For each environment (`Staging`, `Live`, etc.), create the following parameters in AWS Systems Manager Parameter Store. For staging, the exact paths are:

**CUDL Services**

- `/Environments/Staging/CUDL/Services/DB/Password` (SecureString)  
  - Postgres password for the `cudl_viewer_dev_user_1` user.
- `/Environments/Staging/CUDL/Services/APIKey/Darwin` (SecureString)  
  - API key used by the Darwin website to call CUDL Services.
- `/Environments/Staging/CUDL/Services/APIKey/Viewer` (SecureString)  
  - API key used by the viewer to call CUDL Services.
- `/Environments/Staging/CUDL/Services/BasicAuth/Credentials` (String)  
  - Basic auth credentials (e.g. `user:password`) used by CUDL Services when calling protected endpoints.

**CUDL Viewer**

- `/Environments/Staging/CUDL/Viewer/SMTP/Username` (SecureString)  
- `/Environments/Staging/CUDL/Viewer/SMTP/Password` (SecureString)  
- `/Environments/Staging/CUDL/Viewer/SMTP/Port` (SecureString)  
  - SMTP credentials and port for sending email (typically AWS SES).
- `/Environments/Staging/CUDL/Viewer/Recaptcha/Sitekey` (SecureString)  
- `/Environments/Staging/CUDL/Viewer/Recaptcha/Secretkey` (SecureString)  
  - Google reCAPTCHA site and secret keys for the viewer’s domain.
- `/Environments/Staging/CUDL/Viewer/Google/AnalyticsId` (SecureString)  
- `/Environments/Staging/CUDL/Viewer/Google/GA4AnalyticsId` (SecureString)  
  - Google Analytics tracking IDs (Universal + GA4).
- `/Environments/Staging/CUDL/Viewer/CloudFront/Username` (SecureString)  
- `/Environments/Staging/CUDL/Viewer/CloudFront/Password` (SecureString)  
  - Basic auth credentials enforced by the CloudFront Function in front of the viewer.

For other environments, use the same structure but change the environment segment (e.g. `/Environments/Live/...`), and ensure the values match that environment’s endpoints and credentials.

### 3.6 CloudWatch log destination (optional but referenced)

In each environment’s `terraform.tfvars` you’ll see:

- `cloudwatch_log_destination_arn`

This should point to an existing CloudWatch Logs destination (often used for centralised logging or forwarding to another account). Terraform will create a subscription filter that sends ECS logs from the base architecture log group to this destination.

If you do not want to forward logs, either:

- Create a destination and set its ARN here, or
- Adjust the configuration to skip the subscription filter.

---

## 4. Environment bring-up checklist

Before running Terraform for a given environment (`cul-cudl-staging`, `cul-cudl-production`, etc.):

1. Confirm global backend resources exist:
   - S3 bucket `cul-cudl-terraform-state`
   - DynamoDB table `terraform-state-lock-cudl` with `LockID` (String) key
2. Confirm Route53 hosted zone and ACM certificates exist and ARNs/IDs match the values in that environment’s `terraform.tfvars`.
3. Confirm all required ECR repositories and images exist and match the digests in `terraform.tfvars`.
4. Confirm the Maven/JAR bucket (`lambda-jar-bucket`) exists and contains the referenced JARs.
5. Confirm any XSLT artefact buckets required by your pipelines exist and are populated.
6. Confirm the RDS instance and database/users exist and are reachable from the target VPC.
7. Create or verify all SSM Parameter Store entries listed in section 3.5.
8. Confirm the CloudWatch Logs destination (if used) exists and matches `cloudwatch_log_destination_arn`.

Once all of the above are in place:

```bash
cd cul-cudl-staging   # or another environment directory
terraform init
terraform plan
terraform apply
```

