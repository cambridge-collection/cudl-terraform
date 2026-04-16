#!/usr/bin/env bash
# Creates the AWS resources that must exist before 'terraform init' can run
# for a new environment:
#
#   - S3 bucket for Terraform state
#   - DynamoDB table for Terraform state locking
#   - CloudWatch log group consumed by the ECS cluster
#   - S3 bucket for Maven/Lambda JAR artifacts
#
# Run this once per environment in the target AWS account, then run
# ../../scripts/copy-lambda-jars.sh to populate the JAR bucket.
#
# Usage (from repo root):
#   ./new-deployment-template/scripts/bootstrap-environment.sh --env <name> --jar-bucket <bucket> [options]
#
# Example:
#   ./new-deployment-template/scripts/bootstrap-environment.sh --env neworg --jar-bucket cul-cudl.mvn.neworg.example.com

set -euo pipefail

REGION="eu-west-1"
ENV=""
JAR_BUCKET=""
DRY_RUN=false

usage() {
  echo "Usage: $0 --env <name> --jar-bucket <bucket> [--region <region>] [--dry-run]"
  echo ""
  echo "  --env <name>          Environment name, e.g. 'neworg' (used in resource names)"
  echo "  --jar-bucket <name>   S3 bucket name for Lambda JAR artifacts"
  echo "  --region <region>     AWS region (default: eu-west-1)"
  echo "  --dry-run             Print what would be created without making any changes"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --env)        ENV="${2:-}";        [[ -z "$ENV" ]]        && usage; shift 2 ;;
    --jar-bucket) JAR_BUCKET="${2:-}"; [[ -z "$JAR_BUCKET" ]] && usage; shift 2 ;;
    --region)     REGION="${2:-}";     [[ -z "$REGION" ]]     && usage; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$ENV" || -z "$JAR_BUCKET" ]] && usage

# Derived resource names — must match the backend config in the environment's terraform.tf
STATE_BUCKET="cul-cudl-${ENV}-terraform-state"
LOCK_TABLE="terraform-state-lock-cudl-${ENV}"
# Title-case the env name for the log group (e.g. "neworg" → "Neworg")
ENV_TITLE="$(echo "${ENV:0:1}" | tr '[:lower:]' '[:upper:]')${ENV:1}"
LOG_GROUP="/ecs/CUDL-${ENV_TITLE}"

check_auth() {
  echo "Checking AWS credentials ..."
  if ! IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null); then
    echo ""
    echo "ERROR: AWS credentials are invalid or expired."
    echo "       Tip: unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
    exit 1
  fi
  CURRENT_ACCOUNT=$(echo "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
  ARN=$(echo           "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Arn'])")
  ALIAS=$(aws iam list-account-aliases --region "$REGION" \
    --query 'AccountAliases[0]' --output text 2>/dev/null || true)
  [[ -z "$ALIAS" || "$ALIAS" == "None" ]] && ALIAS="(no alias)"
  echo "Account:  $CURRENT_ACCOUNT ($ALIAS)"
  echo "Identity: $ARN"
  echo ""
  read -r -p "Continue with this account? [y/N] " CONFIRM
  [[ "${CONFIRM,,}" != "y" ]] && echo "Aborted." && exit 1
  echo ""
}

create_s3() {
  local bucket="$1" purpose="$2"
  if [[ "$DRY_RUN" == true ]]; then
    echo "  DRY  s3 create: s3://${bucket}  (${purpose})"
    return
  fi
  if aws s3api head-bucket --bucket "$bucket" --region "$REGION" 2>/dev/null; then
    echo "  EXISTS  s3://${bucket}"
  else
    if [[ "$REGION" == "us-east-1" ]]; then
      aws s3api create-bucket \
        --bucket "$bucket" \
        --region "$REGION" \
        --no-cli-pager > /dev/null
    else
      aws s3api create-bucket \
        --bucket "$bucket" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint="$REGION" \
        --no-cli-pager > /dev/null
    fi
    aws s3api put-bucket-versioning \
      --bucket "$bucket" \
      --versioning-configuration Status=Enabled \
      --region "$REGION" \
      --no-cli-pager > /dev/null
    aws s3api put-public-access-block \
      --bucket "$bucket" \
      --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
      --region "$REGION" \
      --no-cli-pager > /dev/null
    echo "  CREATED s3://${bucket}"
  fi
}

