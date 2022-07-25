module "vcp_endpoint" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 3.14.2"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service    = "s3"
      subnet_ids = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      # policy     = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    }

    kms = {
      service             = "kms"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    },

    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    },

    elasticloadbalancing = {
      service             = "elasticloadbalancing"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    },

    monitoring = {
      service             = "monitoring"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    }

    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
      tags = local.tags
    }

    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    },

    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
      #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

      tags = local.tags
    },

    # only meant for aurora serverless: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/data-api.html
    # rds = {
    #   service             = "rds"
    #   private_dns_enabled = true
    #   subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
    #   #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

    #   tags = local.tags
    # }    
    # rds-data = {
    #   service             = "rds-data"
    #   private_dns_enabled = true
    #   subnet_ids          = concat(module.vpc.private_subnets, module.vpc.private_subnets)
    #   #policy              = data.aws_iam_policy_document.generic_endpoint_policy.json

    #   tags = local.tags
    # }
  }
}

data "aws_iam_policy_document" "generic_endpoint_policy" {
  statement {
    effect    = "Deny"
    actions   = ["*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpc"
      values   = [module.vpc.vpc_id]
    }
  }
}
