#!/usr/bin/env bash
# Packages ECR images as .tar.gz files for manual transfer (e.g. via OneDrive),
# then loads and pushes them in a target account.
#
# Use this when direct ECR-to-ECR copying is not possible — for example when
# the target account has no outbound internet access or the two accounts have
# no shared network path.
#
# Two-step workflow:
#
#   Step 1 — logged into SOURCE account:
#     ./scripts/package-ecr-images.sh --export --src-account <id> \
#                                     [--output-dir ./ecr-export]  \
#                                     [--region <region>]
#
#   Step 2 — upload the output directory to OneDrive
#
#   Step 3 — download the folder, then logged into TARGET account:
#     ./scripts/package-ecr-images.sh --load --input-dir ./ecr-export \
#                                     [--region <region>] [--dry-run]
#
#   Step 4 — refresh pinned digests in tfvars:
#     cd cul-<env> && ./scripts/update-ecr-digests.sh

set -euo pipefail

REGION="eu-west-1"
OUTPUT_DIR=""
INPUT_DIR=""
SRC_ACCOUNT=""
DRY_RUN=false
MINIMAL=false
MODE=""

# ── Image list (keep in sync with copy-ecr-images.sh) ────────────────────────

# All images available in the source account
REPOS_ALL=(
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

# Minimal set: images directly referenced by Terraform (ECS tasks + Lambda containers).
# Excludes cudl/transkribus-processing which is not used in any environment config.
REPOS_MINIMAL=(
  "cudl/content-loader-db"
  "cudl/content-loader-ui"
  "cudl/solr-api"
  "cudl/solr"
  "cudl/services"
  "cudl/viewer"
  "cudl/tei-processing"
  "cudl/solr-listener"
)

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

# ── Helpers ───────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage:
  $0 --export --src-account <id> [--output-dir <dir>] [--minimal] [--region <region>]
  $0 --load   --input-dir   <dir> [--region <region>] [--dry-run]

--export  Pull images from source ECR and save as .tar.gz files ready for upload.
--load    Load .tar.gz files from a downloaded folder and push to target ECR.

Options:
  --src-account <id>   Source AWS account ID (required for --export)
  --output-dir  <dir>  Where to write .tar.gz files (default: ecr-export[-minimal]-YYYYMMDD-HHMMSS)
  --input-dir   <dir>  Folder containing .tar.gz files and manifest.json (required for --load)
  --minimal            Export only the 8 images required by Terraform; omits cudl/transkribus-processing
  --region      <reg>  AWS region (default: eu-west-1)
  --dry-run            Show what would happen without pulling, loading, or pushing
EOF
  exit 1
}

# cudl/content-loader-db  →  cudl-content-loader-db
repo_to_flat() { echo "${1//\//-}"; }

check_auth() {
  echo "Checking credentials..."
  if ! IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null); then
    echo ""
    echo "ERROR: AWS credentials are invalid or expired."
    echo "       Unset stale env vars and try again:"
    echo "       unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
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

ecr_login() {
  local registry="$1"
  echo "Logging Docker into ${registry} ..."
  aws ecr get-login-password --region "$REGION" \
    | docker login --username AWS --password-stdin "$registry"
  echo ""
}

ensure_ecr_repo() {
  local repo="$1"
  local existing
  existing=$(aws ecr describe-repositories \
    --region "$REGION" \
    --repository-names "$repo" \
    --query "repositories[0].repositoryName" \
    --output text 2>/dev/null || echo "")
  if [[ "$existing" == "$repo" ]]; then
    echo "  EXISTS  ${repo}"
  else
    aws ecr create-repository \
      --region "$REGION" \
      --repository-name "$repo" \
      --image-scanning-configuration scanOnPush=true \
      --no-cli-pager > /dev/null
    echo "  CREATED ${repo}"
  fi
}

# ── Argument parsing ──────────────────────────────────────────────────────────

