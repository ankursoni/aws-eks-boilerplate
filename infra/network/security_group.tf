module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.9.0"

  use_name_prefix = false
  name            = "${var.prefix}-${var.environment}-rdssg"
  description     = "Allow inbound to RDS"
  vpc_id          = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "mysql-tcp"
      cidr_blocks = "${chomp(data.http.myip.body)}/32" # your ip address
    },
  ]

  count = var.create_database_instance && var.enable_database_public_access ? 1 : 0

  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

output "rds_security_group_id" {
  value = var.create_database_instance && var.enable_database_public_access ? module.rds_security_group[0].security_group_id : null
}

module "public_bastion_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.9.0"

  use_name_prefix = false
  name            = "${var.prefix}-${var.environment}-publicbastionsg"
  description     = "Allow inbound to RDS"
  vpc_id          = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "${chomp(data.http.myip.body)}/32" # your ip address
    },
  ]

  count = var.create_bastion ? 1 : 0

  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

output "public_bastion_security_group_id" {
  value = var.create_bastion ? module.public_bastion_security_group[0].security_group_id : null
}
