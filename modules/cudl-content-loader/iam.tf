// TODO There are far too generous permissions here, and also lots of hardcoded stuff.
resource "aws_iam_policy" "cudl-content-loader-iam-edit-s3-source" {
  name = "${var.environment}-cudl-content-loader-dl-loader-edit-s3-source"
  path = "/"
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"s3:*"
			],
			"Resource": [
				"arn:aws:s3:::${var.environment}-${var.source-bucket-name}",
				"arn:aws:s3:::${var.environment}-${var.source-bucket-name}/*",
				"arn:aws:s3:::sandboxtf-cudl-data-source",
				"arn:aws:s3:::sandboxtf-cudl-data-source/*"
			]
		}
	]
}
EOF
}
//TODO fix
resource "aws_iam_policy" "cudl-content-loader-iam-edit-s3-release" {
  name = "${var.environment}-cudl-content-loader-edit-s3-release"
  path = "/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetLifecycleConfiguration",
                "s3:GetBucketTagging",
                "s3:GetInventoryConfiguration",
                "s3:DeleteObjectVersion",
                "s3:GetObjectVersionTagging",
                "s3:ListBucketVersions",
                "s3:GetBucketLogging",
                "s3:ListBucket",
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketPolicy",
                "s3:GetObjectVersionTorrent",
                "s3:GetObjectAcl",
                "s3:GetEncryptionConfiguration",
                "s3:GetBucketObjectLockConfiguration",
                "s3:GetBucketRequestPayment",
                "s3:GetObjectVersionAcl",
                "s3:GetObjectTagging",
                "s3:GetMetricsConfiguration",
                "s3:GetBucketOwnershipControls",
                "s3:DeleteObject",
                "s3:GetBucketPublicAccessBlock",
                "s3:GetBucketPolicyStatus",
                "s3:ListBucketMultipartUploads",
                "s3:GetObjectRetention",
                "s3:GetBucketWebsite",
                "s3:GetBucketVersioning",
                "s3:GetBucketAcl",
                "s3:GetObjectLegalHold",
                "s3:GetBucketNotification",
                "s3:GetReplicationConfiguration",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectTorrent",
                "s3:GetBucketCORS",
                "s3:GetAnalyticsConfiguration",
                "s3:GetObjectVersionForReplication",
                "s3:GetBucketLocation",
                "s3:GetObjectVersion"
            ],
            "Resource": [
				"arn:aws:s3:::${var.environment}-${var.destination-bucket-name}",
				"arn:aws:s3:::${var.environment}-${var.destination-bucket-name}/*",
				"arn:aws:s3:::sandboxtf-cudl-data-releases",
				"arn:aws:s3:::sandboxtf-cudl-data-releases/*"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_user" "cudl-content-loader-iam-user" {
  path = "/"
  name = "${var.environment}-dl_loading_ui_sandbox"
  tags = {

  }

}

resource "aws_iam_user_policy" "cudl-content-loader-iam-user-policy-source" {
  name   = "${var.environment}-cudl-content-loader-user-policy-source"
  user   = aws_iam_user.cudl-content-loader-iam-user.name
  policy = aws_iam_policy.cudl-content-loader-iam-edit-s3-source.policy
}

resource "aws_iam_user_policy" "cudl-content-loader-iam-user-policy-release" {
  name   = "${var.environment}-cudl-content-loader-user-policy-release"
  user   = aws_iam_user.cudl-content-loader-iam-user.name
  policy = aws_iam_policy.cudl-content-loader-iam-edit-s3-release.policy
}

resource "aws_iam_role" "cudl-content-loader-iam-task-role" {
  path = "/"
  name = "${var.environment}-cudl-iam-task-role"
  assume_role_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":[\"ec2.amazonaws.com\",\"ecs-tasks.amazonaws.com\",\"ecs.amazonaws.com\"]},\"Action\":\"sts:AssumeRole\"}]}"
  max_session_duration = 3600
  tags = {}
}