[[ $# -eq 0 ]] && usage

while [[ $# -gt 0 ]]; do
  case $1 in
    --export)      MODE="export"; shift ;;
    --load)        MODE="load";   shift ;;
    --src-account) SRC_ACCOUNT="${2:-}"; [[ -z "$SRC_ACCOUNT" ]] && usage; shift 2 ;;
    --output-dir)  OUTPUT_DIR="${2:-}";  [[ -z "$OUTPUT_DIR"  ]] && usage; shift 2 ;;
    --input-dir)   INPUT_DIR="${2:-}";   [[ -z "$INPUT_DIR"   ]] && usage; shift 2 ;;
    --region)      REGION="${2:-}";      [[ -z "$REGION"      ]] && usage; shift 2 ;;
    --minimal)     MINIMAL=true; shift ;;
    --dry-run)     DRY_RUN=true; shift ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

[[ -z "$MODE" ]] && usage

if [[ "$MODE" == "export" ]]; then
  [[ -z "$SRC_ACCOUNT" ]] && echo "ERROR: --export requires --src-account" && echo "" && usage
  if [[ -z "$OUTPUT_DIR" ]]; then
    if [[ "$MINIMAL" == true ]]; then
      OUTPUT_DIR="ecr-export-minimal-$(date +%Y%m%d-%H%M%S)"
    else
      OUTPUT_DIR="ecr-export-$(date +%Y%m%d-%H%M%S)"
    fi
  fi
fi

if [[ "$MODE" == "load" ]]; then
  [[ -z "$INPUT_DIR" ]] && echo "ERROR: --load requires --input-dir" && echo "" && usage
  [[ ! -d "$INPUT_DIR" ]]            && echo "ERROR: directory not found: $INPUT_DIR"           && exit 1
  [[ ! -f "$INPUT_DIR/manifest.json" ]] && echo "ERROR: manifest.json not found in $INPUT_DIR" && exit 1
fi

# ── Export ────────────────────────────────────────────────────────────────────

