variables {
  # Override values in cudl-dev/terraform.tfvars
  environment                        = "devlike"
  lambda-jar-bucket                  = "sandbox.mvn.cudl.lib.cam.ac.uk"
  lambda-layer-bucket                = "sandbox-cudl-artefacts"
  lambda-layer-filepath              = "projects/cudl-data-processing/xslt/cudl-transform-xslt-0.0.15.zip"
  enhancements-lambda-layer-filepath = "projects/curious-cures/xslt/curious-cures-xslt-0.0.2.zip"
  vpc-id                             = "vpc-057886e0bdd7c4e43"
  subnet-id                          = "subnet-0f2b1a30b3838d5f1"
  security-group-id                  = "sg-032f9f202ea602d21"
}

run "transform_lambda_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_lambda_length == length(var.transform-lambda-information)
    error_message = "Number of transform lambdas does not match expected value"
  }
}

run "transform_lambda_sqs_queue_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_lambda_sqs_queue_length == length(var.transform-lambda-information)
    error_message = "Number of SQS queues expected to match number of transform lambdas"
  }
}

run "transform_sns_topic_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_sns_topic_length == length(var.transform-lambda-bucket-sns-notifications)
    error_message = "Number of SNS topics does not match expected value"
  }
}

run "transform_sns_topic_subscriptions_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_sns_topic_subscriptions_length == length(flatten(var.transform-lambda-bucket-sns-notifications[*].subscriptions))
    error_message = "Number of SNS topics subscriptions does not match expected value"
  }
}

run "transform_bucket_notification_topics_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_bucket_notification_topics_length == length(var.transform-lambda-bucket-sns-notifications)
    error_message = "Number of S3 Bucket SNS topic subscriptions does not match expected value"
  }
}

run "transform_bucket_notification_queues_length" {
  command = plan

  assert {
    condition     = module.cudl-data-processing.transform_bucket_notification_queues_length == length(var.transform-lambda-bucket-sqs-notifications)
    error_message = "Number of S3 Bucket SQS Queue subscriptions does not match expected value"
  }
}
