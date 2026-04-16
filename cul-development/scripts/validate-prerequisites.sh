#!/usr/bin/env bash
# Pre-flight checks before running 'terraform init' / 'terraform apply'.
#
# Reads configuration from institution.auto.tfvars and terraform.tf in the
# current directory, then verifies every AWS prerequisite exists.
#
# Usage (run from the environment directory, e.g. cul-myorg/ or new-deployment-template/):
#   ./scripts/validate-prerequisites.sh [--region <region>]
#
# Exit code: 0 if all checks pass, 1 if any check fails.

set -euo pipefail

REGION="eu-west-1"
PASS=0
FAIL=0
WARN=0

while [[ $# -gt 0 ]]; do
  case $1 in
    --region) REGION="${2:-}"; shift 2 ;;
    *) echo "Usage: $0 [--region <region>]"; exit 1 ;;
  esac
done

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPTS_DIR")"
INSTITUTION_TFVARS="${TEMPLATE_DIR}/institution.auto.tfvars"
TERRAFORM_TF="${TEMPLATE_DIR}/terraform.tf"

[[ -f "$INSTITUTION_TFVARS" ]] || { echo "ERROR: institution.auto.tfvars not found in $(pwd)"; exit 1; }
[[ -f "$TERRAFORM_TF" ]]       || { echo "ERROR: terraform.tf not found in $(pwd)"; exit 1; }

# ── Helpers ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; NC='\033[0m'

pass()  { echo -e "  ${GREEN}PASS${NC}  $1"; (( PASS++ )) || true; }
fail()  { echo -e "  ${RED}FAIL${NC}  $1"; (( FAIL++ )) || true; }
warn()  { echo -e "  ${YELLOW}WARN${NC}  $1"; (( WARN++ )) || true; }
header(){ echo ""; echo "── $1 ──────────────────────────────────────────────"; }

# Read a value from institution.auto.tfvars
tfvar() {
  grep -E "^${1}\s*=" "$INSTITUTION_TFVARS" \
    | sed 's/.*=\s*"\(.*\)".*/\1/' | head -1 || echo ""
}

# Read a value from terraform.tf (backend block)
tfbackend() {
  grep -E "${1}\s*=" "$TERRAFORM_TF" \
    | sed 's/.*=\s*"\(.*\)".*/\1/' | head -1 || echo ""
}

# ── Read config ───────────────────────────────────────────────────────────────
ENV=$(tfvar environment)
DOMAIN=$(tfvar registered_domain_name | sed 's/\.$//')  # strip trailing dot
ZONE_ID=$(tfvar route53_zone_id_existing)
ACM_ARN=$(tfvar acm_certificate_arn)
JAR_BUCKET=$(tfvar lambda-jar-bucket)
LOG_GROUP=$(tfvar cloudwatch_log_group)
LOG_DEST=$(tfvar cloudwatch_log_destination_arn)
STATE_BUCKET=$(tfbackend bucket)
LOCK_TABLE=$(tfbackend dynamodb_table)

echo "Validating prerequisites for environment: ${ENV:-<unset>}"
echo "Region: $REGION"

# ── 1. No FIXME placeholders left in institution.auto.tfvars ──────────────────
header "institution.auto.tfvars"

FIXME_COUNT=$(grep -v "^\s*#" "$INSTITUTION_TFVARS" 2>/dev/null | grep -c "FIXME" || true)
if [[ "$FIXME_COUNT" -gt 0 ]]; then
  fail "${FIXME_COUNT} FIXME placeholder(s) still in institution.auto.tfvars:"
  grep -v "^\s*#" "$INSTITUTION_TFVARS" | grep -n "FIXME" | while read -r line; do
    echo "         $line"
  done
else
  pass "No FIXME placeholders in institution.auto.tfvars"
fi

# ── 2. AWS credentials ────────────────────────────────────────────────────────
header "AWS credentials"

IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null) || {
  fail "AWS credentials invalid or expired"
  echo ""
  echo "Cannot continue without valid credentials."
  echo "Tip: unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
  exit 1
}
ACCOUNT=$(echo "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
ARN=$(echo     "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Arn'])")
pass "Authenticated as $ARN"

# ── 3. Terraform state backend ────────────────────────────────────────────────
header "Terraform state backend"

if [[ -z "$STATE_BUCKET" ]]; then
  fail "Could not read state bucket name from terraform.tf"
else
  if aws s3api head-bucket --bucket "$STATE_BUCKET" --region "$REGION" 2>/dev/null; then
    pass "S3 state bucket exists: $STATE_BUCKET"
  else
    fail "S3 state bucket missing: $STATE_BUCKET  (run ./scripts/bootstrap-environment.sh)"
  fi
fi

if [[ -z "$LOCK_TABLE" ]]; then
  fail "Could not read DynamoDB table name from terraform.tf"
else
  TABLE_STATUS=$(aws dynamodb describe-table \
    --table-name "$LOCK_TABLE" --region "$REGION" \
    --query 'Table.TableStatus' --output text 2>/dev/null || echo "")
  if [[ "$TABLE_STATUS" == "ACTIVE" ]]; then
    pass "DynamoDB lock table exists: $LOCK_TABLE"
  else
    fail "DynamoDB lock table missing: $LOCK_TABLE  (run ./scripts/bootstrap-environment.sh)"
  fi
fi

# ── 4. CloudWatch log group ───────────────────────────────────────────────────
header "CloudWatch log group"

if [[ -z "$LOG_GROUP" ]]; then
  fail "cloudwatch_log_group not set in institution.auto.tfvars"
else
  EXISTING_LG=$(aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" --region "$REGION" \
    --query "logGroups[?logGroupName=='${LOG_GROUP}'].logGroupName" \
    --output text 2>/dev/null || echo "")
  if [[ "$EXISTING_LG" == "$LOG_GROUP" ]]; then
    pass "CloudWatch log group exists: $LOG_GROUP"
  else
    fail "CloudWatch log group missing: $LOG_GROUP  (run ./scripts/bootstrap-environment.sh)"
  fi
fi

# ── 5. Route53 hosted zone ────────────────────────────────────────────────────
header "Route53 hosted zone"

if [[ -z "$ZONE_ID" || "$ZONE_ID" == *"FIXME"* ]]; then
  fail "route53_zone_id_existing not set in institution.auto.tfvars"
else
  ZONE_NAME=$(aws route53 get-hosted-zone \
    --id "$ZONE_ID" \
    --query 'HostedZone.Name' --output text 2>/dev/null || echo "")
  if [[ -n "$ZONE_NAME" ]]; then
    pass "Route53 zone exists: $ZONE_ID ($ZONE_NAME)"
  else
    fail "Route53 zone not found: $ZONE_ID"
  fi
fi

# ── 6. ACM certificate ────────────────────────────────────────────────────────
header "ACM certificate (eu-west-1)"

if [[ -z "$ACM_ARN" || "$ACM_ARN" == *"FIXME"* ]]; then
  fail "acm_certificate_arn not set in institution.auto.tfvars"
else
  CERT_STATUS=$(aws acm describe-certificate \
    --certificate-arn "$ACM_ARN" --region "$REGION" \
    --query 'Certificate.Status' --output text 2>/dev/null || echo "")
  case "$CERT_STATUS" in
    ISSUED)           pass "ACM certificate ISSUED: $ACM_ARN" ;;
    PENDING_VALIDATION) warn "ACM certificate PENDING_VALIDATION — DNS records may not be propagated yet" ;;
    "")               fail "ACM certificate not found: $ACM_ARN" ;;
    *)                fail "ACM certificate status is $CERT_STATUS: $ACM_ARN" ;;
  esac
fi

# ── 7. Lambda JAR bucket ──────────────────────────────────────────────────────
header "Lambda JAR bucket"

if [[ -z "$JAR_BUCKET" ]]; then
  fail "lambda-jar-bucket not set in institution.auto.tfvars"
else
  if aws s3api head-bucket --bucket "$JAR_BUCKET" --region "$REGION" 2>/dev/null; then
    # Check that at least one JAR exists
    JAR_COUNT=$(aws s3 ls "s3://${JAR_BUCKET}/release/" --recursive --region "$REGION" \
      2>/dev/null | grep -c "\.jar$" || true)
    if [[ "$JAR_COUNT" -gt 0 ]]; then
      pass "JAR bucket exists with ${JAR_COUNT} JAR(s): $JAR_BUCKET"
    else
      warn "JAR bucket exists but contains no JARs — run scripts/copy-lambda-jars.sh"
    fi
  else
    fail "JAR bucket missing: $JAR_BUCKET  (run ./scripts/bootstrap-environment.sh)"
  fi