resource "aws_iam_role_policy" "cudl-content-loader-iam-policy" {
  name = "${var.environment}-cudl-content-loader-iam-role-policy"
  policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ssm:GetAutomationExecution",
				"ssm:ListDocumentVersions",
				"ssm:GetDefaultPatchBaseline",
				"ssm:DescribeDocument",
				"ssm:ListDocumentMetadataHistory",
				"ssm:DescribeMaintenanceWindowTasks",
				"ssm:ListAssociationVersions",
				"ssm:GetPatchBaselineForPatchGroup",
				"ssm:ListInstanceAssociations",
				"ssm:GetParameter",
				"ssm:DescribeMaintenanceWindowExecutions",
				"ssm:GetMaintenanceWindowTask",
				"ssm:DescribeMaintenanceWindowExecutionTasks",
				"ssm:DescribeAutomationStepExecutions",
				"ssm:GetDocument",
				"ssm:GetParametersByPath",
				"ssm:GetMaintenanceWindow",
				"ssm:DescribeInstanceAssociationsStatus",
				"ssm:DescribeAssociationExecutionTargets",
				"ssm:GetPatchBaseline",
				"ssm:DescribeAssociation",
				"ssm:GetConnectionStatus",
				"ssm:GetOpsItem",
				"ssm:GetParameterHistory",
				"ssm:DescribeMaintenanceWindowTargets",
				"ssm:DescribeEffectiveInstanceAssociations",
				"ssm:GetParameters",
				"ssm:GetResourcePolicies",
				"ssm:GetOpsSummary",
				"ssm:GetOpsMetadata",
				"ssm:ListTagsForResource",
				"ssm:DescribeDocumentParameters",
				"ssm:DescribeEffectivePatchesForPatchBaseline",
				"ssm:GetServiceSetting",
				"ssm:DescribeAssociationExecutions",
				"ssm:GetCalendar",
				"ssm:DescribeDocumentPermission",
				"ssm:GetCalendarState"
			],
			"Resource": [
                "${aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key.arn}",
                "${aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id.arn}"
            ]
		},
		{
			"Sid": "VisualEditor1",
			"Effect": "Allow",
			"Action": [
				"ssm:DescribePatchGroups",
				"ssm:ListCommands",
				"ssm:DescribeMaintenanceWindowSchedule",
				"ssm:DescribeInstancePatches",
				"ssm:PutConfigurePackageResult",
				"ssm:DescribePatchGroupState",
				"ssm:GetMaintenanceWindowExecutionTaskInvocation",
				"ssm:DescribeAutomationExecutions",
				"ssm:GetManifest",
				"ssm:DescribeMaintenanceWindowExecutionTaskInvocations",
				"ssm:ListOpsMetadata",
				"ssm:DescribeInstancePatchStates",
				"ssm:DescribeInstancePatchStatesForPatchGroup",
				"ssm:DescribeParameters",
				"ssm:ListResourceDataSync",
				"ssm:GetInventorySchema",
				"ssm:ListDocuments",
				"ssm:DescribeMaintenanceWindowsForTarget",
				"ssm:DescribeInstanceProperties",
				"ssm:ListInventoryEntries",
				"ssm:ListComplianceItems",
				"ssm:GetMaintenanceWindowExecutionTask",
				"ssm:ListOpsItemEvents",
				"ssm:GetDeployablePatchSnapshotForInstance",
				"ssm:DescribeSessions",
				"ssm:GetMaintenanceWindowExecution",
				"ssm:DescribePatchBaselines",
				"ssm:DescribeInventoryDeletions",
				"ssm:ListResourceComplianceSummaries",
				"ssm:DescribePatchProperties",
				"ssm:GetInventory",
				"ssm:DescribeActivations",
				"ssm:ListOpsItemRelatedItems",
				"ssm:DescribeOpsItems",
				"ssm:GetCommandInvocation",
				"ssm:ListComplianceSummaries",
				"ssm:DescribeInstanceInformation",
				"ssm:DescribeMaintenanceWindows",
				"ssm:ListAssociations",
				"ssm:ListCommandInvocations",
				"ssm:DescribeAvailablePatches"
			],
			"Resource": [
                "${aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key.arn}",
                "${aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id.arn}"
            ]
		},
        {
            "Sid": "Statement1",
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "arn:aws:s3:::sandbox.mvn.cudl.lib.cam.ac.uk",
                "arn:aws:s3:::sandbox.mvn.cudl.lib.cam.ac.uk/*",
                "arn:aws:s3:::${var.environment}-cudl-env-files",
                "arn:aws:s3:::${var.environment}-cudl-env-files/",
                "arn:aws:s3:::${var.environment}-cudl-env-files/*"
            ]
        },
		{
			"Sid": "Statement2",
			"Effect": "Allow",
			"Action": [
				"ecr:*"
			],
			"Resource": [
				"${aws_ecr_repository.cudl-content-loader-db-ecr-repository.arn}",
                "${aws_ecr_repository.cudl-content-loader-ui-ecr-repository.arn}"
			]
		}
	]
}
EOF
  role = aws_iam_role.cudl-content-loader-iam-task-role.name
  depends_on = [
    aws_iam_role.cudl-content-loader-iam-task-role,
    aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key-id,
    aws_ssm_parameter.cudl-content-loader-ssm-dl-loader-ui-s3-access-key
  ]
}

resource "aws_iam_access_key" "cudl-content-loader-iam-access-key" {
  status = "Active"
  user = "${var.environment}-dl_loading_ui_sandbox"
  depends_on = [
    aws_iam_user.cudl-content-loader-iam-user
  ]
}

resource "aws_iam_instance_profile" "cudl-content-loader-iam-instance-profile" {
  name = "${var.environment}-cudl-content-loader-iam-instance-profile"
  role = aws_iam_role.cudl-content-loader-iam-task-role.name
}