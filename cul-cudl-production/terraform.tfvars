environment                  = "mjh39-cul-darwinproject-production"
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
    "image_uri"                = "330100528433.dkr.ecr.eu-west-1.amazonaws.com/darwin/solr-listener@sha256:c77859f95ee2646ebf53a92f75c4eee823d55a111f443b29a2a34c83d863684d"
    "queue_name"               = "DarwinIndexTEIQueue"
    "queue_delay_seconds"      = 10
    "vpc_name"                 = "mjh39-cul-darwinproject-production-darwin-ecs-vpc"
    "subnet_names"             = ["mjh39-cul-darwinproject-production-darwin-ecs-subnet-private-a", "mjh39-cul-darwinproject-production-darwin-ecs-subnet-private-b"]
    "security_group_names"     = ["mjh39-cul-darwinproject-production-darwin-ecs-vpc-egress", "mjh39-cul-darwinproject-production-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-darwin-ecs.mjh39-cul-darwinproject-production-solr"
      API_PORT = "8081"
      API_PATH = "item"
    }
  },
  {
    "name"                     = "AWSLambda_Pages_SOLR_Listener"
    "image_uri"                = "330100528433.dkr.ecr.eu-west-1.amazonaws.com/darwin/solr-listener@sha256:c77859f95ee2646ebf53a92f75c4eee823d55a111f443b29a2a34c83d863684d"
    "queue_name"               = "DarwinIndexPagesQueue"
    "vpc_name"                 = "mjh39-cul-darwinproject-production-darwin-ecs-vpc"
    "subnet_names"             = ["mjh39-cul-darwinproject-production-darwin-ecs-subnet-private-a", "mjh39-cul-darwinproject-production-darwin-ecs-subnet-private-b"]
    "security_group_names"     = ["mjh39-cul-darwinproject-production-darwin-ecs-vpc-egress", "mjh39-cul-darwinproject-production-solr-external"]
    "timeout"                  = 180
    "memory"                   = 1024
    "batch_window"             = 2
    "batch_size"               = 1
    "maximum_concurrency"      = 5
    "use_datadog_variables"    = false
    "use_additional_variables" = true
    "environment_variables" = {
      API_HOST = "solr-api-darwin-ecs.mjh39-cul-darwinproject-production-solr"
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

releases-root-directory-path   = "/data"
efs-name                       = "cudl-data-releases-efs"
cloudfront_route53_zone_id     = "Z028489118FY8DBPA2P7Q"
cloudfront_distribution_name   = "darwin"
cloudfront_origin_path         = "/www"
cloudfront_origin_errors_path  = "/errors"
cloudfront_default_root_object = "index.html"

# Base Architecture
cluster_name_suffix            = "darwin-ecs"
registered_domain_name         = "darwinproject.link."
asg_desired_capacity           = 1 # n = number of tasks
asg_max_size                   = 1 # n + 1
asg_allow_all_egress           = true
ec2_instance_type              = "t3.large"
ec2_additional_userdata        = <<-EOF
echo 1 > /proc/sys/vm/swappiness
echo ECS_RESERVED_MEMORY=256 >> /etc/ecs/ecs.config
EOF
#route53_delegation_set_id      = "N02288771HQRX5TRME6CM"
route53_zone_id_existing       = "Z028489118FY8DBPA2P7Q"
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
  "darwin/solr-api" = "sha256:2c2c1695c1323d09a53f0eb691b1443206a5ade67defe5202ef812e067204a13",
  "darwin/solr"     = "sha256:008b4b6e4af8264351e2a0f63c8866f2aefa30b6cf047840c098cf4eaf3f4068"
}
solr_ecs_task_def_volumes     = { "solr-volume" = "/var/solr" }
solr_container_name_api       = "solr-api"
solr_container_name_solr      = "solr"
solr_health_check_status_code = "404"
solr_allowed_methods          = ["HEAD", "GET", "OPTIONS"]
solr_ecs_task_def_cpu         = 2048
solr_use_service_discovery    = true