fi

# ── 8. ECR repositories ───────────────────────────────────────────────────────
header "ECR repositories"

ECR_REPOS=(
  "cudl/content-loader-db"
  "cudl/content-loader-ui"
  "cudl/solr-api"
  "cudl/solr"
  "cudl/services"
  "cudl/viewer"
  "cudl/tei-processing"
  "cudl/solr-listener"
)

REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
for REPO in "${ECR_REPOS[@]}"; do
  IMAGE_COUNT=$(aws ecr describe-images \
    --repository-name "$REPO" --region "$REGION" \
    --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
  if [[ "$IMAGE_COUNT" == "0" || -z "$IMAGE_COUNT" ]]; then
    fail "ECR repo empty or missing: $REPO  (run scripts/copy-ecr-images.sh)"
  else
    pass "ECR repo has images: $REPO (${IMAGE_COUNT} image(s))"
  fi
done

# ── 9. SSM Parameter Store ────────────────────────────────────────────────────
header "SSM Parameter Store"

# Title-case the env name for SSM paths (e.g. development → Development)
ENV_TITLE="$(echo "${ENV:0:1}" | tr '[:lower:]' '[:upper:]')${ENV:1}"

SSM_PARAMS=(
  "/Environments/${ENV_TITLE}/CUDL/Services/DB/Password"
  "/Environments/${ENV_TITLE}/CUDL/Services/APIKey/Viewer"
  "/Environments/${ENV_TITLE}/CUDL/Services/APIKey/Darwin"
  "/Environments/${ENV_TITLE}/CUDL/Services/BasicAuth/Credentials"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/SMTP/Username"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/SMTP/Password"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/SMTP/Port"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/CloudFront/Username"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/CloudFront/Password"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/Recaptcha/Sitekey"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/Recaptcha/Secretkey"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/Google/AnalyticsId"
  "/Environments/${ENV_TITLE}/CUDL/Viewer/Google/GA4AnalyticsId"
)

for PARAM in "${SSM_PARAMS[@]}"; do
  EXISTS=$(aws ssm get-parameter \
    --name "$PARAM" --region "$REGION" \
    --query 'Parameter.Name' --output text 2>/dev/null || echo "")
  if [[ -n "$EXISTS" ]]; then
    pass "SSM parameter exists: $PARAM"
  else
    fail "SSM parameter missing: $PARAM  (run scripts/copy-ssm-params.sh)"
  fi
done

# ── 10. CloudWatch log destination (optional) ─────────────────────────────────
header "CloudWatch log destination (optional)"

if [[ -z "$LOG_DEST" || "$LOG_DEST" == *"FIXME"* ]]; then
  warn "cloudwatch_log_destination_arn not set — log forwarding disabled"
else
  # Just check the ARN format looks plausible; we can't describe cross-account destinations
  if [[ "$LOG_DEST" =~ ^arn:aws:logs: ]]; then
    pass "cloudwatch_log_destination_arn is set (cross-account, cannot verify reachability)"
  else
    fail "cloudwatch_log_destination_arn doesn't look like a valid ARN: $LOG_DEST"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL + WARN))
echo "Results: ${PASS} passed, ${FAIL} failed, ${WARN} warnings  (${TOTAL} checks)"

if [[ "$FAIL" -gt 0 ]]; then
  echo -e "${RED}Not ready — fix the failures above before running terraform.${NC}"
  exit 1
elif [[ "$WARN" -gt 0 ]]; then
  echo -e "${YELLOW}Ready with warnings — review them before proceeding.${NC}"
  echo ""
  echo "Next: terraform init && terraform apply --target=module.base_architecture"
else
  echo -e "${GREEN}All checks passed — ready to deploy.${NC}"
  echo ""
  echo "Next: terraform init && terraform apply --target=module.base_architecture"
fi
echo "════════════════════════════════════════════════════════════"
