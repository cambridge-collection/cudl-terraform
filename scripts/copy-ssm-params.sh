#!/usr/bin/env bash
# Copies CUDL SSM parameters between AWS accounts / environments.
#
# Two-step workflow — log into each account separately:
#
#   Step 1 — logged into source account, run from the source environment directory:
#     ./copy-ssm-params.sh --discover
#     ./copy-ssm-params.sh --export params.json
#
#   Step 2 — logged into destination account, run from the destination environment directory:
#     ./copy-ssm-params.sh --import params.json [--dry-run]
#
# --src-env / --dst-env default to the environment name read from institution.auto.tfvars
# in the current directory (title-cased, e.g. development → Development).
# Pass them explicitly to override, e.g. --src-env Staging.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-detect the title-cased environment name from institution.auto.tfvars in the
# current directory (e.g. environment = "development" → "Development").
DETECTED_ENV=""
INST_TFVARS="$(pwd)/institution.auto.tfvars"
if [[ -f "$INST_TFVARS" ]]; then
  _raw="$(grep -E '^environment[[:space:]]*=' "$INST_TFVARS" | sed 's/.*=[[:space:]]*"\(.*\)".*/\1/' | head -1)"
  if [[ -n "$_raw" && "$_raw" != *"FIXME"* ]]; then
    DETECTED_ENV="$(printf '%s' "${_raw:0:1}" | tr '[:lower:]' '[:upper:]')${_raw:1}"
  fi
fi

REGION="eu-west-1"
SSM_ROOT="/Environments"
APP="CUDL"

# Relative parameter paths under /<root>/<env>/<app>/
PARAMS=(
  "Services/APIKey/Viewer"
  "Viewer/SMTP/Username"
  "Viewer/SMTP/Password"
  "Viewer/SMTP/Port"
  "Viewer/CloudFront/Username"
  "Viewer/CloudFront/Password"
  "Viewer/Recaptcha/Sitekey"
  "Viewer/Recaptcha/Secretkey"
  "Viewer/Google/AnalyticsId"
  "Viewer/Google/GA4AnalyticsId"
  "Services/DB/Password"
  "Services/APIKey/Darwin"
  "Services/BasicAuth/Credentials"
)

usage() {
  echo "Usage:"
  echo "  $0 --discover                                      # list all $SSM_ROOT/ params in current account"
  echo "  $0 --export <file.json> [--src-env <Env>]         # export params from current account"
  echo "  $0 --import <file.json> [--dst-env <Env>]         # import params into current account"
  echo "  $0 --import <file.json> [--dst-env <Env>] --dry-run"
  echo "  $0 --region <region>  (default: $REGION)"
  echo ""
  echo "  --src-env / --dst-env are the title-cased environment name, e.g. 'Development'."
  echo "  If omitted, the name is read from institution.auto.tfvars in the current directory."
  [[ -n "$DETECTED_ENV" ]] && echo "  Auto-detected: $DETECTED_ENV"
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
FILE=""
SRC_ENV=""
DST_ENV=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --discover)  MODE="discover"; shift ;;
    --export)    MODE="export";  FILE="${2:-}";    [[ -z "$FILE" ]]    && usage; shift 2 ;;
    --import)    MODE="import";  FILE="${2:-}";    [[ -z "$FILE" ]]    && usage; shift 2 ;;
    --src-env)   SRC_ENV="${2:-}";  [[ -z "$SRC_ENV" ]] && usage; shift 2 ;;
    --dst-env)   DST_ENV="${2:-}";  [[ -z "$DST_ENV" ]] && usage; shift 2 ;;
    --region)    REGION="${2:-}";   [[ -z "$REGION" ]]  && usage; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$MODE" ]] && usage

# Fall back to auto-detected env name if not provided on the command line
SRC_ENV="${SRC_ENV:-$DETECTED_ENV}"
DST_ENV="${DST_ENV:-$DETECTED_ENV}"

if [[ "$MODE" == "export" && -z "$SRC_ENV" ]]; then
  echo "ERROR: --export requires --src-env (or run from a directory containing institution.auto.tfvars)"
  usage
fi
if [[ "$MODE" == "import" && -z "$DST_ENV" ]]; then
  echo "ERROR: --import requires --dst-env (or run from a directory containing institution.auto.tfvars)"
  usage
fi

# Resolve a bare filename (no directory component) relative to the scripts directory
# so the file is always in the same place regardless of where the script is invoked from.
if [[ -n "$FILE" && "$FILE" != */* ]]; then
  FILE="${SCRIPTS_DIR}/${FILE}"
fi

check_auth

case "$MODE" in

  discover)
    echo "All parameters under $SSM_ROOT/ in current account:"
    echo ""
    aws ssm get-parameters-by-path \
      --region    "$REGION" \
      --path      "${SSM_ROOT}/" \
      --recursive \
      --query     "Parameters[].Name" \
      --output    text | tr '\t' '\n' | sort
    ;;

  export)
    SRC_PREFIX="${SSM_ROOT}/${SRC_ENV}/${APP}"
    echo "Exporting from ${SRC_PREFIX} -> ${FILE} ..."
    echo ""
    python3 - <<PYEOF
import subprocess, json

params = """$(printf '%s\n' "${PARAMS[@]}")""".strip().split('\n')

out, skipped = [], []

for rel in params:
    name = "${SRC_PREFIX}/" + rel
    result = subprocess.run(
        ["aws", "ssm", "get-parameter", "--region", "${REGION}",
         "--name", name, "--with-decryption",
         "--query", "Parameter.{Value:Value,Type:Type}", "--output", "json"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        skipped.append(name)
        print(f"  SKIP  {name}")
        continue
    data = json.loads(result.stdout)
    out.append({"path": rel, "value": data["Value"], "type": data["Type"]})
    print(f"  OK    {name}  (type: {data['Type']})")

with open("${FILE}", "w") as f:
    json.dump(out, f, indent=2)

print()
print(f"Exported {len(out)} parameters to ${FILE}")
if skipped:
    print(f"Skipped  {len(skipped)} (not found in source):")
    for s in skipped:
        print(f"         {s}")
PYEOF
    ;;

  import)
    [[ ! -f "$FILE" ]] && echo "ERROR: File not found: $FILE" && exit 1
    DST_PREFIX="${SSM_ROOT}/${DST_ENV}/${APP}"
    [[ "$DRY_RUN" == true ]] && echo "[DRY RUN — no writes will occur]" && echo ""
    echo "Importing from ${FILE} -> ${DST_PREFIX} ..."
    echo ""
    python3 - <<PYEOF
import subprocess, json

with open("${FILE}") as f:
    params = json.load(f)

dry_run = $([[ "$DRY_RUN" == true ]] && echo "True" || echo "False")

for p in params:
    dst   = "${DST_PREFIX}/" + p["path"]
    ptype = p["type"] if p["type"] != "StringList" else "String"
    if dry_run:
        print(f"  DRY   {dst}  (type: {ptype})")
        continue
    result = subprocess.run(
        ["aws", "ssm", "put-parameter", "--region", "${REGION}",
         "--name", dst, "--value", p["value"],
         "--type", ptype, "--overwrite", "--no-cli-pager"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"  FAIL  {dst}")
        print(f"        {result.stderr.strip()}")
    else:
        print(f"  OK    {dst}  (type: {ptype})")

print()
print("Done.")
PYEOF
    ;;

esac