if [[ "$MODE" == "export" ]]; then

  if [[ "$MINIMAL" == true ]]; then
    REPOS=("${REPOS_MINIMAL[@]}")
  else
    REPOS=("${REPOS_ALL[@]}")
  fi

  SRC_REGISTRY="${SRC_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN — no pulls, saves, or file writes will occur]"
    echo ""
  fi

  check_auth

  mkdir -p "$OUTPUT_DIR"
  ABS_OUTPUT=$(realpath "$OUTPUT_DIR")
  echo "Output directory: ${ABS_OUTPUT}"
  echo ""

  [[ "$DRY_RUN" != true ]] && ecr_login "$SRC_REGISTRY"

  # Accumulate manifest entries as a JSON array (one line per entry, joined at the end)
  MANIFEST_ENTRIES=()

  echo "── :latest images (${#REPOS[@]}) ──────────────────────────────────────────"
  echo ""

  for REPO in "${REPOS[@]}"; do
    FLAT=$(repo_to_flat "$REPO")
    TAG="latest"
    FILE="${FLAT}-${TAG}.tar.gz"
    SRC="${SRC_REGISTRY}/${REPO}:${TAG}"
    LOCAL_TAG="${FLAT}:${TAG}"

    if [[ "$DRY_RUN" == true ]]; then
      echo "  DRY  ${REPO}:${TAG}  →  ${FILE}"
      MANIFEST_ENTRIES+=("{\"repo\":\"${REPO}\",\"tag\":\"${TAG}\",\"file\":\"${FILE}\",\"local_tag\":\"${LOCAL_TAG}\"}")
      continue
    fi

    echo "  Pulling  ${REPO}:${TAG} ..."
    docker pull "$SRC"

    echo "  Tagging  ${SRC}  →  ${LOCAL_TAG}"
    docker tag "$SRC" "$LOCAL_TAG"

    echo "  Saving   ${FILE} ..."
    docker save "$LOCAL_TAG" | gzip > "${OUTPUT_DIR}/${FILE}"
    SIZE=$(du -sh "${OUTPUT_DIR}/${FILE}" | cut -f1)
    echo "  Done     ${FILE}  (${SIZE})"
    echo ""

    MANIFEST_ENTRIES+=("{\"repo\":\"${REPO}\",\"tag\":\"${TAG}\",\"file\":\"${FILE}\",\"local_tag\":\"${LOCAL_TAG}\"}")
  done

  echo "── Pinned-digest images (${#PINNED[@]}) ─────────────────────────────────────"
  echo ""

  for REPO in "${!PINNED[@]}"; do
    DIGEST="${PINNED[$REPO]}"
    SHORT="${DIGEST:7:12}"
    FLAT=$(repo_to_flat "$REPO")
    TAG="pinned-${SHORT}"
    FILE="${FLAT}-${TAG}.tar.gz"
    SRC="${SRC_REGISTRY}/${REPO}@${DIGEST}"
    LOCAL_TAG="${FLAT}:${TAG}"

    if [[ "$DRY_RUN" == true ]]; then
      echo "  DRY  ${REPO}@${DIGEST:0:19}  →  ${FILE}"
      MANIFEST_ENTRIES+=("{\"repo\":\"${REPO}\",\"tag\":\"${TAG}\",\"digest\":\"${DIGEST}\",\"file\":\"${FILE}\",\"local_tag\":\"${LOCAL_TAG}\"}")
      continue
    fi

    echo "  Pulling  ${REPO}@${DIGEST:0:19} ..."
    docker pull "$SRC"

    echo "  Tagging  →  ${LOCAL_TAG}"
    docker tag "$SRC" "$LOCAL_TAG"

    echo "  Saving   ${FILE} ..."
    docker save "$LOCAL_TAG" | gzip > "${OUTPUT_DIR}/${FILE}"
    SIZE=$(du -sh "${OUTPUT_DIR}/${FILE}" | cut -f1)
    echo "  Done     ${FILE}  (${SIZE})"
    echo ""

    MANIFEST_ENTRIES+=("{\"repo\":\"${REPO}\",\"tag\":\"${TAG}\",\"digest\":\"${DIGEST}\",\"file\":\"${FILE}\",\"local_tag\":\"${LOCAL_TAG}\"}")
  done

  # Write manifest.json
  ENTRIES_JSON=$(IFS=,; echo "[${MANIFEST_ENTRIES[*]}]")
  python3 - <<PYEOF > "${OUTPUT_DIR}/manifest.json"
import json, sys, datetime

entries_raw = """${ENTRIES_JSON}"""
data = {
    "source_account":  "${SRC_ACCOUNT}",
    "source_registry": "${SRC_REGISTRY}",
    "region":          "${REGION}",
    "exported_at":     datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "images":          json.loads(entries_raw)
}
print(json.dumps(data, indent=2))
PYEOF

  echo ""
  echo "Manifest written: ${OUTPUT_DIR}/manifest.json"
  echo ""

  if [[ "$DRY_RUN" != true ]]; then
    TOTAL=$(du -sh "$OUTPUT_DIR" | cut -f1)
    echo "════════════════════════════════════════════════════════════"
    echo "Export complete.  Total size: ${TOTAL}"
    echo "Output:  ${ABS_OUTPUT}"
  else
    echo "════════════════════════════════════════════════════════════"
    echo "Dry run complete — no files written."
  fi

  echo ""
  echo "Next steps:"
  echo "  1. Upload the '$(basename "$OUTPUT_DIR")' folder to OneDrive."
  echo "  2. Download it on the target machine, then (logged into the target account):"
  echo "       ./scripts/package-ecr-images.sh --load --input-dir <downloaded-folder>"
fi

# ── Load ──────────────────────────────────────────────────────────────────────

