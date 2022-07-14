module "vcp_endpoint" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.14.2"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service    = "s3"
      subnet_ids = module.vpc.private_subnets

      tags = local.tags
    }

    # rds = {
    #   service = "rds"
    #   private_dns_enabled = true
    #   subnet_ids = module.vpc.private_subnets
    #   # security_group_ids = [aws_security_group.rdssg.id]

    #   tags = local.tags
    # }

    # ecr_api = {
    #   service = "ecr.api"
    #   private_dns_enabled = true
    #   subnet_ids = module.vpc.private_subnets

    #   tags = local.tags
    # }
  }
}
