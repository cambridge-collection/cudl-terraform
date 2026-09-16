# CUDL Data Loading / `cudl-data-processing` Module

This document describes the data loading process and the infrastructure created by the `modules/cudl-data-processing` module and related components.

It complements the high-level project overview in `README.md`.

---

## Overview

The data loading process converts source CUDL data into the formats used by the viewer and downstream systems. Examples include:

- Transforming TEI into JSON for the viewer
- Copying or transforming HTML and JSON artefacts
- Indexing content into SOLR
- Handling Transkribus data for enhanced transcriptions

The core Terraform for this lives in:

- `modules/cudl-data-processing`
- Environment-specific wiring (buckets, VPC, certificates, etc.) in directories such as `cul-cudl-staging/`.

For application-level transformation logic see:

- https://github.com/cambridge-collection/data-lambda-transform
- https://github.com/cambridge-collection/cudl-solr-listener
- https://github.com/cambridge-collection/transkribus-import

---

## High-level architecture

The module and its callers create and connect the following AWS resources:

- **S3 buckets**
  - Source CUDL data (pre-processing)
  - Destination / releases data (post-processing)
  - Enhancements / Transkribus data
- **Lambda functions**
  - Java JAR-based Lambdas from `data-lambda-transform`
  - Container-based Lambdas (TEI processing, SOLR listeners, Transkribus ingest)
- **SQS and SNS**
  - Queues per processing stage (e.g. HTML, collections, index, copy-to-EFS)
  - Optional SNS topics for S3 event fan-out
- **EFS**
  - Encrypted file system with mount targets in the CUDL VPC
  - Access point for use by Lambdas and ECS workloads
- **DataSync**
  - S3 → EFS tasks for copying releases data to the shared EFS volume
- **CloudFront & WAF**
  - Optional distribution exposing processed artefacts
  - WAFv2 WebACL protecting the distribution
- **Route53 & ACM**
  - DNS records and certificates if CloudFront is enabled
- **IAM**
  - Roles and policies for Lambdas and DataSync
- **CloudWatch**
  - Dashboards for Lambda and SQS metrics

This diagram shows this infrastructure end to end.
![CUDL Data Processing Architecture](images/CUDL_data_processingv5.svg)


---

## Lambda functions

The data loading stack uses a combination of JAR-based and container-based Lambda functions. The core ones are:

| Lambda name                                           | Type      | Runtime | Source Code                                                   |
| :---------------------------------------------------- | :-------- | :------ | :------------------------------------------------------------ |
| AWSLambda_CUDLPackageData_Collection_SOLR_Listener    | Container | Docker  | https://github.com/cambridge-collection/cudl-solr-listener    |
| AWSLambda_CUDLPackageData_COPY_FILE_S3_to_EFS         | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_DATASET_JSON                | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_FILE_UNCHANGED_COPY         | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_HTML_to_HTML_Translate_URLS | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_JSON_to_JSON_Translate_URLS | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_SOLR_Listener               | Container | Docker  | https://github.com/cambridge-collection/cudl-solr-listener    |
| AWSLambda_CUDLPackageData_TEI_Processing              | Container | Docker  | https://github.com/cambridge-collection/transkribus-import    |
| AWSLambda_CUDL_Transkribus_Ingest                     | Container | Docker  | https://github.com/cambridge-collection/transkribus-import    |
| AWSLambda_CUDLPackageData_UI_JSON                     | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |
| AWSLambda_CUDLPackageData_UPDATE_DB                   | Java Jar  | Java 11 | https://github.com/cambridge-collection/data-lambda-transform |

Each environment wires these functions through the `transform-lambda-information` variable in its `terraform.tfvars` file (for example `cul-cudl-staging/terraform.tfvars`), specifying:

- Name, timeout, memory, and concurrency settings
- Whether the function uses a JAR (`jar_path` + `runtime`) or a container image (`image_uri`)
- Queue name and VPC networking (VPC, subnets, security groups)
- Environment variables and optional EFS mount configuration

---

## AWS resources created by the module

The `cudl-data-processing` module and its supporting code create:

- **IAM**
  - Execution roles for all Lambdas, with permissions for:
    - S3 read/write on source, destination, and enhancements buckets
    - SQS receive/delete
    - CloudWatch Logs
    - VPC networking and EFS access
  - DataSync role and policy for S3 → EFS transfers

- **Storage**
  - S3 buckets for:
    - Source (`<env>-<source-bucket-name>`)
    - Destination/releases (`<env>-<destination-bucket-name>`)
    - Enhancements (`<env>-<enhancements-bucket-name>`)
  - EFS file system, access point, and mount targets in the CUDL VPC

- **Messaging and events**
  - SQS queues and dead-letter queues, one per logical processing queue
  - SNS topics and subscriptions used by S3 notifications where configured
  - S3 bucket notifications wired to SQS and SNS

- **Compute**
  - Lambda functions and aliases for each entry in `transform-lambda-information`
  - Lambda layer containing generated properties files (e.g. bucket names, prefixes)

- **Data transfer**
  - DataSync locations (S3 and EFS)
  - DataSync tasks for bulk copy of releases S3 → EFS