check_auth

[[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no resources will be created]" && echo ""

echo "=== Terraform state backend ==="
create_s3 "$STATE_BUCKET" "Terraform state"

echo ""
echo "=== DynamoDB state lock table ==="
if [[ "$DRY_RUN" == true ]]; then
  echo "  DRY  dynamodb create: ${LOCK_TABLE} (LockID pk)"
else
  EXISTING=$(aws dynamodb describe-table \
    --table-name "$LOCK_TABLE" \
    --region "$REGION" \
    --query 'Table.TableName' \
    --output text 2>/dev/null || echo "")
  if [[ "$EXISTING" == "$LOCK_TABLE" ]]; then
    echo "  EXISTS  ${LOCK_TABLE}"
  else
    aws dynamodb create-table \
      --table-name "$LOCK_TABLE" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region "$REGION" \
      --no-cli-pager > /dev/null
    echo "  CREATED ${LOCK_TABLE}"
  fi
fi

echo ""
echo "=== CloudWatch log group ==="
if [[ "$DRY_RUN" == true ]]; then
  echo "  DRY  cloudwatch create: ${LOG_GROUP}"
else
  EXISTING=$(aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --region "$REGION" \
    --query "logGroups[?logGroupName=='${LOG_GROUP}'].logGroupName" \
    --output text 2>/dev/null || echo "")
  if [[ "$EXISTING" == "$LOG_GROUP" ]]; then
    echo "  EXISTS  ${LOG_GROUP}"
  else
    aws logs create-log-group \
      --log-group-name "$LOG_GROUP" \
      --region "$REGION" \
      --no-cli-pager > /dev/null
    aws logs put-retention-policy \
      --log-group-name "$LOG_GROUP" \
      --retention-in-days 90 \
      --region "$REGION" \
      --no-cli-pager > /dev/null
    echo "  CREATED ${LOG_GROUP}"
  fi
fi

echo ""
echo "=== Maven/JAR artifact bucket ==="
create_s3 "$JAR_BUCKET" "Lambda JAR artifacts"

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "Done (dry run)."
else
  echo "Bootstrap complete."
  echo ""
  echo "Next steps:"
  echo "  1. Create a Route53 hosted zone for your domain (if not already done)"
  echo "  2. Copy container images:  ./scripts/copy-ecr-images.sh --pull  (source account)"
  echo "                             ./scripts/copy-ecr-images.sh --push --src-account <id>"
  echo "  3. Copy Lambda JARs:       ./scripts/copy-lambda-jars.sh --download  (source account)"
  echo "                             ./scripts/copy-lambda-jars.sh --upload --dst-bucket ${JAR_BUCKET}"
  echo "  4. Copy SSM parameters:    ./scripts/copy-ssm-params.sh --export params.json --src-env Staging"
  echo "                             ./scripts/copy-ssm-params.sh --import params.json --dst-env ${ENV_TITLE}"
  echo "  5. Update institution.auto.tfvars with Route53 zone IDs and ACM cert ARN"
  echo "  6. Run update-ecr-digests.sh to refresh sha256 digests"
  echo "  7. terraform init && terraform apply --target=module.base_architecture"
  echo "  8. terraform apply"
  echo ""
  echo "Terraform backend config for ${ENV}/terraform.tf:"
  echo "  bucket         = \"${STATE_BUCKET}\""
  echo "  dynamodb_table = \"${LOCK_TABLE}\""
  echo "  cloudwatch_log_group (institution.auto.tfvars) = \"${LOG_GROUP}\""
fi
