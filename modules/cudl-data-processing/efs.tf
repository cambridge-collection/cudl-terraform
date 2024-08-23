resource "aws_efs_file_system" "efs-volume" {
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${var.environment}-${var.efs-name}"
  }
}

resource "aws_efs_access_point" "efs-access-point" {

  tags = {
    Name = "${var.environment}-${var.efs-name}-access-point"
  }
  file_system_id = aws_efs_file_system.efs-volume.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = var.releases-root-directory-path

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 777
    }
  }
  depends_on = [aws_efs_file_system.efs-volume]
}

resource "aws_efs_mount_target" "efs-mount-point" {
  for_each = toset(data.aws_subnets.efs.ids)

  file_system_id  = aws_efs_file_system.efs-volume.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]

  depends_on = [aws_efs_file_system.efs-volume]
}
