data "aws_iam_policy_document" "staging_cudl_data_releases" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      format("arn:aws:s3:::%s", module.cudl-data-processing.destination_bucket),
      format("arn:aws:s3:::%s/*", module.cudl-data-processing.destination_bucket)
    ]
  }
}

resource "aws_iam_policy" "staging_cudl_data_releases" {
  name        = format("%s-staging-cudl-data-releases", module.content_loader.name_prefix)
  path        = "/"
  description = format("Policy for %s-staging-cudl-data-releases", module.content_loader.name_prefix)
  policy      = data.aws_iam_policy_document.staging_cudl_data_releases.json
}

data "aws_iam_policy_document" "production_cudl_data_releases" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = [
      format("arn:aws:s3:::%s", var.content_loader_releases_bucket_production),
      format("arn:aws:s3:::%s/*", var.content_loader_releases_bucket_production)
    ]
  }
}

resource "aws_iam_policy" "production_cudl_data_releases" {
  name        = format("%s-production-cudl-data-releases", module.content_loader.name_prefix)
  path        = "/"
  description = format("Policy for %s-production-cudl-data-releases", module.content_loader.name_prefix)
  policy      = data.aws_iam_policy_document.production_cudl_data_releases.json
}

data "aws_iam_policy_document" "staging_cudl_data_source" {
  statement {
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLocation",
      "s3:GetBucketLogging",
      "s3:GetBucketNotification",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketRequestPayment",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetBucketWebsite",
      "s3:GetEncryptionConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectLegalHold",
      "s3:GetObjectRetention",
      "s3:GetObjectTagging",
      "s3:GetObjectTorrent",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectVersionTorrent",
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      format("arn:aws:s3:::%s", module.cudl-data-processing.source_bucket),
      format("arn:aws:s3:::%s/*", module.cudl-data-processing.source_bucket)
    ]
  }
}

resource "aws_iam_policy" "staging_cudl_data_source" {
  name        = format("%s-staging-cudl-data-source", module.content_loader.name_prefix)
  path        = "/"
  description = format("Policy for %s-staging-cudl-data-source", module.content_loader.name_prefix)
  policy      = data.aws_iam_policy_document.staging_cudl_data_source.json
}
