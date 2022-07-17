locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.3.0"

  bucket = var.s3_bucket_name

  tags = local.tags
}
