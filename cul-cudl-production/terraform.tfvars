environment                  = "mjh39-darwin-test"
project                      = "Darwin"
component                    = "cudl-data-workflows"
subcomponent                 = "cudl-transform-lambda"
destination-bucket-name      = "releases"
web_frontend_domain_name     = "darwin.cudl-sandbox.net"
transcriptions-bucket-name   = "unused-cul-cudl-transcriptions"
enhancements-bucket-name     = "unused-cul-cudl-data-enhancements"
source-bucket-name           = "unused-cul-cudl-data-source"
compressed-lambdas-directory = "compressed_lambdas"
lambda-jar-bucket            = "cul-cudl.mvn.cudl.lib.cam.ac.uk"

transform-lambda-bucket-sns-notifications = [

]
transform-lambda-bucket-sqs-notifications = [
  {
    "type"          = "SQS",
    "queue_name"    = "DarwinIndexTEIQueue"
    "filter_prefix" = "solr-json/tei/"
    "filter_suffix" = ".json"
    "bucket_name"   = "releases"
  },
  {
    "type"          = "SQS",
    "queue_name"    = "DarwinIndexPagesQueue"
    "filter_prefix" = "solr-json/pages/"
    "filter_suffix" = ".json"
    "bucket_name"   = "releases"
  }
]
transform-lambda-information = [
  {
    "name"                     = "AWSLambda_TEI_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "DarwinIndexTEIQueue"
    "queue_delay_seconds"      = 10
    "vpc_name"                 = "mjh39-darwin-test-darwin-ecs-vpc"
    "subnet_names"             = ["mjh39-darwin-test-darwin-ecs-subnet-private-a", "mjh39-darwin-test-darwin-ecs-subnet-private-b"]
    "security_group_names"     = ["mjh39-darwin-test-darwin-ecs-vpc-egress", "mjh39-darwin-test-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-darwin-ecs.mjh39-darwin-test-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_Pages_SOLR_Listener"
    "image_uri"                = "563181399728.dkr.ecr.eu-west-1.amazonaws.com/cudl-solr-listener@sha256:88795e469457966c06f62e55c1c217bef3b5fb92c35589bac4a5be735c631689"
    "queue_name"               = "DarwinIndexPagesQueue"
    "vpc_name"                 = "mjh39-darwin-test-darwin-ecs-vpc"
    "subnet_names"             = ["mjh39-darwin-test-darwin-ecs-subnet-private-a", "mjh39-darwin-test-darwin-ecs-subnet-private-b"]
    "security_group_names"     = ["mjh39-darwin-test-darwin-ecs-vpc-egress", "mjh39-darwin-test-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-darwin-ecs.mjh39-darwin-test-solr"
      API_PORT = "8081"
      API_PATH = "page"
    }
  }
]
dst-efs-prefix    = "/mnt/cudl-data-releases"
dst-prefix        = "html/"
dst-s3-prefix     = ""
tmp-dir           = "/tmp/dest/"
lambda-alias-name = "LIVE"

releases-root-directory-path = "/data"
efs-name                     = "cudl-data-releases-efs"
cloudfront_route53_zone_id   = "Z035173135AOVWW8L57UJ"

# Base Architecture
cluster_name_suffix            = "darwin-ecs"
registered_domain_name         = "cudl-sandbox.net."
asg_desired_capacity           = 1 # n = number of tasks
asg_max_size                   = 1 # n + 1
asg_allow_all_egress           = true
ec2_instance_type              = "t3.large"
ec2_additional_userdata        = <<-EOF
echo 1 > /proc/sys/vm/swappiness
echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
EOF
route53_delegation_set_id      = "N02288771HQRX5TRME6CM"
route53_zone_id_existing       = "Z035173135AOVWW8L57UJ"
route53_zone_force_destroy     = true
alb_enable_deletion_protection = false
alb_idle_timeout               = "900"
vpc_cidr_block                 = "10.42.0.0/22" #1024 adresses
vpc_public_subnet_public_ip    = false
vpc_peering_vpc_ids            = ["vpc-057886e0bdd7c4e43"]
cloudwatch_log_group           = "/ecs/Darwin"

# SOLR Worload
solr_name_suffix       = "solr"
solr_domain_name       = "darwin-search"
solr_application_port  = 8983
solr_target_group_port = 8081
solr_ecr_repositories = {
  "darwin-solr-api" = "sha256:430d4b0d59657a008bae4b93a10d43eca60f967da008624332a7fde83f79b912",
  "darwin-solr"     = "sha256:03b09ec898ada0a5ea64e1fddc8df6798a1287b53029e707cc56f4f567188a52"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true