- **Edge & security**
  - Optional CloudFront distribution in `us-east-1` exposing the destination bucket
  - WAFv2 WebACL for the distribution, using AWS managed rule groups with an optional IP allow list and rate limiting
  - Route53 records and ACM certificates (if configured to be created)

- **Monitoring**
  - CloudWatch dashboards for Lambda and SQS metrics

For the exact resource definitions, see:

- `modules/cudl-data-processing/*.tf`
- Environment-specific variables in `cul-cudl-*/terraform.tfvars`

---

## CloudFront WAF

When `create_cloudfront_distribution` is enabled, the module creates a WAFv2 WebACL in `us-east-1` and associates it with the distribution. The WebACL allows requests by default and applies the following AWS managed rule groups:

| Priority | Rule group                              |
| :------- | :-------------------------------------- |
| 0        | `AWSManagedRulesAmazonIpReputationList` |
| 1        | `AWSManagedRulesCommonRuleSet`          |
| 2        | `AWSManagedRulesKnownBadInputsRuleSet`  |

Within the common rule set, `NoUserAgent_HEADER` is overridden to count rather than block, so requests without a user agent are recorded but still served.

Two further rules are optional and off by default: an IP allow list at priority 3 and rate limiting at priority 4. Rules are evaluated in priority order, so the allow list is always considered before rate limiting.

### IP allow list

An optional allow rule (priority 3) permits requests from a set of CIDR ranges, typically the UL VPN. Providing one or more ranges creates an `aws_wafv2_ip_set` named `<environment>-<cloudfront_distribution_name>-<waf_ip_allow_list_name>` and adds the rule that references it:

| Variable                      | Default    | Description                                                                               |
| :---------------------------- | :--------- | :---------------------------------------------------------------------------------------- |
| `waf_ip_allow_list_addresses` | `[]`       | CIDR ranges allowed unconditionally. An empty list disables the allow list and its IP set  |
| `waf_ip_allow_list_name`      | `"UL_VPN"` | Suffix for the IP set name, prefixed with the environment and distribution name            |

The rule is terminating: a request from a listed range is allowed outright and no later rule is evaluated, which is what exempts those addresses from rate limiting. Because it sits after the managed rule groups rather than before them, allow-listed traffic is still inspected for bad input and IP reputation, and is blocked if it trips either.

Note that the IP set holds IPv4 ranges only. CloudFront serves IPv6 by default, so a client connecting over IPv6 arrives with a source address the allow list cannot match and is rate limited as normal.

Rule matches are published to CloudWatch, and sampled requests are retained for inspection in the WAF console, under the metric name `<environment>-<cloudfront_distribution_name>-waf-web-acl-rule-ip-allow-list`.

For example, in an environment's `main.tf`:

```hcl
module "cudl-data-processing" {
  # ...
  waf_ip_allow_list_addresses = ["192.0.2.0/24"] # replace with the real VPN range
  waf_ip_allow_list_name      = "UL_VPN"
}
```

### Rate limiting

An optional rate-based rule (priority 4) blocks requests from a single originating IP address once they exceed a configured limit within an evaluation window. It is disabled by default and is wired up per environment through the following variables:

| Variable                                  | Default         | Description                                                                                   |
| :---------------------------------------- | :-------------- | :-------------------------------------------------------------------------------------------- |
| `waf_use_rate_limiting`                   | `false`         | Whether to add the rate-based rule to the WebACL                                               |
| `waf_rate_limit`                          | `300`           | Requests permitted from one IP address within the evaluation window                            |
| `waf_rate_limiting_evaluation_window`     | `300`           | Seconds over which requests are counted. Valid values are `60`, `120`, `300` and `600`         |
| `waf_rate_limiting_scope_down_uri`        | `null`          | URI path to restrict rate limiting to. If unset, all requests to the distribution are counted  |
| `waf_rate_limiting_scope_down_match_type` | `"STARTS_WITH"` | How the scope-down URI is matched: `EXACTLY`, `STARTS_WITH`, `CONTAINS` or `ENDS_WITH`         |

The scope-down URI narrows which requests the rule counts, so rate limiting can be targeted at expensive paths (for example `/iiif/`) while leaving the rest of the distribution unthrottled. Requests falling outside the scope-down match are neither counted nor blocked by this rule. Paths are normalised before matching but compared case-sensitively, so a scope-down URI of `/iiif/` will not match a request to `/IIIF/`.

Rule matches are published to CloudWatch, and sampled requests are retained for inspection in the WAF console, under the metric name `<environment>-<cloudfront_distribution_name>-waf-web-acl-rule-rate-limiting`.

For example, in an environment's `main.tf`:

```hcl
module "cudl-data-processing" {
  # ...
  waf_use_rate_limiting                   = true
  waf_rate_limit                          = 500
  waf_rate_limiting_evaluation_window     = 60
  waf_rate_limiting_scope_down_uri        = "/iiif/"
  waf_rate_limiting_scope_down_match_type = "STARTS_WITH"
}
```

---

## Existing / external resources expected

The module expects several external resources to exist and be referenced via variables:

- ECR repositories and images for container-based Lambdas
- S3 Maven/JAR bucket containing built Lambda artefacts
- (Optionally) S3 buckets containing XSLT artefacts used by the transformation code

These are documented in more detail in:

- `docs/environment-setup.md`

