module "s3_alb" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"

  create_bucket = true

  # only lowercase alphanumeric characters and hyphens allowed
  bucket = "${local.namespace}-alb.logs"
  acl    = "private"

  attach_elb_log_delivery_policy = true

  versioning = {
    enabled = true
  }
}
