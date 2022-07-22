locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 5.0.0"

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = var.database_subnet_group_name
  subnet_ids             = var.database_subnet_ids
  publicly_accessible    = var.enable_database_public_access

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = var.database_engine
  engine_version       = var.database_engine_version
  family               = var.database_db_parameter_group_family
  major_engine_version = var.database_db_option_group_major_engine_verion
  multi_az             = var.database_is_multi_az
  instance_class       = var.database_instance_class
  identifier           = var.database_instance_name

  allocated_storage = var.database_storage_gb
  storage_type      = var.database_storage_type

  username                            = var.database_masterdb_username
  password                            = var.database_masterdb_password
  create_random_password              = false
  iam_database_authentication_enabled = true

  skip_final_snapshot = true

  tags = local.tags
}
