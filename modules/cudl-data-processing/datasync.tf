resource "aws_datasync_task" "cudl-production-cudl-data-releases-s3-to-efs" {
  for_each      = toset([for subnet in data.aws_subnet.efs : subnet.arn])

  destination_location_arn = aws_datasync_location_efs.cudl-datasync-efs[each.value].arn
  name                     = "${var.environment}-cudl-data-releases-s3-to-efs"
  source_location_arn      = aws_datasync_location_s3.cudl-datasync-s3.arn

  options {
    bytes_per_second       = -1
    preserve_deleted_files = "REMOVE"
    overwrite_mode         = "ALWAYS"
  }
}

resource "aws_datasync_task" "cudl-production-cudl-data-releases-pages-s3-to-efs-" {
  for_each      = toset([for subnet in data.aws_subnet.efs : subnet.arn])

  destination_location_arn = aws_datasync_location_efs.cudl-datasync-efs[each.value].arn
  name                     = "${var.environment}-cudl-data-releases-pages-s3-to-efs"
  source_location_arn      = aws_datasync_location_s3.cudl-datasync-s3.arn

  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = "/pages/*|/cudl.dl-dataset.json|/cudl.ui.json5|/collections/*|/ui/*"
  }

  options {
    bytes_per_second       = -1
    preserve_deleted_files = "REMOVE"
    overwrite_mode         = "ALWAYS"
  }
}

resource "aws_datasync_location_efs" "cudl-datasync-efs" {
  for_each      = toset([for subnet in data.aws_subnet.efs : subnet.arn])

  efs_file_system_arn = aws_efs_file_system.efs-volume.arn
  subdirectory        = "/data/"

  ec2_config {
    security_group_arns = [aws_security_group.efs.arn]
    subnet_arn          = each.value
  }
}

resource "aws_datasync_location_s3" "cudl-datasync-s3" {
  s3_bucket_arn = aws_s3_bucket.dest-bucket.arn
  subdirectory  = ""

  s3_config {
    bucket_access_role_arn = aws_iam_role.assume-datasync-role.arn
  }
}