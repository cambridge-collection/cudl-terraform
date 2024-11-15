resource "aws_cloudwatch_log_group" "cudl_viewer" {
  name = "/ecs/${module.cudl_viewer.name_prefix}"
}
