resource "aws_ecr_repository" "cudl-content-loader-db-ecr-repository" {
  name = "${var.environment}-dl-loader-db"
}

resource "aws_ecr_repository" "cudl-content-loader-ui-ecr-repository" {
  name = "${var.environment}-dl-loader-ui"
}