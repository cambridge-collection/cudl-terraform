#!/usr/bin/env bash
# After running copy-ecr-images.sh --push, refreshes all pinned ECR image digests in:
#
#   - <env-dir>/institution.auto.tfvars  — ECS service ECR repository maps
#   - <env-dir>/terraform.tfvars         — Lambda image_uri values
#   - scripts/copy-ecr-images.sh         — PINNED associative array
#
# Queries the current account's ECR registry for the :latest digest of each image,
# then patches those three files in place.
#
# Usage (run from any environment directory that has institution.auto.tfvars):
#   ./scripts/update-ecr-digests.sh [--region <region>] [--dry-run]

set -euo pipefail

REGION="eu-west-1"
DRY_RUN=false

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPTS_DIR")"
REPO_ROOT="$(dirname "$TEMPLATE_DIR")"

usage() {
  echo "Usage: $0 [--region <region>] [--dry-run]"
  echo ""
  echo "  --region <region>  AWS region (default: eu-west-1)"
  echo "  --dry-run          Show what would change without modifying files"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --region)  REGION="${2:-}"; [[ -z "$REGION" ]] && usage; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

INSTITUTION_TFVARS="${TEMPLATE_DIR}/institution.auto.tfvars"
MAIN_TFVARS="${TEMPLATE_DIR}/terraform.tfvars"
ECR_SCRIPT="${REPO_ROOT}/scripts/copy-ecr-images.sh"

for f in "$INSTITUTION_TFVARS" "$MAIN_TFVARS" "$ECR_SCRIPT"; do
  [[ -f "$f" ]] || { echo "ERROR: file not found: $f"; exit 1; }
done