if [[ "$MODE" == "load" ]]; then

  # Repo list for ECR creation is driven by the manifest, not the local arrays.
  # Use REPOS_ALL as the superset for verification; actual work follows manifest.json.
  REPOS=("${REPOS_ALL[@]}")

  [[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no loads or pushes will occur]" && echo ""

  check_auth

  DST_REGISTRY="${CURRENT_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
  MANIFEST=$(cat "${INPUT_DIR}/manifest.json")

  SRC_ACCOUNT_M=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['source_account'])"  "$MANIFEST")
  EXPORTED_AT=$(  python3 -c "import json,sys; print(json.loads(sys.argv[1])['exported_at'])"      "$MANIFEST")
  IMAGE_COUNT=$(  python3 -c "import json,sys; print(len(json.loads(sys.argv[1])['images']))"       "$MANIFEST")

  echo "Manifest: ${IMAGE_COUNT} images, exported ${EXPORTED_AT} from account ${SRC_ACCOUNT_M}"
  echo "Target:   ${DST_REGISTRY}"
  echo ""

  # Verify all files listed in the manifest are present before touching ECR
  echo "Verifying files ..."
  MISSING=0
  while IFS= read -r FILE; do
    if [[ ! -f "${INPUT_DIR}/${FILE}" ]]; then
      echo "  MISSING  ${FILE}"
      MISSING=$((MISSING + 1))
    else
      echo "  OK       ${FILE}"
    fi
  done < <(python3 -c "
import json, sys
for img in json.loads(sys.argv[1])['images']:
    print(img['file'])
" "$MANIFEST")
  echo ""
  if [[ $MISSING -gt 0 ]]; then
    echo "ERROR: ${MISSING} file(s) missing from ${INPUT_DIR}."
    echo "       Re-download the folder from OneDrive and try again."
    exit 1
  fi

  # Create ECR repositories for images present in the manifest
  MANIFEST_REPOS=$(python3 -c "
import json, sys
images = json.loads(sys.argv[1])['images']
seen = []
for img in images:
    if img['repo'] not in seen:
        seen.append(img['repo'])
        print(img['repo'])
" "$MANIFEST")

  echo "Creating ECR repositories ..."
  while IFS= read -r REPO; do
    if [[ "$DRY_RUN" == true ]]; then
      echo "  DRY  would create: ${REPO}"
    else
      ensure_ecr_repo "$REPO"
    fi
  done <<< "$MANIFEST_REPOS"
  echo ""

  [[ "$DRY_RUN" == true ]] && echo "Dry run complete." && exit 0

  ecr_login "$DST_REGISTRY"

  # Load each image, retag for target registry, push
  IMAGE_COUNT_INT=$(python3 -c "import json,sys; print(len(json.loads(sys.argv[1])['images']))" "$MANIFEST")

  for i in $(seq 0 $((IMAGE_COUNT_INT - 1))); do
    REPO=$(     python3 -c "import json,sys; print(json.loads(sys.argv[1])['images'][int(sys.argv[2])]['repo'])"      "$MANIFEST" "$i")
    TAG=$(      python3 -c "import json,sys; print(json.loads(sys.argv[1])['images'][int(sys.argv[2])]['tag'])"       "$MANIFEST" "$i")
    FILE=$(     python3 -c "import json,sys; print(json.loads(sys.argv[1])['images'][int(sys.argv[2])]['file'])"      "$MANIFEST" "$i")
    LOCAL_TAG=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['images'][int(sys.argv[2])]['local_tag'])" "$MANIFEST" "$i")
    DST_TAG="${DST_REGISTRY}/${REPO}:${TAG}"

    echo "  [${REPO}:${TAG}]"
    echo "    Loading   ${FILE} ..."
    docker load -i "${INPUT_DIR}/${FILE}"

    echo "    Tagging   ${LOCAL_TAG}  →  ${DST_TAG}"
    docker tag "$LOCAL_TAG" "$DST_TAG"

    echo "    Pushing   ${DST_TAG} ..."
    docker push "$DST_TAG"
    echo "    OK"
    echo ""
  done

  echo "════════════════════════════════════════════════════════════"
  echo "All images loaded and pushed to ${DST_REGISTRY}"
  echo ""
  echo "Next step — refresh pinned digests in tfvars:"
  echo "  cd cul-<env> && ./scripts/update-ecr-digests.sh"
fi
