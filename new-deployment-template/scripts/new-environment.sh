#!/usr/bin/env bash
# Generates a new Terraform environment directory by copying new-deployment-template
# and substituting the environment name, AWS account ID, and domain name
# throughout all files.
#
# After running this script you will still need to:
#   - Fill in the FIXME placeholders in <new-dir>/institution.auto.tfvars
#   - Run <new-dir>/bootstrap-environment.sh in the target account
#   - Copy images, JARs, and SSM parameters (see scripts/README.md)
#
# Usage (run from new-deployment-template/):
#   ./scripts/new-environment.sh \
#     --env    <name>       \
#     --domain <domain>     \
#     --account <aws-id>    \
#     [--out-dir <path>]    \
#     [--dry-run]
#
# Example:
#   ./scripts/new-environment.sh \
#     --env neworg \
#     --domain neworg.example.com \
#     --account 123456789012

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(dirname "$SCRIPTS_DIR")"
REPO_ROOT="$(dirname "$TEMPLATE_DIR")"

NEW_ENV=""
NEW_DOMAIN=""
NEW_ACCOUNT=""
OUT_DIR=""
DRY_RUN=false

# Source values read from the template's institution.auto.tfvars
SRC_DIR="$TEMPLATE_DIR"
get_tfvar() { grep -E "^${1}\s*=" "${SRC_DIR}/institution.auto.tfvars" | sed 's/.*=\s*"\(.*\)".*/\1/' | head -1; }
SRC_ENV="$(get_tfvar environment)"
SRC_DOMAIN="$(get_tfvar registered_domain_name | sed 's/\.$//')"   # strip trailing dot
SRC_ACCOUNT="$(get_tfvar acm_certificate_arn | grep -oE '[0-9]{12}' | head -1)"

usage() {
  echo "Usage: $0 --env <name> --domain <domain> --account <aws-id> [options]"
  echo ""
  echo "  --env <name>       New environment name, e.g. 'neworg'"
  echo "  --domain <domain>  Base domain for the new environment, e.g. 'neworg.example.com'"
  echo "  --account <id>     Target AWS account ID, e.g. '123456789012'"
  echo "  --out-dir <path>   Output directory (default: cul-<name> in repo root)"
  echo "  --dry-run          List files that would be created/modified without writing"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --env)     NEW_ENV="${2:-}";     [[ -z "$NEW_ENV" ]]     && usage; shift 2 ;;
    --domain)  NEW_DOMAIN="${2:-}";  [[ -z "$NEW_DOMAIN" ]]  && usage; shift 2 ;;
    --account) NEW_ACCOUNT="${2:-}"; [[ -z "$NEW_ACCOUNT" ]] && usage; shift 2 ;;
    --out-dir) OUT_DIR="${2:-}";     [[ -z "$OUT_DIR" ]]     && usage; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$NEW_ENV" || -z "$NEW_DOMAIN" || -z "$NEW_ACCOUNT" ]] && usage

[[ -z "$OUT_DIR" ]] && OUT_DIR="${REPO_ROOT}/cul-${NEW_ENV}"

if [[ -d "$OUT_DIR" ]]; then
  echo "ERROR: output directory already exists: $OUT_DIR"
  echo "       Remove it first or specify a different --out-dir."
  exit 1
fi

# Title-case helper (first letter uppercase, rest unchanged)
title_case() {
  local upper
  upper="$(printf '%s' "${1:0:1}" | tr '[:lower:]' '[:upper:]')"
  printf '%s%s' "$upper" "${1:1}"
}
SRC_ENV_TITLE="$(title_case "$SRC_ENV")"
NEW_ENV_TITLE="$(title_case "$NEW_ENV")"

