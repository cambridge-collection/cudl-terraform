#!/usr/bin/env bash
# Loads sample CUDL source data from the dl-data-samples GitHub repository into
# the cul-cudl-data-source S3 bucket, ready for the Lambda processing pipeline.
#
# Source repository: https://github.com/cambridge-collection/dl-data-samples
# Source path:       source-data/data/
#
# Two files are renamed on upload because the pipeline expects canonical names:
#   sample.dl-dataset.json  →  cudl.dl-dataset.json
#   sample.ui.json5         →  cudl.ui.json5
#
# Usage:
#   ./load-sample-data.sh [--bucket <name>] [--region <region>] [--dry-run]
#
# Requires: git, aws CLI

set -euo pipefail

REGION="eu-west-1"
DEFAULT_BUCKET="development-cul-cudl-data-source"
REPO_URL="https://github.com/cambridge-collection/dl-data-samples"
REPO_SUBDIR="source-data/data"

usage() {
  echo "Usage: $0 [--bucket <name>] [--region <region>] [--dry-run]"
  echo ""
  echo "Defaults:"
  echo "  --bucket  $DEFAULT_BUCKET"
  echo "  --region  $REGION"
  exit 1
}

check_auth() {
  echo "Checking credentials..."
  if ! IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null); then
    echo ""
    echo "ERROR: AWS credentials are invalid or expired."
    echo "       Run 'aws sts get-caller-identity' directly to diagnose."
    echo ""
    echo "Tip: stale environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,"
    echo "     AWS_SESSION_TOKEN) override your login. Unset them and try again:"
    echo "     unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
    exit 1
  fi
  ACCOUNT=$(echo "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
  ARN=$(echo     "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Arn'])")
  ALIAS=$(aws iam list-account-aliases --region "$REGION" --query 'AccountAliases[0]' --output text 2>/dev/null || true)
  [[ -z "$ALIAS" || "$ALIAS" == "None" ]] && ALIAS="(no alias)"
  echo "Account:  $ACCOUNT ($ALIAS)"
  echo "Identity: $ARN"
  echo ""
  read -r -p "Continue with this account? [y/N] " CONFIRM
  [[ "${CONFIRM,,}" != "y" ]] && echo "Aborted." && exit 1
  echo ""
}

BUCKET="$DEFAULT_BUCKET"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --bucket)   BUCKET="${2:-}";  [[ -z "$BUCKET" ]] && usage; shift 2 ;;
    --region)   REGION="${2:-}";  [[ -z "$REGION" ]] && usage; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help|-h)  usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no files will be uploaded]" && echo ""

check_auth

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Cloning sample data from ${REPO_URL} ..."
git clone \
  --depth=1 \
  --filter=blob:none \
  --sparse \
  --quiet \
  "$REPO_URL" \
  "$WORK_DIR/repo"

cd "$WORK_DIR/repo"
git sparse-checkout set "$REPO_SUBDIR"
cd - > /dev/null

DATA_DIR="$WORK_DIR/repo/$REPO_SUBDIR"

# Rename sample.* files to the canonical names expected by the pipeline
mv "$DATA_DIR/sample.dl-dataset.json" "$DATA_DIR/cudl.dl-dataset.json"
mv "$DATA_DIR/sample.ui.json5"        "$DATA_DIR/cudl.ui.json5"

# The sample HTML files use editing-system image paths (/edit/source/pages/images/...)
# The HTML URL-translate Lambda expects relative paths (../images/...) from the
# pages/html/ directory, which it resolves to pages/images/X then rewrites to /images/X.
find "$DATA_DIR/pages/html" -name "*.html" -exec \
  sed -i 's|/edit/source/pages/images/|../images/|g' {} +

# The FILE_UNCHANGED_COPY Lambda skips files <= 412 bytes (hardcoded threshold
# in S3Output.writeFromStream). Pad cudl.dl-dataset.json if it is too small.
python3 - "$DATA_DIR/cudl.dl-dataset.json" <<'EOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
if len(open(path).read().encode()) <= 412:
    data.setdefault("description", "Sample dataset for CUDL development environment. Contains test collections and items for validating the data processing pipeline.")
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
EOF

echo "Uploading to s3://${BUCKET} ..."
echo ""

CP_ARGS=(
  "$DATA_DIR"
  "s3://${BUCKET}"
  --recursive
  --region "$REGION"
  --no-progress
)
[[ "$DRY_RUN" == true ]] && CP_ARGS+=(--dryrun)

aws s3 cp "${CP_ARGS[@]}"

echo ""
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. Run without --dry-run to upload."
else
  echo "Done. Sample data loaded into s3://${BUCKET}"
  echo ""
  echo "The Lambda processing pipeline will trigger automatically via SQS"
  echo "notifications on the bucket. Check Lambda logs for progress:"
  echo "  Log group: /aws/lambda/development-AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY"
fi