# ── Auth check ─────────────────────────────────────────────────────────────────
echo "Checking AWS credentials ..."
IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null) || {
  echo "ERROR: AWS credentials invalid or expired."
  echo "       Tip: unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
  exit 1
}
ACCOUNT=$(echo "$IDENTITY" | python3 -c "import sys,json; print(json.load(sys.stdin)['Account'])")
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
echo "Account:  $ACCOUNT"
echo "Registry: $REGISTRY"
echo ""
[[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no files will be modified]" && echo ""

# ── Repos ──────────────────────────────────────────────────────────────────────
# ECS service images — digests live in institution.auto.tfvars *_ecr_repositories maps
ECS_REPOS=(
  "cudl/content-loader-db"
  "cudl/content-loader-ui"
  "cudl/solr-api"
  "cudl/solr"
  "cudl/services"
  "cudl/viewer"
)

# Lambda container images — digests live in terraform.tfvars transform-lambda-information image_uri values
LAMBDA_REPOS=(
  "cudl/tei-processing"
  "cudl/solr-listener"
  "cudl/transkribus-processing"
)

ALL_REPOS=("${ECS_REPOS[@]}" "${LAMBDA_REPOS[@]}")

# ── Collect latest digests from ECR ───────────────────────────────────────────
declare -A DIGESTS

echo "Querying ECR for latest digests ..."
for REPO in "${ALL_REPOS[@]}"; do
  printf "  %-40s" "${REPO} ..."
  DIGEST=$(aws ecr describe-images \
    --region "$REGION" \
    --repository-name "$REPO" \
    --image-ids imageTag=latest \
    --query 'imageDetails[0].imageDigest' \
    --output text 2>/dev/null || echo "")
  if [[ -z "$DIGEST" || "$DIGEST" == "None" ]]; then
    echo "SKIP (no :latest tag in ECR)"
    continue
  fi
  DIGESTS["$REPO"]="$DIGEST"
  echo "${DIGEST:0:19}..."
done
echo ""

if [[ ${#DIGESTS[@]} -eq 0 ]]; then
  echo "No digests found. Make sure copy-ecr-images.sh --push has been run first."
  exit 1
fi

# ── Helper: literal string replacement with dry-run support ───────────────────
# Uses Python str.replace to avoid sed regex interpretation of special chars.
patch_file() {
  local file="$1" old="$2" new="$3" label="$4"
  if grep -qF "$old" "$file" 2>/dev/null; then
    if [[ "$DRY_RUN" == true ]]; then
      echo "  WOULD UPDATE  ${label}"
    else
      python3 - "$file" "$old" "$new" <<'PYEOF'
import sys
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()
open(path, 'w').write(content.replace(old, new))
PYEOF
      echo "  UPDATED  ${label}"
    fi
  else
    echo "  SKIP (entry not found): ${label}"
  fi
}

# ── Update institution.auto.tfvars — ECS ECR repository maps ──────────────────
# Uses Python regex to handle variable whitespace between key and = (alignment padding).
# Matches both existing sha256 digests and FIXME placeholder values.
echo "Patching ${INSTITUTION_TFVARS##*/} ..."
for REPO in "${ECS_REPOS[@]}"; do
  [[ -z "${DIGESTS[$REPO]+x}" ]] && continue
  NEW="${DIGESTS[$REPO]}"
  FOUND=$(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
pattern = r'\"' + re.escape(sys.argv[2]) + r'\"\s*=\s*\"[^\"]*\"'
print('yes' if re.search(pattern, content) else 'no')
" "$INSTITUTION_TFVARS" "$REPO")
  if [[ "$FOUND" != "yes" ]]; then
    echo "  SKIP (entry not found): ${REPO}"
    continue
  fi
  if [[ "$DRY_RUN" == true ]]; then
    echo "  WOULD UPDATE  ${REPO}"
  else
    python3 - "$INSTITUTION_TFVARS" "$REPO" "$NEW" <<'PYEOF'
import re, sys
path, repo, new_digest = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()
content = re.sub(
    r'("' + re.escape(repo) + r'"\s*=\s*)"[^"]*"',
    r'\g<1>"' + new_digest + '"',
    content
)
open(path, 'w').write(content)
PYEOF
    echo "  UPDATED  ${REPO}"
  fi
done
echo ""

# ── Update terraform.tfvars — Lambda image_uri values ─────────────────────────
# Matches image_uri values containing the repo name (handles real account IDs and ACCOUNT_ID placeholder).
echo "Patching ${MAIN_TFVARS##*/} ..."
for REPO in "${LAMBDA_REPOS[@]}"; do
  [[ -z "${DIGESTS[$REPO]+x}" ]] && continue
  NEW_URI="${REGISTRY}/${REPO}@${DIGESTS[$REPO]}"
  FOUND=$(python3 -c "
import re, sys
content = open(sys.argv[1]).read()
print('yes' if re.search(r'\"image_uri\"\s*=\s*\"[^\"]*' + re.escape(sys.argv[2]) + r'[^\"]*\"', content) else 'no')
" "$MAIN_TFVARS" "$REPO")
  if [[ "$FOUND" != "yes" ]]; then
    echo "  SKIP (entry not found): ${REPO}"
    continue
  fi
  if [[ "$DRY_RUN" == true ]]; then
    echo "  WOULD UPDATE  ${REPO}"
  else
    python3 - "$MAIN_TFVARS" "$REPO" "$NEW_URI" <<'PYEOF'
import re, sys
path, repo, new_uri = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()
content = re.sub(
    r'("image_uri"\s*=\s*)"[^"]*' + re.escape(repo) + r'[^"]*"',
    r'\g<1>"' + new_uri + '"',
    content
)
open(path, 'w').write(content)
PYEOF
    echo "  UPDATED  ${REPO}"
  fi
done
echo ""

# ── Update copy-ecr-images.sh — PINNED associative array ─────────────────────
# Pattern:  ["cudl/repo-name"]="sha256:HEX"
echo "Patching ${ECR_SCRIPT##*/} ..."
for REPO in "${ALL_REPOS[@]}"; do
  [[ -z "${DIGESTS[$REPO]+x}" ]] && continue
  NEW="${DIGESTS[$REPO]}"
  OLD_DIGEST=$(grep -oE "\[\"${REPO}\"\]=\"sha256:[0-9a-f]+\"" "$ECR_SCRIPT" \
    | grep -oE 'sha256:[0-9a-f]+' | head -1 || echo "")
  if [[ -z "$OLD_DIGEST" ]]; then
    echo "  SKIP (entry not found): ${REPO}"
    continue
  fi
  patch_file "$ECR_SCRIPT" \
    "[\"${REPO}\"]=\"${OLD_DIGEST}\"" \
    "[\"${REPO}\"]=\"${NEW}\"" \
    "${REPO}"
done
echo ""

if [[ "$DRY_RUN" == true ]]; then
  echo "Done (dry run). Re-run without --dry-run to apply."
else
  echo "Done. Review changes with 'git diff' then run 'terraform plan' to verify."
fi
