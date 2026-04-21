# Deploying CUDL to a New AWS Account

This guide walks through setting up a complete CUDL environment on a new AWS account,
either for a new instance of the Cambridge deployment or for a different institution.

The whole process takes roughly **2–3 hours** of active work, plus waiting time for
DNS propagation (up to 48 hours, but usually under 30 minutes) and ACM certificate
validation (usually under 10 minutes).

---

## Contents

1. [Tools you need](#1-tools-you-need)
2. [AWS account setup](#2-aws-account-setup)
3. [Generate the environment directory](#3-generate-the-environment-directory)
4. [Register a domain and create the Route 53 hosted zone](#4-register-a-domain-and-create-the-route-53-hosted-zone)
5. [Bootstrap pre-Terraform AWS resources](#5-bootstrap-pre-terraform-aws-resources)
6. [Copy container images](#6-copy-container-images)
7. [Copy Lambda JAR artifacts](#7-copy-lambda-jar-artifacts)
8. [Copy or create SSM Parameter Store secrets](#8-copy-or-create-ssm-parameter-store-secrets)
9. [Configure institution.auto.tfvars](#9-configure-institutionautotfvars)
10. [Create the ACM wildcard certificates](#10-create-the-acm-wildcard-certificates)
11. [Run the pre-flight validation](#11-run-the-pre-flight-validation)
12. [Deploy with Terraform](#12-deploy-with-terraform)
13. [Load sample data and verify](#13-load-sample-data-and-verify)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. Tools you need

Install these on your local machine before starting.

| Tool | Version | Install |
|---|---|---|
| AWS CLI | v2 | https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html |
| Terraform | ~1.9.7 | https://developer.hashicorp.com/terraform/install |
| Docker | any recent | https://docs.docker.com/get-docker/ |
| Python | 3.x | https://www.python.org/downloads/ |
| Git | any recent | https://git-scm.com/downloads |

Verify they are all on your PATH:

```bash
aws --version
terraform --version
docker --version
python3 --version
git --version
```

---

## 2. AWS account setup

### 2.1 Get credentials for the target account

You need programmatic access (access key + secret key, or a role you can assume) to
an AWS account where you have broad IAM permissions. The deployment creates resources
across: S3, DynamoDB, EC2, ECS, ECR, CloudFront, ACM, Route 53, Lambda, EFS, SQS,
SNS, WAFv2, CloudWatch Logs, SSM Parameter Store, and IAM.

The easiest setup for a fresh account is an IAM user or role with
`AdministratorAccess`. You can tighten permissions once the platform is running.

Configure your credentials:

```bash
aws configure
# or export AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN
```

Check you are authenticated to the **correct** account before every step:

```bash
aws sts get-caller-identity
```

> **Tip:** If you see `InvalidClientTokenId` errors despite being logged in, you
> probably have stale credentials in environment variables. Clear them:
>
> ```bash
> unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
> ```

### 2.2 Decide your region

All resources are deployed to `eu-west-1` (Ireland) by default. CloudFront
certificates are also created in `us-east-1` automatically. If you need a different
primary region, edit `terraform.tf` in your new environment directory (created in
step 3) and update the default in [variables.tf](variables.tf) for `deployment-aws-region`.

---

## 3. Generate the environment directory

The `new-deployment-template/` directory is the canonical template for new deployments.
The `new-environment.sh` script copies it and substitutes your environment name,
AWS account ID, and domain name throughout.

Run this from the `new-deployment-template/` directory:

```bash
cd new-deployment-template

./scripts/new-environment.sh \
  --env    myorg \
  --domain myorg.example.com \
  --account 123456789012
```

Replace:
- `myorg` — a short lowercase name for the environment (used in resource names)
- `myorg.example.com` — the domain you will use (see step 4)
- `123456789012` — your AWS account ID (get it with `aws sts get-caller-identity`)

This creates a `cul-myorg/` directory at the repo root. The script prints a
summary of remaining steps when it finishes.

> **What the script does:** copies all `.tf` and `.tfvars` files, replaces
> `development` → `myorg`, `206247777824` → your account ID, and
> `cul-development.net` → your domain. It also clears the account-specific
> values in `institution.auto.tfvars` to `FIXME` placeholders so they stand out.

From here on, **all shared scripts are run from the repo root** (`./scripts/...`) and
**environment-specific scripts are run from `cul-myorg/`** (`./scripts/validate-prerequisites.sh`, etc.)

```bash
cd cul-myorg
```

---

## 4. Register a domain and create the Route 53 hosted zone

You need a domain that you control. You can:

- Register a new domain through Route 53 (takes ~15 minutes)
- Use an existing domain and delegate a subdomain (e.g. `cudl.myorg.example.com`)
- Transfer an existing domain into Route 53

### 4.1 Create the hosted zone

In the **target** AWS account:

```bash
aws route53 create-hosted-zone \
  --name myorg.example.com \
  --caller-reference "$(date +%s)"
```

Note the `Id` and `Name` from the output. The zone ID looks like `Z0XXXXXXXXXXXX`
(the part after `/hostedzone/`).

Or find it later:

```bash
aws route53 list-hosted-zones-by-name \
  --dns-name myorg.example.com \
  --query 'HostedZones[0].Id' \
  --output text
```

### 4.2 Delegate DNS (if using an existing domain)

If `myorg.example.com` is a subdomain of a domain you own elsewhere, you need to
add NS records at the parent. Get the Route 53 nameservers:

```bash
aws route53 get-hosted-zone \
  --id Z0XXXXXXXXXXXX \
  --query 'DelegationSet.NameServers'
```

Add those four nameservers as NS records in your parent domain's DNS provider.
DNS delegation can take up to 48 hours to propagate, but is usually much faster.

> **Check propagation:**
> ```bash
> dig NS myorg.example.com +short
> ```
> You should see the four Route 53 nameservers.

---

## 5. Bootstrap pre-Terraform AWS resources

Terraform needs certain resources to already exist before it can run. Create them
with the bootstrap script (still logged into the **target** account):

```bash
./scripts/bootstrap-environment.sh \
  --env myorg \
  --jar-bucket cul-cudl.mvn.myorg.example.com
```

Use `--dry-run` first to see what would be created without making any changes.

This creates:

| Resource | Name |
|---|---|
| S3 state bucket | `cul-cudl-myorg-terraform-state` |
| DynamoDB lock table | `terraform-state-lock-cudl-myorg` |
| CloudWatch log group | `/ecs/CUDL-Myorg` |
| Lambda JAR bucket | `cul-cudl.mvn.myorg.example.com` |
| IAM service-linked role | `AWSServiceRoleForAutoScaling` |

> **Why the service-linked role?** New AWS accounts don't have this role until Auto
> Scaling is used for the first time. Terraform will fail to create the Auto Scaling
> Group without it.

> **Note:** S3 bucket names are globally unique across all AWS accounts. If the JAR
> bucket name is taken, choose a different name and update `lambda-jar-bucket` in
> `institution.auto.tfvars` to match.

---

## 6. Copy container images

Container images must exist in the **target account's** ECR before Terraform can
reference them. This is a two-step process: pull from the source, push to the target.

### Step 1 — logged into the **source** account (Cambridge staging/production)

```bash
./scripts/copy-ecr-images.sh --pull
```

When it finishes it prints: `Now log into the destination account and run: ./copy-ecr-images.sh --push --src-account <id>`
Note that account ID — you will need it in the next step.

### Step 2 — logged into the **target** account

```bash
./scripts/copy-ecr-images.sh --push --src-account 438117829123
```

Replace `438117829123` with the source account ID printed in step 1.

> **Optional — update pinned digests:** The digests in `institution.auto.tfvars`,
> `terraform.tfvars`, and `scripts/copy-ecr-images.sh` are pinned to specific image
> versions. After copying images, these pinned values will already match what is in
> ECR (because `copy-ecr-images.sh` copies exactly those versions). You only need to
> run `update-ecr-digests.sh` if you want to **upgrade to newer image versions** —
> it queries ECR for the current `:latest` digest of each repository and updates all
> three files in one step:
>
> ```bash
> cd ../cul-myorg
> ./scripts/update-ecr-digests.sh
> ```
>
> Skip this step if you just want the same image versions as the source environment.

> **If you don't have access to the source account:** you need to build or obtain
> the images yourself and push them to the target ECR under the same repository
> names (`cudl/viewer`, `cudl/solr`, etc.).

---

## 7. Copy Lambda JAR artifacts

Lambda functions that use `.jar` files need the JARs in an S3 bucket.

### Step 1 — logged into the **source** account

```bash
./scripts/copy-lambda-jars.sh --download
```

This downloads JARs to `/tmp/lambda-jars/`.

### Step 2 — logged into the **target** account

```bash
../scripts/copy-lambda-jars.sh \
  --upload \
  --dst-bucket cul-cudl.mvn.myorg.example.com
```

Clean up afterwards:

```bash
rm -rf /tmp/lambda-jars
```

---

## 8. Create SSM Parameter Store secrets

The application containers read secrets from SSM Parameter Store at runtime.
All parameters must exist or Terraform will fail to resolve their ARNs at plan time.

If you have a `params.json` exported from an existing environment, import it with
(run from the `cul-myorg/` directory so the env name is auto-detected):

```bash
../scripts/copy-ssm-params.sh --import params.json --dry-run
../scripts/copy-ssm-params.sh --import params.json
```

A bare filename resolves to `scripts/params.json` regardless of working directory.
The imported values are placeholders — update each parameter in the AWS console
with the real values for this environment.

Otherwise create them manually in **AWS Systems Manager → Parameter Store**
(`eu-west-1`) under `/Environments/Myorg/CUDL/`:

> **Legacy parameters:** some are no longer actively used but still referenced in
> the Terraform code pending a future refactor. Set them to any non-empty placeholder
> (e.g. `"unused"`) so the deployment can proceed.

| Parameter path (relative to prefix) | Type | Description |
|---|---|---|
| `Services/DB/Password` | SecureString | **Legacy** — not actively used; set to any placeholder value |
| `Services/APIKey/Viewer` | SecureString | API key the Viewer uses to call CUDL Services |
| `Services/APIKey/Darwin` | SecureString | API key for the Darwin website |
| `Services/BasicAuth/Credentials` | String | Basic auth string (`user:password`) for protected endpoints |
| `Viewer/SMTP/Username` | SecureString | SMTP username for outbound email (SES recommended) |
| `Viewer/SMTP/Password` | SecureString | SMTP password |
| `Viewer/SMTP/Port` | SecureString | SMTP port (e.g. `587`) |
| `Viewer/CloudFront/Username` | SecureString | Username for CloudFront basic auth on the Viewer |
| `Viewer/CloudFront/Password` | SecureString | Password for CloudFront basic auth |
| `Viewer/Recaptcha/Sitekey` | SecureString | Google reCAPTCHA v2 site key |
| `Viewer/Recaptcha/Secretkey` | SecureString | Google reCAPTCHA v2 secret key |
| `Viewer/Google/AnalyticsId` | SecureString | **Legacy** — UA tracking ID (Google Analytics UA was sunset); set to any placeholder |
| `Viewer/Google/GA4AnalyticsId` | SecureString | Google Analytics 4 measurement ID |

> **SMTP:** The easiest option is AWS SES. Verify your sending domain in SES,
> create SMTP credentials, and use port 587.

### Content Loader database password

`ContentLoader/DB/Password` is used in two ways:

- **Spring Boot** reads it as `LOADING_DB_PASSWORD` to authenticate connections to PostgreSQL.
- **PostgreSQL** reads it as `POSTGRES_PASSWORD` to set the superuser password — but **only on first initialisation** (i.e. when the EFS data directory is empty). After that, the password lives inside the PostgreSQL data directory and the parameter value is ignored by PostgreSQL on subsequent starts.

This means the SSM value and the password stored in the database must always be kept in sync:

**Fresh environment (empty EFS volume):** set `ContentLoader/DB/Password` to any strong password before first deploy. PostgreSQL will initialise with it and Spring Boot will connect using the same value.

**Existing environment (EFS volume already has data):** the database password is whatever it was set to originally. Set `ContentLoader/DB/Password` to match that existing password. If you want to rotate to a new password, update it inside PostgreSQL first, then update the SSM parameter:

```sql
ALTER USER "dl-loading-ui" WITH PASSWORD 'new-password';
```

```bash
aws ssm put-parameter \
  --name "/Environments/Myorg/CUDL/ContentLoader/DB/Password" \
  --value "new-password" \
  --type SecureString \
  --overwrite \
  --region eu-west-1
```

Then restart the ECS service so the new value is injected.

---

## 9. Configure institution.auto.tfvars

Open `cul-myorg/institution.auto.tfvars` and fill in the remaining `FIXME` values.

Run this to see what is still outstanding:

```bash
grep -n FIXME institution.auto.tfvars
```

| Variable | Where to get the value |
|---|---|
| `route53_zone_id_existing` | Zone ID from step 4.1 |
| `cloudfront_route53_zone_id` | Same zone ID (both variables can be the same zone) |
| `cloudwatch_log_destination_arn` | ARN of your central CloudWatch destination, or remove/leave as FIXME (logging forwarding is disabled for development — see [cloudwatch.tf](cloudwatch.tf)) |
| `acm_certificate_arn` | Created in step 10 below — leave as FIXME for now |
| `acm_certificate_arn_us-east-1` | Created in step 10 below — leave as FIXME for now |
| ECR digests | Already updated by `update-ecr-digests.sh` in step 6 |

---

## 10. Create the ACM wildcard certificates

Two wildcard certificates are required:

- **eu-west-1** — used by the ALB HTTPS listener
- **us-east-1** — required by CloudFront (CloudFront only accepts certificates in us-east-1)

Both must be created manually in AWS Certificate Manager before running Terraform.

### 10.1 Request the certificates

Run the following twice — once for each region:

```bash
# eu-west-1 (ALB)
aws acm request-certificate \
  --domain-name "*.myorg.example.com" \
  --subject-alternative-names "myorg.example.com" \
  --validation-method DNS \
  --region eu-west-1

# us-east-1 (CloudFront)
aws acm request-certificate \
  --domain-name "*.myorg.example.com" \
  --subject-alternative-names "myorg.example.com" \
  --validation-method DNS \
  --region us-east-1
```

Each command prints a `CertificateArn`. Note both ARNs.

### 10.2 Add DNS validation records

For each certificate, add the CNAME validation record to your Route 53 hosted zone.

**Easiest — AWS Console:** open Certificate Manager in each region, select the pending
certificate, and click **Create records in Route 53**.

**CLI:**

```bash
# Get the validation record (repeat for the us-east-1 cert)
aws acm describe-certificate \
  --certificate-arn <arn> \
  --region eu-west-1 \
  --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# Add the CNAME to Route 53
aws route53 change-resource-record-sets \
  --hosted-zone-id <your-zone-id> \
  --change-batch '{
    "Changes": [{
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "<Name from above>",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [{"Value": "<Value from above>"}]
      }
    }]
  }'
```

> **Note:** both certificates cover the same domain, so they share the same DNS
> validation CNAME — you only need to add it to Route 53 once.

### 10.3 Wait for ISSUED status

```bash
aws acm describe-certificate \
  --certificate-arn <eu-west-1-arn> \
  --region eu-west-1 \
  --query 'Certificate.Status'

aws acm describe-certificate \
  --certificate-arn <us-east-1-arn> \
  --region us-east-1 \
  --query 'Certificate.Status'
```

Both should reach `ISSUED` within 5–10 minutes of the DNS records propagating.

### 10.4 Set the ARNs in institution.auto.tfvars

```hcl
acm_certificate_arn           = "arn:aws:acm:eu-west-1:123456789012:certificate/..."
acm_certificate_arn_us-east-1 = "arn:aws:acm:us-east-1:123456789012:certificate/..."
```

---

## 11. Run the pre-flight validation

Before running the main Terraform deployment, run the validation script to confirm
every prerequisite is in place:

```bash
./scripts/validate-prerequisites.sh
```

Expected output when everything is ready:

```
── institution.auto.tfvars ───────────────────────────────────────
  PASS  No FIXME placeholders in institution.auto.tfvars
── AWS credentials ────────────────────────────────────────────────
  PASS  Authenticated as arn:aws:iam::123456789012:user/deploy
── Terraform state backend ────────────────────────────────────────
  PASS  S3 state bucket exists: cul-cudl-myorg-terraform-state
  PASS  DynamoDB lock table exists: terraform-state-lock-cudl-myorg
── CloudWatch log group ───────────────────────────────────────────
  PASS  CloudWatch log group exists: /ecs/CUDL-Myorg
...
════════════════════════════════════════════════════════════
Results: 30 passed, 0 failed, 0 warnings  (30 checks)
All checks passed — ready to deploy.
```

Fix any failures before continuing. The script tells you which script to run for
each common issue.

---

## 12. Deploy with Terraform

Terraform must be applied in two stages because the base networking (VPC, subnets,
ALB) must exist before the workload services can be deployed into it.

### Stage 1 — base networking

```bash
terraform apply --target=module.base_architecture
```

Review the plan (you will see ~40–60 resources) and type `yes` to confirm.

This creates the VPC, subnets, ECS cluster, ALB, security groups, IAM roles, and
CloudWatch configuration. It takes about 5 minutes.

> **After this step:** if you are using an RDS database that needs to be in the
> same VPC, this is the point to create it. The VPC ID and subnet IDs are visible
> in the Terraform state or AWS console.

### Stage 2 — everything else

```bash
terraform apply
```

This deploys: the data-processing Lambda functions and S3 buckets, EFS, SQS queues,
CloudFront distribution, and all four ECS workloads (Content Loader, SOLR,
CUDL Services, CUDL Viewer). It takes about 10–15 minutes.

Review the plan — you will see ~150–200 resources — and type `yes` to confirm.

> **Note:** On first apply, ECS services may take 5–10 minutes to stabilise as
> containers start and pass health checks. Check the ECS console if services
> stay in a `PENDING` state.

---

## 13. Load sample data and verify

Terraform (step 12) created two S3 buckets:

| Bucket | Purpose |
|---|---|
| `myorg-cul-cudl-data-source` | Incoming source data — TEI files, images, collections |
| `myorg-cul-cudl-data-releases` | Processed output — populated automatically by Lambda |

Load sample data into the **source** bucket only. The releases bucket is intentionally
left empty — it is populated by the Lambda processing pipeline when source files arrive.

```bash
cd ..
./scripts/load-sample-data.sh --bucket myorg-cul-cudl-data-source
```

This clones a small set of sample TEI files from the
[dl-data-samples](https://github.com/cambridge-collection/dl-data-samples) repository
and uploads them to the source bucket. The Lambda processing pipeline triggers
automatically via SQS notifications — check CloudWatch Logs or the CloudWatch
dashboard Terraform created for the processing module.

After a few minutes, verify the environment is working:

| URL | Expected |
|---|---|
| `https://content-loader-myorg.myorg.example.com` | 401 login prompt |
| `https://search-myorg.myorg.example.com` | 404 (SOLR API healthy) |
| `https://services-myorg.myorg.example.com` | 404 (services healthy) |
| `https://viewer-myorg.myorg.example.com` | CUDL Viewer homepage |

---

## 14. Troubleshooting

### terraform init fails with "NoSuchBucket"

The S3 state bucket does not exist. Run `./scripts/bootstrap-environment.sh` first (step 5).

### ACM certificate stays in PENDING_VALIDATION

The DNS validation CNAME records could not be verified. Check:

1. The Route 53 zone was created in the **same** account as the certificate.
2. NS delegation is working if this is a subdomain: `dig NS myorg.example.com`.
3. The validation records were created: check Route 53 → hosted zone → look for
   CNAME records starting with `_`.

### ECS tasks fail to start ("CannotPullContainerError")

The task execution role cannot pull images from ECR. Check:

1. ECR repositories exist in the account: `aws ecr describe-repositories`.
2. The image digest in `institution.auto.tfvars` matches what is in ECR — run
   `./scripts/update-ecr-digests.sh --dry-run` to see if there are mismatches.

### ECS tasks start then stop immediately

Check the stopped task's logs in CloudWatch Logs group `/ecs/CUDL-Myorg`.
Common causes:

- SSM parameters missing or mis-named — verify paths match `/Environments/Myorg/CUDL/...`.
- Database unreachable — check security group allows traffic from the ECS VPC CIDR.
- Environment variable misconfigured in a container definition `.tf` file.

### Lambda functions not triggering

Check that S3 bucket notifications are configured: in the AWS console, open the
source bucket → Properties → Event notifications. If no notifications are listed,
the Lambda module may not have applied correctly — run `terraform apply` again.

### "Error: duplicate variable definition" on terraform plan

You have a variable defined in both `institution.auto.tfvars` and `terraform.tfvars`.
The split was introduced intentionally — any variable appearing in `institution.auto.tfvars`
should be removed from `terraform.tfvars`. Run:

```bash
grep -F "$(grep '^\w' institution.auto.tfvars | cut -d= -f1 | tr -d ' ')" terraform.tfvars
```

to find duplicates.

### Credentials error mid-apply ("ExpiredTokenException")

Your session token expired during a long apply. Renew credentials and re-run
`terraform apply` — Terraform is idempotent and will only create what is missing.

---

## Quick reference — full command sequence

```bash
# All commands run from the repo root unless shown otherwise.

# ── Generate environment directory ────────────────────────────────────────────
cd new-deployment-template
./scripts/new-environment.sh --env myorg --domain myorg.example.com --account 123456789012
cd ..

# ── In SOURCE account ─────────────────────────────────────────────────────────
# (switch credentials to source account)
./scripts/copy-ecr-images.sh --pull
./scripts/copy-lambda-jars.sh --download

# ── In TARGET account ─────────────────────────────────────────────────────────
# (switch credentials to target account)
cd cul-myorg
./scripts/bootstrap-environment.sh --env myorg --jar-bucket cul-cudl.mvn.myorg.example.com
cd ..
./scripts/copy-ecr-images.sh --push --src-account <source-account-id>
# Optional: only needed if upgrading to newer image versions than the source
# cd cul-myorg && ./scripts/update-ecr-digests.sh && cd ..
./scripts/copy-lambda-jars.sh --upload --dst-bucket cul-cudl.mvn.myorg.example.com

# Create SSM parameters in AWS console or CLI (see step 8)

# Fill in institution.auto.tfvars (zone IDs, DB host, etc.)

terraform init

# Create wildcard certs manually in ACM (eu-west-1 and us-east-1) — see step 10
# Add both ARNs to institution.auto.tfvars, then:
./scripts/validate-prerequisites.sh

terraform apply --target=module.base_architecture
terraform apply

../scripts/load-sample-data.sh --bucket myorg-cul-cudl-data-source
```
