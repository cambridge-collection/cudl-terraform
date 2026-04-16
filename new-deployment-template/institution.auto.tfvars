# ─────────────────────────────────────────────────────────────────────────────
# Institution / account-specific values
#
# These are the ~15 values that must change when deploying to a new AWS account
# or for a new institution.  Everything else lives in terraform.tfvars and is
# identical across deployments.
#
# To set up a new environment, see DEPLOY.md for the full walkthrough, or in brief:
#   1. Run scripts/new-environment.sh    — generates a new environment directory
#   2. Run scripts/bootstrap-environment.sh — creates state backend + log group
#   3. Run scripts/copy-ecr-images.sh    — copies container images to the new account ECR
#   4. Run scripts/copy-lambda-jars.sh   — copies JAR artifacts to the new Maven bucket
#   5. Create SSM parameters in the AWS console (see DEPLOY.md step 8)
#   6. Fill in the FIXME values below
#   7. Run scripts/update-ecr-digests.sh — refreshes sha256 digests from the new account ECR
#   8. terraform apply --target=module.base_architecture
#   9. terraform apply
# ─────────────────────────────────────────────────────────────────────────────

environment            = "FIXME: short lowercase name, e.g. myorg"
registered_domain_name = "FIXME: your domain with trailing dot, e.g. myorg.example.com."

# VPC CIDR — must not overlap with other VPCs in the account or peered networks.
vpc_cidr_block = "FIXME: e.g. 10.50.0.0/22"

# Route 53 — hosted zone for this environment's domain.
# Both values point to the same zone when the ALB and CloudFront share one zone.
route53_zone_id_existing   = "FIXME: set after creating hosted zone"
cloudfront_route53_zone_id = "FIXME: set after creating hosted zone"

# ACM — eu-west-1 certificate for the ALB HTTPS listener.
# The us-east-1 / CloudFront certificate is managed in acm_wildcard_cert.tf.
acm_certificate_arn = "FIXME: set after running terraform apply -target=aws_acm_certificate_validation.wildcard_eu_west_1"

# S3 — Maven/JAR bucket for JAR-based Lambda functions (created by bootstrap-environment.sh).
lambda-jar-bucket = "FIXME: e.g. cul-cudl.mvn.myorg.example.com"

# CloudWatch log group created by bootstrap-environment.sh before terraform apply.
cloudwatch_log_group = "FIXME: e.g. /ecs/CUDL-Myorg"

# Optional: ARN of a CloudWatch Logs destination in another account to forward ECS logs to.
# Leave as "" for a standalone installation (no cross-account log forwarding).
# If set, the destination account must grant this account permission on its destination policy.
cloudwatch_log_destination_arn = ""

# ─── ECR image digests ────────────────────────────────────────────────────────
# These are account-specific: ECR repositories live in this account.
# After running copy-ecr-images.sh --push, run scripts/update-ecr-digests.sh
# to populate all digests below and in terraform.tfvars automatically.

content_loader_ecr_repositories = {
  "cudl/content-loader-db" = "FIXME: run scripts/update-ecr-digests.sh",
  "cudl/content-loader-ui" = "FIXME: run scripts/update-ecr-digests.sh"
}
solr_ecr_repositories = {
  "cudl/solr-api" = "FIXME: run scripts/update-ecr-digests.sh",
  "cudl/solr"     = "FIXME: run scripts/update-ecr-digests.sh"
}
cudl_services_ecr_repositories = {
  "cudl/services" = "FIXME: run scripts/update-ecr-digests.sh"
}
cudl_viewer_ecr_repositories = {
  "cudl/viewer" = "FIXME: run scripts/update-ecr-digests.sh"
}
