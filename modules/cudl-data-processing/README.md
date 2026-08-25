# cudl-data-processing module

This module creates the AWS infrastructure for the CUDL data processing pipeline: the S3 buckets holding source, enhancement and release data, the Lambda functions that transform TEI source documents into release files, the EFS filesystem and DataSync tasks they share, and the SQS/SNS wiring that triggers them.

It also creates an optional CloudFront distribution serving the destination bucket, which is what delivers the processed artefacts to the public.

For the pipeline narrative — how data moves from TEI source through the Lambdas to the releases files — see [`docs/data-loading.md`](../../docs/data-loading.md). This README covers using the module, and the CloudFront delivery behaviour in particular.

## What it creates

- S3 buckets for source, enhancements and destination data, with versioning, bucket policies and event notifications.
- Lambda functions (plus aliases, layers and event source mappings) that perform the transforms, triggered from SQS.
- SQS queues and SNS topics connecting bucket events to the Lambdas.
- An EFS filesystem, access points and mount targets, with security groups, plus DataSync tasks and locations for moving data between EFS and S3.
- A CloudWatch dashboard, and IAM roles and policies for the above.
- When `create_cloudfront_distribution` is set:
  - A CloudFront distribution fronting the destination bucket, with an origin access control.
  - A WAFv2 WebACL protecting the distribution.
  - Route 53 records for the distribution domain, and an ACM certificate if `acm_create_certificate` is set (otherwise `acm_certificate_arn` supplies an existing one).
  - A `Cache-Control: no-store` response headers policy, if any behavior uses `prevent_all_caching` (see below).

CloudFront is a global service, so the distribution itself is not regional. These resources use the `aws.us-east-1` provider alias because the WebACL needs `scope = "CLOUDFRONT"` and the certificate must be issued in that region; the caller must supply the alias.

## CloudFront caching and compression

The distribution has one default cache behavior and, optionally, a list of path-specific ordered behaviors. CloudFront evaluates the ordered behaviors in list order, first match wins, and anything matching none of them falls through to the default.

### Path patterns match the URL the viewer sent

This is the caveat that catches people. CloudFront selects the cache behavior **before** the viewer-request function runs, so `path_pattern` must match the incoming URL, not whatever the function rewrites it to.

If a function rewrites `/path/to/my/page` to `/path/to/my/page.html`, then:

- `/path/to/my/page` matches.
- `*.html` does not.

A rewrite can also move a path into an entirely different tree, which hides it from patterns aimed at where the object actually lives. If `/data-feed` is rewritten to `/generated/feeds/data.json`, then `/data-feed` matches, but neither `*.json` nor `/generated/*` does.

Two related points:

- Patterns are matched against the path only. Query strings are invisible to behavior selection; they are a cache key concern, controlled by the cache policy.
- The cache key uses the URI *after* the rewrite, so a rewritten path and a direct request for the same underlying object share one cached copy.

### Ordering

Entries are evaluated in the order given, so list specific patterns before broad ones. Note that a trailing wildcard is a prefix match: `/search*` also matches `/search.config.json`.

### Compression

Setting `compress = true` is not sufficient on its own. CloudFront only compresses when the attached cache policy also has Gzip and Brotli enabled:

| Managed cache policy | TTLs | Compression |
| --- | --- | --- |
| `Managed-CachingDisabled` | all 0 | **disabled** |
| `Managed-CachingOptimized` | 1s / 24h / 365d | enabled |
| `Managed-UseOriginCacheControlHeaders` | 0 / 0 / 365d | enabled |

The module's default for `cloudfront_default_cache_policy` is `Managed-CachingDisabled`, which preserves the historical configuration but means the default behavior's `compress` setting has no effect. Deployments that want compression on the catch-all should set a policy that supports it.

Beyond the policy, CloudFront only compresses objects between 1,000 and 10,000,000 bytes whose `Content-Type` is on its own fixed allowlist — `text/*`, `application/json`, `application/xml`, `image/svg+xml`, `application/pdf` and the legacy font formats among them. Already-compressed types such as JPEG, PNG, WOFF2 and Office documents are skipped automatically, so there is no need to exclude them by hand.

### Preventing caching

A cache policy only controls CloudFront's own storage; it says nothing to the browser, which is then free to cache heuristically from `Last-Modified`. Preventing caching properly needs both layers, which is what `prevent_all_caching` does: it selects `Managed-CachingDisabled` and attaches a module-managed policy setting `Cache-Control: no-store`.

Note that these paths cannot be compressed at the edge. CloudFront rejects a cache policy that sets both zero TTLs and the accept-encoding parameters — the encoding settings are part of the cache key, and there is no cache key when nothing is cached. Uncached and compressed is not an available combination.

Use it for live query endpoints and anything else that must never be served stale. `response_headers_policy_id` remains available for the other cases, such as CORS, where you pass the ID of a policy you have created yourself. The two cannot be combined on the same behavior.

## Inputs

The module has around 50 variables covering the buckets, Lambdas, EFS and networking; see `variables.tf` for the full set. The CloudFront and caching inputs are:

- `create_cloudfront_distribution` (string, optional, default: `false`)  
  Whether to create the distribution and its supporting resources at all. When false, none of the inputs below have any effect.

