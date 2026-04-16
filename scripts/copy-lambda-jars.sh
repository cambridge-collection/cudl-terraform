#!/usr/bin/env bash
# Copies Lambda JAR artifacts from the source Maven S3 bucket to the destination bucket.
#
# Two-step workflow — log into each account separately:
#
#   Step 1 — logged into source account:
#     ./copy-lambda-jars.sh --download [--src-bucket <name>] [--local-dir <path>]
#
#   Step 2 — logged into destination account:
#     ./copy-lambda-jars.sh --upload [--dst-bucket <name>] [--local-dir <path>] [--dry-run]

set -euo pipefail

REGION="eu-west-1"
DEFAULT_SRC_BUCKET="cul-cudl.mvn.cudl.lib.cam.ac.uk"
DEFAULT_DST_BUCKET="cul-cudl.mvn.cul-development.net"
DEFAULT_LOCAL_DIR="/tmp/lambda-jars"

usage() {
  echo "Usage:"
  echo "  $0 --download [--src-bucket <name>] [--local-dir <path>]"
  echo "  $0 --upload   [--dst-bucket <name>] [--local-dir <path>] [--dry-run]"
  echo ""
  echo "Defaults:"
  echo "  --src-bucket  $DEFAULT_SRC_BUCKET"
  echo "  --dst-bucket  $DEFAULT_DST_BUCKET"
  echo "  --local-dir   $DEFAULT_LOCAL_DIR"
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

[[ $# -eq 0 ]] && usage

MODE=""
SRC_BUCKET="$DEFAULT_SRC_BUCKET"
DST_BUCKET="$DEFAULT_DST_BUCKET"
LOCAL_DIR="$DEFAULT_LOCAL_DIR"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --download)   MODE="download"; shift ;;
    --upload)     MODE="upload"; shift ;;
    --src-bucket) SRC_BUCKET="${2:-}"; [[ -z "$SRC_BUCKET" ]] && usage; shift 2 ;;
    --dst-bucket) DST_BUCKET="${2:-}"; [[ -z "$DST_BUCKET" ]] && usage; shift 2 ;;
    --local-dir)  LOCAL_DIR="${2:-}";  [[ -z "$LOCAL_DIR" ]]  && usage; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$MODE" ]] && usage

check_auth

case "$MODE" in

  download)
    echo "Downloading s3://${SRC_BUCKET} -> ${LOCAL_DIR} ..."
    echo ""
    mkdir -p "$LOCAL_DIR"
    aws s3 sync \
      "s3://${SRC_BUCKET}" \
      "$LOCAL_DIR" \
      --region "$REGION" \
      --no-progress
    echo ""
    echo "Download complete: $(du -sh "$LOCAL_DIR" | cut -f1) in $LOCAL_DIR"
    echo "Now log into the destination account and run:"
    echo "  $0 --upload --dst-bucket ${DST_BUCKET} --local-dir ${LOCAL_DIR}"
    ;;

  upload)
    [[ ! -d "$LOCAL_DIR" ]] && echo "ERROR: Local directory not found: $LOCAL_DIR" && echo "       Run --download first." && exit 1
    echo "Uploading ${LOCAL_DIR} -> s3://${DST_BUCKET} ..."
    echo ""
    SYNC_ARGS=(
      "$LOCAL_DIR"
      "s3://${DST_BUCKET}"
      --region "$REGION"
      --no-progress
    )
    [[ "$DRY_RUN" == true ]] && SYNC_ARGS+=(--dryrun) && echo "[DRY RUN]" && echo ""
    aws s3 sync "${SYNC_ARGS[@]}"
    echo ""
    if [[ "$DRY_RUN" == false ]]; then
      echo "Upload complete."
      echo "You can now delete the local copy if no longer needed:"
      echo "  rm -rf ${LOCAL_DIR}"
    fi
    ;;

esac
