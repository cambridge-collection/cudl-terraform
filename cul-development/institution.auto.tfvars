# ─────────────────────────────────────────────────────────────────────────────
# Institution / account-specific values
#
# These are the ~15 values that must change when deploying to a new AWS account
# or for a new institution.  Everything else lives in terraform.tfvars and is
# identical across deployments.
#
# To set up a new environment:
#   1. Run scripts/bootstrap-environment.sh   — creates state backend + log group
#   2. Run scripts/copy-ecr-images.sh         — copies container images to the new account ECR
#   3. Run scripts/copy-lambda-jars.sh        — copies JAR artifacts to the new Maven bucket
#   4. Run scripts/copy-ssm-params.sh         — copies SSM Parameter Store secrets
#   5. Fill in the FIXME values below
#   6. Run scripts/update-ecr-digests.sh      — refreshes sha256 digests from the new account ECR
#   7. terraform apply --target=module.base_architecture
#   8. terraform apply
# ─────────────────────────────────────────────────────────────────────────────

environment            = "development"
registered_domain_name = "cul-development.net."

# VPC CIDR — must not overlap with other VPCs in the account or peered networks.
vpc_cidr_block = "10.50.0.0/22"

# Route 53 — hosted zone for this environment's domain.
# Both values point to the same zone when the ALB and CloudFront share one zone.
route53_zone_id_existing   = "Z0793873J5B5RKU48R3D"
cloudfront_route53_zone_id = "Z0793873J5B5RKU48R3D"

# ACM — eu-west-1 certificate for the ALB HTTPS listener.
# The us-east-1 / CloudFront certificate is managed in acm_wildcard_cert.tf.
acm_certificate_arn = "arn:aws:acm:eu-west-1:206247777824:certificate/9f58fdb2-6384-4cc5-8274-6f8491a27104"

# S3 — Maven/JAR bucket for JAR-based Lambda functions (created by bootstrap-environment.sh).
lambda-jar-bucket = "cul-cudl.mvn.cul-development.net"

# CloudWatch log group created by bootstrap-environment.sh before terraform apply.
cloudwatch_log_group = "/ecs/CUDL-Development"

# Optional: ARN of a CloudWatch Logs destination in another account to forward ECS logs to.
# Leave as "" for a standalone installation (no cross-account log forwarding).
# If set, the destination account must grant this account permission on its destination policy.
cloudwatch_log_destination_arn = "arn:aws:logs:eu-west-1:874581676011:destination:cul-logs-cloudwatch-log-destination"

# ─── ECR image digests ────────────────────────────────────────────────────────
# These are account-specific: ECR repositories live in this account.
# After running copy-ecr-images.sh --push, run scripts/update-ecr-digests.sh
# to refresh all digests below and in terraform.tfvars automatically.

content_loader_ecr_repositories = {
  "cudl/content-loader-db" = "sha256:db3975d626e80ad1de43f97f95997854f4c4b63ea8c71e1dbf40ce0c89455631",
  "cudl/content-loader-ui" = "sha256:39e4885b8e9f6e1b25df52f73ff71f018e8b1cfa5f0b8e310cbe8672d4b9b19a"
}
solr_ecr_repositories = {
  "cudl/solr-api" = "sha256:38e68886cf61cb563de3ad8611f3c708816f78605f43540ffa2e0a9652bb73af",
  "cudl/solr"     = "sha256:9c144888d9a51757a8732a457e0f712d397ec25143a9caded6661a3e880b031d"
}
cudl_services_ecr_repositories = {
  "cudl/services" = "sha256:bc86da808e1420fde49196cdbc12251f1e79ba5dc3f0c5a68e4e197ebe1c7902"
}
cudl_viewer_ecr_repositories = {
  "cudl/viewer" = "sha256:89f506db9ee6d75ccf93602cf5ba7a9b58d2bbe62193b8d7d8a994a62453b320"
}