- `cloudfront_distribution_name` (string, optional, default: `transcriptions`)  
  Name of the distribution and associated resources; combined with the environment and hosted zone to form the domain.

- `cloudfront_default_cache_policy` (string, optional, default: `Managed-CachingDisabled`)  
  Managed cache policy name for the default cache behavior. See the compression table above before changing it.

- `cloudfront_ordered_cache_behaviors` (list(object), optional, default: `[]`)  
  Path-specific behaviors, evaluated before the default. An empty list leaves the distribution unchanged. Each object takes:
  - `path_pattern` (string, required) — matched against the incoming viewer URI. Must be unique within the list.
  - `cache_policy_name` (string, default: `Managed-CachingOptimized`) — managed policy name. Ignored when `prevent_all_caching` is set.
  - `prevent_all_caching` (bool, default: `false`) — stop both the edge and the browser caching this path.
  - `compress` (bool, default: `true`) — attempt Gzip/Brotli compression. Only takes effect if the cache policy supports it.
  - `allowed_methods` (list(string), default: `["GET", "HEAD", "OPTIONS"]`)
  - `cached_methods` (list(string), default: `["GET", "HEAD"]`)
  - `attach_viewer_request_function` (bool, default: `true`) — attach `cloudfront_viewer_request_function_arn` to this behavior. Setting this to false for a path whose S3 key only exists after a rewrite will produce a 404.
  - `response_headers_policy_id` (string, optional) — ID, not a name, so a resource reference can be passed. Cannot be combined with `prevent_all_caching`.

- `cloudfront_viewer_request_function_arn` (string, optional, default: `null`)  
  ARN of a CloudFront Function handling viewer requests, typically for URL rewriting.

- `cloudfront_default_root_object` (string, optional, default: `null`)  
  Object returned for the root URL. Applies to the default behavior only, never to an ordered behavior.

- `cloudfront_origin_path` (string, optional, default: `null`)  
  Path within the destination bucket to serve as the origin root.

- `cloudfront_alternative_domain_names` (list(string), optional, default: `[]`)  
  Additional aliases for the distribution.

- `cloudfront_error_response_page_path` (string, optional, default: `null`)  
  Bucket path to a custom error page. Used with `cloudfront_error_code_to_catch` (default `403`), `cloudfront_error_response_code` (default `404`) and `cloudfront_error_caching_min_ttl` (default `60`).

- `cloudfront_access_logging` (bool, optional, default: `false`)  
  Whether to log requests, written to `cloudfront_access_logging_bucket`.

- `cloudfront_route53_zone_id` (string, optional, default: `null`)  
  Hosted zone in which to create the distribution's DNS records.

## Example usage

Caching the whole site, with a live search endpoint excluded. Only a few of the pipeline inputs are shown; see `variables.tf` for the rest.

```hcl
module "cudl-data-processing" {
  source = "../modules/cudl-data-processing"

  environment                  = local.environment
  source-bucket-name           = var.source-bucket-name
  destination-bucket-name      = var.destination-bucket-name
  enhancements-bucket-name     = var.enhancements-bucket-name
  efs-name                     = var.efs-name
  releases-root-directory-path = var.releases-root-directory-path
  lambda-jar-bucket            = var.lambda-jar-bucket
  transform-lambda-information = var.transform-lambda-information
  vpc-id                       = module.base_architecture.vpc_id
  aws-account-number           = data.aws_caller_identity.current.account_id

  create_cloudfront_distribution         = true
  cloudfront_route53_zone_id             = var.cloudfront_route53_zone_id
  cloudfront_distribution_name           = var.cloudfront_distribution_name
  cloudfront_viewer_request_function_arn = aws_cloudfront_function.viewer.arn
  cloudfront_default_cache_policy        = "Managed-CachingOptimized"

  cloudfront_ordered_cache_behaviors = [
    {
      path_pattern        = "/search*"
      prevent_all_caching = true
    },
  ]

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
```

Several behaviors together, showing ordering and a caller-supplied CORS policy. Because `response_headers_policy_id` takes a resource reference, the list has to be built in `locals.tf` rather than set in `terraform.tfvars`:

```hcl
resource "aws_cloudfront_response_headers_policy" "cors" {
  name = "${local.environment}-cors"

  cors_config {
    access_control_allow_credentials = false
    origin_override                  = true

    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD"]
    }
    access_control_allow_origins {
      # The origins whose pages fetch these files, not this distribution's own domain
      items = ["https://cudl.lib.cam.ac.uk"]
    }
  }
}

locals {
  cloudfront_ordered_cache_behaviors = [
    # Listed before /json/*, which would otherwise match these paths first
    {
      path_pattern               = "/json/manifests/*"
      cache_policy_name          = "Managed-CachingOptimized"
      response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id
    },
    {
      path_pattern      = "/json/*"
      cache_policy_name = "Managed-CachingOptimized"
    },
    {
      path_pattern        = "/search*"
      prevent_all_caching = true
    },
    # Add as many behaviors as needed; CloudFront evaluates them in this order
  ]
}
```

The list is then passed straight through:

```hcl
cloudfront_ordered_cache_behaviors = local.cloudfront_ordered_cache_behaviors
```
