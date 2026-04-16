# Helper Scripts

Scripts for copying assets between AWS accounts when setting up a new CUDL environment.

> **Setting up a new environment or institution?**
> See `new-deployment-template/scripts/` — it contains `new-environment.sh`, `bootstrap-environment.sh`,
> `update-ecr-digests.sh`, and `validate-prerequisites.sh` which are specific to that workflow.

## Scripts

| Script | Purpose |
|---|---|
| `copy-ssm-params.sh` | Copy Parameter Store parameters between accounts |
| `copy-ecr-images.sh` | Create ECR repositories and copy images between accounts |
| `copy-lambda-jars.sh` | Copy Lambda JAR artifacts between Maven S3 buckets |
| `load-sample-data.sh` | Load sample source data into the cul-cudl-data-source S3 bucket |

## Prerequisites

- AWS CLI v2
- Docker (ECR script only)
- Python 3
- Authenticated to the relevant AWS account before each step (see [Authentication](#authentication))

## Authentication

These scripts use whatever AWS credentials are active in your shell. They do **not** use named profiles.

If you see `InvalidClientTokenId` errors despite being logged in, you likely have stale credentials set as environment variables that are overriding your session. Clear them with:

```bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

---

## copy-ssm-params.sh

Copies CUDL Parameter Store parameters from one account/environment to another.

Parameters are read from and written to paths of the form:
```
/Environments/<Env>/CUDL/<Service>/<Name>
```

### Workflow

**Step 1** — logged into the source account:

```bash
# Find the exact path structure in the source account
./scripts/copy-ssm-params.sh --discover

# Export parameters to a local file
./scripts/copy-ssm-params.sh --export params.json --src-env Staging
```

A bare filename (no path) is written to `scripts/params.json` regardless of which
directory you run the script from.

**Step 2** — logged into the destination account:

```bash
# Preview what will be written
./scripts/copy-ssm-params.sh --import params.json --dst-env Development --dry-run

# Write parameters
./scripts/copy-ssm-params.sh --import params.json --dst-env Development
```

> **Security:** `params.json` contains plaintext secrets. Delete it after the import:
> ```bash
> rm scripts/params.json
> ```

### Options

| Flag | Description |
|---|---|
| `--discover` | List all parameters under `/Environments/` in the current account |
| `--export <file>` | Export CUDL parameters from the current account to a JSON file |
| `--import <file>` | Import parameters from a JSON file into the current account |
| `--src-env <Env>` | Source environment name as it appears in the SSM path (e.g. `Staging`, `Production`) |
| `--dst-env <Env>` | Destination environment name (e.g. `Development`) |
| `--region <region>` | AWS region (default: `eu-west-1`) |
| `--dry-run` | Print what would be written without making any changes (import only) |

### Parameters copied

| Path (relative to `/Environments/<Env>/CUDL/`) | Used by |
|---|---|
| `Services/APIKey/Viewer` | Viewer → CUDL Services auth |
| `Viewer/SMTP/Username` | Viewer email feedback |
| `Viewer/SMTP/Password` | Viewer email feedback |
| `Viewer/SMTP/Port` | Viewer email feedback |
| `Viewer/CloudFront/Username` | Viewer CloudFront basic auth |
| `Viewer/CloudFront/Password` | Viewer CloudFront basic auth |
| `Viewer/Recaptcha/Sitekey` | Viewer feedback form |
| `Viewer/Recaptcha/Secretkey` | Viewer feedback form |
| `Viewer/Google/AnalyticsId` | Viewer Google Analytics |
| `Viewer/Google/GA4AnalyticsId` | Viewer Google Analytics 4 |
| `Services/DB/Password` | CUDL Services RDS |
| `Services/APIKey/Darwin` | CUDL Services Darwin API |
| `Services/BasicAuth/Credentials` | CUDL Services IIIF/base URL auth |

---

## copy-ecr-images.sh

Creates ECR repositories in the destination account and copies all required images from a source account.

Images are pulled locally from the source registry and then pushed to the destination registry. Docker can hold login sessions for both registries simultaneously, so the pulled images remain cached between steps.

### Workflow

**Step 1** — logged into the source account:

```bash
./scripts/copy-ecr-images.sh --pull
```

The script will print the `--src-account` value to use in step 2.

**Step 2** — logged into the destination account:

```bash
# Preview what repos would be created and images pushed
./scripts/copy-ecr-images.sh --push --src-account <source-account-id> --dry-run

# Create repositories and push images
./scripts/copy-ecr-images.sh --push --src-account <source-account-id>
```

### Options

| Flag | Description |
|---|---|
| `--pull` | Authenticate to source ECR and pull all images locally |
| `--push` | Create ECR repositories and push locally cached images to destination ECR |
| `--src-account <id>` | Source AWS account ID — used to locate the locally cached images (required for `--push`) |
| `--region <region>` | AWS region (default: `eu-west-1`) |
| `--dry-run` | Print what would be created/pushed without making any changes (push only) |

### Images copied

| Repository | Digest | Used by |
|---|---|---|
| `cudl/content-loader-db` | `sha256:26092924...` | Content Loader (ECS) |
| `cudl/content-loader-ui` | `sha256:6d042df4...` | Content Loader (ECS) |
| `cudl/solr-api` | `sha256:6df1d6c1...` | SOLR (ECS) |
| `cudl/solr` | `sha256:dfd38c74...` | SOLR (ECS) |
| `cudl/services` | `sha256:bc86da80...` | CUDL Services (ECS) |
| `cudl/viewer` | `sha256:70e1574f...` | CUDL Viewer (ECS) |
| `cudl/tei-processing` | `sha256:dedac988...` | TEI Processing (Lambda) |
| `cudl/solr-listener` | `sha256:1bef571e...` | SOLR Listener (Lambda) |
| `cudl/transkribus-processing` | `sha256:03cf5047...` | Transkribus Ingest (Lambda) |

The digests in this script are pinned to the versions in `terraform.tfvars`. Update them together when upgrading image versions.

---

## load-sample-data.sh

Loads sample CUDL source data from the [dl-data-samples](https://github.com/cambridge-collection/dl-data-samples) repository into the `cul-cudl-data-source` S3 bucket. This gives the Lambda processing pipeline something to work with in a fresh environment.

The script uses a sparse Git checkout so only the `source-data/data/` directory is downloaded. Two files are renamed on upload to match the canonical names expected by the pipeline:

- `sample.dl-dataset.json` → `cudl.dl-dataset.json`
- `sample.ui.json5` → `cudl.ui.json5`

Once uploaded, the S3 bucket notifications will trigger the Lambda transforms automatically.

### Usage

```bash
# Preview what would be uploaded
./scripts/load-sample-data.sh --dry-run

# Upload to the default bucket (development-cul-cudl-data-source)
./scripts/load-sample-data.sh

# Upload to a different bucket
./scripts/load-sample-data.sh --bucket my-cudl-data-source
```

### Options

| Flag | Description |
|---|---|
| `--bucket <name>` | Target S3 bucket (default: `development-cul-cudl-data-source`) |
| `--region <region>` | AWS region (default: `eu-west-1`) |
| `--dry-run` | Print what would be uploaded without transferring |

### Prerequisites

- `git` (for sparse checkout)
- AWS CLI authenticated to the development account

---

## copy-lambda-jars.sh

Syncs Lambda JAR artifacts from the source Maven S3 bucket to the destination bucket.

### Workflow

**Step 1** — logged into source account:

```bash
./scripts/copy-lambda-jars.sh --download
```

**Step 2** — logged into destination account:

```bash
./scripts/copy-lambda-jars.sh --upload --dry-run
./scripts/copy-lambda-jars.sh --upload
```

Clean up the local cache afterwards:

```bash
rm -rf /tmp/lambda-jars
```

### Options

| Flag | Description |
|---|---|
| `--download` | Sync source bucket to a local directory |
| `--upload` | Sync local directory to destination bucket |
| `--src-bucket <name>` | Source bucket (default: `cul-cudl.mvn.cudl.lib.cam.ac.uk`) |
| `--dst-bucket <name>` | Destination bucket (default: `cul-cudl.mvn.cul-development.net`) |
| `--local-dir <path>` | Local staging directory (default: `/tmp/lambda-jars`) |
| `--dry-run` | Print what would be uploaded without transferring (upload only) |