echo "Source:      cul-${SRC_ENV}  (account ${SRC_ACCOUNT}, domain ${SRC_DOMAIN})"
echo "Destination: ${OUT_DIR}"
echo "New env:     ${NEW_ENV}  (account ${NEW_ACCOUNT}, domain ${NEW_DOMAIN})"
echo ""
[[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no files will be written]" && echo ""

# ── Copy source directory ─────────────────────────────────────────────────────
if [[ "$DRY_RUN" == true ]]; then
  echo "Would copy ${SRC_DIR}/ → ${OUT_DIR}/"
else
  cp -r "$SRC_DIR" "$OUT_DIR"
  echo "Copied ${SRC_DIR}/ → ${OUT_DIR}/"
fi
echo ""

# ── Substitutions ─────────────────────────────────────────────────────────────
# Applied to all .tf and .tfvars files in the new directory.
#
# Order matters: title-case first so it doesn't accidentally match the plain substitution.

do_substitution() {
  local pattern="$1" replacement="$2" description="$3"
  echo "  Replacing: ${description}"
  if [[ "$DRY_RUN" == true ]]; then
    grep -rl --include="*.tf" --include="*.tfvars" "$pattern" "$OUT_DIR" 2>/dev/null \
      | sed "s|${OUT_DIR}/||" | while read -r f; do echo "    $f"; done
    return
  fi
  # In-place substitution across all Terraform files
  find "$OUT_DIR" -type f \( -name "*.tf" -o -name "*.tfvars" \) \
    -exec sed -i "s|${pattern}|${replacement}|g" {} +
}

echo "Applying substitutions ..."
# Title-case env name  (e.g. Development → Neworg)
do_substitution "$SRC_ENV_TITLE" "$NEW_ENV_TITLE" \
  "env title-case: ${SRC_ENV_TITLE} → ${NEW_ENV_TITLE}"

# Lowercase env name  (e.g. development → neworg)
do_substitution "$SRC_ENV" "$NEW_ENV" \
  "env name: ${SRC_ENV} → ${NEW_ENV}"

# AWS account ID in ECR URIs and ARNs
do_substitution "$SRC_ACCOUNT" "$NEW_ACCOUNT" \
  "account ID: ${SRC_ACCOUNT} → ${NEW_ACCOUNT}"

# Domain name  (e.g. cul-development.net → neworg.example.com)
do_substitution "$SRC_DOMAIN" "$NEW_DOMAIN" \
  "domain: ${SRC_DOMAIN} → ${NEW_DOMAIN}"

echo ""

# ── Patch institution.auto.tfvars — clear values that can't be auto-derived ───
INST_TFVARS="${OUT_DIR}/institution.auto.tfvars"

patch_institution() {
  local file="$1"
  [[ -f "$file" ]] || return

  # Route53 zone IDs — unknown until the hosted zone is created
  sed -i 's|route53_zone_id_existing   = "Z[A-Z0-9]*"|route53_zone_id_existing   = "FIXME: set after creating hosted zone"|' "$file"
  sed -i 's|cloudfront_route53_zone_id = "Z[A-Z0-9]*"|cloudfront_route53_zone_id = "FIXME: set after creating hosted zone"|' "$file"

  # ACM cert ARN — unknown until bootstrap-environment.sh runs and cert is issued
  sed -i 's|acm_certificate_arn = "arn:aws:acm:[^"]*"|acm_certificate_arn = "FIXME: set after bootstrap-environment.sh and wildcard cert apply"|' "$file"

  # CloudWatch log destination — only valid for accounts granted access to the central logger
  sed -i 's|cloudwatch_log_destination_arn = "arn:aws:logs:[^"]*"|cloudwatch_log_destination_arn = "FIXME: set if using central log forwarding"|' "$file"

  # ECR digests — will be populated by update-ecr-digests.sh after image push
  sed -i 's|= "sha256:[0-9a-f]*"|= "FIXME: run scripts/update-ecr-digests.sh"|g' "$file"

  echo "Cleared account-specific placeholders in ${file##*/}"
}

if [[ "$DRY_RUN" == true ]]; then
  echo "Would clear FIXME placeholders in institution.auto.tfvars"
else
  patch_institution "$INST_TFVARS"
fi
echo ""

# ── Patch terraform.tf — update backend bucket/table names ───────────────────
TF_BACKEND="${OUT_DIR}/terraform.tf"
if [[ "$DRY_RUN" == true ]]; then
  echo "Would update backend config in terraform.tf"
else
  # The substitutions above already replaced the env name in bucket/table names,
  # so just confirm the result looks correct.
  if grep -q "cul-cudl-${NEW_ENV}-terraform-state" "$TF_BACKEND" 2>/dev/null; then
    echo "Backend config updated in terraform.tf"
  else
    echo "WARNING: could not verify backend config in terraform.tf — please review manually."
  fi
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "================================================================"
if [[ "$DRY_RUN" == true ]]; then
  echo "Dry run complete. Re-run without --dry-run to create the directory."
else
  echo "Environment directory created: ${OUT_DIR}"
fi
echo ""
echo "Remaining manual steps:"
echo ""
echo "  1. In the TARGET AWS account:"
echo "     a. Register/delegate a DNS domain (or subdomain) for ${NEW_DOMAIN}"
echo "     b. Create a Route53 public hosted zone and note the zone ID"
echo "     c. Run:  ./scripts/bootstrap-environment.sh \\"
echo "                --env ${NEW_ENV} \\"
echo "                --jar-bucket cul-cudl.mvn.${NEW_DOMAIN}"
echo ""
echo "  2. Copy assets (source account first, then target account):"
echo "     ./scripts/copy-ecr-images.sh  --pull"
echo "     ./scripts/copy-ecr-images.sh  --push --src-account ${SRC_ACCOUNT}"
echo "     ./scripts/copy-lambda-jars.sh --download"
echo "     ./scripts/copy-lambda-jars.sh --upload --dst-bucket cul-cudl.mvn.${NEW_DOMAIN}"
echo "     ./scripts/copy-ssm-params.sh  --export params.json --src-env ${SRC_ENV_TITLE}"
echo "     ./scripts/copy-ssm-params.sh  --import params.json --dst-env ${NEW_ENV_TITLE}"
echo "     rm params.json"
echo ""
echo "  3. Fill in FIXME values in ${OUT_DIR}/institution.auto.tfvars"
echo "     (Route53 zone ID, ACM cert ARN, log destination)"
echo ""
echo "  4. Run:  ./scripts/update-ecr-digests.sh --env ${NEW_ENV}"
echo "     (updates all ECR sha256 digests from the new account)"
echo ""
echo "  5. cd ${OUT_DIR}"
echo "     terraform init"
echo "     terraform apply --target=module.base_architecture"
echo "     terraform apply"
echo "================================================================"
