#!/usr/bin/env bash
# Creates ECR repositories in the current account and copies latest images from a source account.
#
# Two-step workflow — log into each account separately:
#
#   Step 1 — logged into source account:
#     ./copy-ecr-images.sh --pull [--region <region>]
#
#   Step 2 — logged into destination account:
#     ./copy-ecr-images.sh --push --src-account <id> [--region <region>] [--dry-run]

set -euo pipefail

REGION="eu-west-1"

# Repos to copy as :latest
REPOS=(
  "cudl/content-loader-db"
  "cudl/content-loader-ui"
  "cudl/solr-api"
  "cudl/solr"
  "cudl/services"
  "cudl/viewer"
  "cudl/tei-processing"
  "cudl/solr-listener"
  "cudl/transkribus-processing"
)

# Specific digests required by terraform.tfvars (*_ecr_repositories values).
# These are copied in addition to :latest to ensure Terraform can resolve them.
# Update when pinned versions in tfvars change.
declare -A PINNED=(
  ["cudl/content-loader-db"]="sha256:db3975d626e80ad1de43f97f95997854f4c4b63ea8c71e1dbf40ce0c89455631"
  ["cudl/content-loader-ui"]="sha256:39e4885b8e9f6e1b25df52f73ff71f018e8b1cfa5f0b8e310cbe8672d4b9b19a"
  ["cudl/solr-api"]="sha256:38e68886cf61cb563de3ad8611f3c708816f78605f43540ffa2e0a9652bb73af"
  ["cudl/solr"]="sha256:9c144888d9a51757a8732a457e0f712d397ec25143a9caded6661a3e880b031d"
  ["cudl/services"]="sha256:bc86da808e1420fde49196cdbc12251f1e79ba5dc3f0c5a68e4e197ebe1c7902"
  ["cudl/viewer"]="sha256:89f506db9ee6d75ccf93602cf5ba7a9b58d2bbe62193b8d7d8a994a62453b320"
  ["cudl/tei-processing"]="sha256:7542d95eaf257409741eb1338e20069e002502f7702ad8820fefad6f15d363fd"
  ["cudl/solr-listener"]="sha256:1bef571e90e2c78c78f847d611cf60be91d734065cd951358aa848f1c74a3b0d"
  ["cudl/transkribus-processing"]="sha256:03cf5047a7ddd72163edc8081e7cfad652c6072daa91d0ab941fc96b4d481a40"
)

usage() {
  echo "Usage:"
  echo "  $0 --pull [--region <region>]"
  echo "  $0 --push --src-account <account-id> [--region <region>] [--dry-run]"
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
  CURRENT_ACCOUNT=$(echo "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
  ARN=$(echo           "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Arn'])")
  ALIAS=$(aws iam list-account-aliases --region "$REGION" --query 'AccountAliases[0]' --output text 2>/dev/null || true)
  [[ -z "$ALIAS" || "$ALIAS" == "None" ]] && ALIAS="(no alias)"
  echo "Account:  $CURRENT_ACCOUNT ($ALIAS)"
  echo "Identity: $ARN"
  echo ""
  read -r -p "Continue with this account? [y/N] " CONFIRM
  [[ "${CONFIRM,,}" != "y" ]] && echo "Aborted." && exit 1
  echo ""
}

ecr_login() {
  local registry="$1"
  echo "Logging Docker into ${registry} ..."
  aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$registry"
  echo ""
}

[[ $# -eq 0 ]] && usage

MODE=""
SRC_ACCOUNT=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --pull)        MODE="pull"; shift ;;
    --push)        MODE="push"; shift ;;
    --src-account) SRC_ACCOUNT="${2:-}"; [[ -z "$SRC_ACCOUNT" ]] && usage; shift 2 ;;
    --region)      REGION="${2:-}";      [[ -z "$REGION" ]]      && usage; shift 2 ;;
    --dry-run)     DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$MODE" ]] && usage
[[ "$MODE" == "push" && -z "$SRC_ACCOUNT" ]] && echo "ERROR: --push requires --src-account" && usage

check_auth

case "$MODE" in

  pull)
    SRC_REGISTRY="${CURRENT_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
    ecr_login "$SRC_REGISTRY"
    echo "Pulling ${#REPOS[@]} :latest images and ${#PINNED[@]} pinned digests from ${SRC_REGISTRY} ..."
    echo ""
    for REPO in "${REPOS[@]}"; do
      SRC="${SRC_REGISTRY}/${REPO}:latest"
      echo "  Pulling ${REPO}:latest ..."
      docker pull "$SRC"
      echo ""
    done
    for REPO in "${!PINNED[@]}"; do
      DIGEST="${PINNED[$REPO]}"
      SRC="${SRC_REGISTRY}/${REPO}@${DIGEST}"
      echo "  Pulling ${REPO}@${DIGEST:0:19} ..."
      docker pull "$SRC"
      echo ""
    done
    echo "All images pulled locally."
    echo "Now log into the destination account and run:"
    echo "  $0 --push --src-account ${CURRENT_ACCOUNT}"
    ;;

  push)
    DST_REGISTRY="${CURRENT_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
    SRC_REGISTRY="${SRC_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
    [[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no creates or pushes will occur]" && echo ""

    echo "Creating ECR repositories in account ${CURRENT_ACCOUNT} ..."
    for REPO in "${REPOS[@]}"; do
      if [[ "$DRY_RUN" == true ]]; then
        echo "  DRY   create repo: ${REPO}"
        continue
      fi
      EXISTING=$(aws ecr describe-repositories \
        --region "$REGION" \
        --repository-names "$REPO" \
        --query "repositories[0].repositoryName" \
        --output text 2>/dev/null || echo "")
      if [[ "$EXISTING" == "$REPO" ]]; then
        echo "  EXISTS  ${REPO}"
      else
        aws ecr create-repository \
          --region "$REGION" \
          --repository-name "$REPO" \
          --image-scanning-configuration scanOnPush=true \
          --no-cli-pager > /dev/null
        echo "  CREATED ${REPO}"
      fi
    done
    echo ""

    [[ "$DRY_RUN" == true ]] && echo "Done (dry run)." && exit 0

    ecr_login "$DST_REGISTRY"

    echo "Tagging and pushing :latest images to ${DST_REGISTRY} ..."
    echo ""
    for REPO in "${REPOS[@]}"; do
      SRC="${SRC_REGISTRY}/${REPO}:latest"
      DST="${DST_REGISTRY}/${REPO}:latest"
      echo "  Pushing ${REPO}:latest ..."
      docker tag  "$SRC" "$DST"
      docker push "$DST"
      echo "  OK  ${DST}"
      echo ""
    done

    echo "Tagging and pushing pinned digests to ${DST_REGISTRY} ..."
    echo ""
    for REPO in "${!PINNED[@]}"; do
      DIGEST="${PINNED[$REPO]}"
      SRC="${SRC_REGISTRY}/${REPO}@${DIGEST}"
      SHORT="${DIGEST:7:12}"
      DST="${DST_REGISTRY}/${REPO}:pinned-${SHORT}"
      echo "  Pushing ${REPO}@${DIGEST:0:19} ..."
      docker tag  "$SRC" "$DST"
      docker push "$DST"
      echo "  OK  digest available in ${DST_REGISTRY}/${REPO}"
      echo ""
    done

    echo "All images pushed."
    ;;

esac
