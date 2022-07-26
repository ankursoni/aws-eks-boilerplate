module "network" {
  source                        = "./network"
  providers                     = { aws = aws.default }
  region                        = var.region
  prefix                        = var.prefix
  environment                   = var.environment
  create_database_instance      = var.create_database_instance
  enable_database_public_access = var.enable_database_public_access
  create_bastion                = var.create_bastion
}

module "database" {
  source      = "./database"
  providers   = { aws = aws.default }
  environment = var.environment
  vpc_security_group_ids = var.enable_database_public_access ? (
    [module.network.vpc_default_security_group_id, module.network.rds_security_group_id]
  ) : [module.network.vpc_default_security_group_id]
  database_subnet_group_name                   = module.network.vpc_database_subnet_group_name
  database_subnet_ids                          = module.network.vpc_database_subnets
  enable_database_public_access                = var.enable_database_public_access
  database_engine                              = var.database_engine
  database_engine_version                      = var.database_engine_version
  database_db_parameter_group_family           = var.database_db_parameter_group_family
  database_db_option_group_major_engine_verion = var.database_db_option_group_major_engine_verion
  database_is_multi_az                         = var.database_is_multi_az
  database_instance_class                      = var.database_instance_class
  database_instance_name                       = var.database_instance_name
  database_storage_gb                          = var.database_storage_gb
  database_storage_type                        = var.database_storage_type
  database_masterdb_username                   = var.database_masterdb_username
  database_masterdb_password                   = var.database_masterdb_password

  count      = var.create_database_instance ? 1 : 0
  depends_on = [module.network]
}

module "storage" {
  source         = "./storage"
  providers      = { aws = aws.default }
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name

  count      = var.create_s3_bucket ? 1 : 0
  depends_on = [module.network]
}

module "bastion" {
  source                     = "./bastion"
  providers                  = { aws = aws.default }
  environment                = var.environment
  bastion_key_pair_name      = var.bastion_key_pair_name
  private_security_group_ids = [module.network.vpc_default_security_group_id]
  public_security_group_ids  = [module.network.vpc_default_security_group_id, module.network.public_bastion_security_group_id]
  private_subnets            = module.network.private_subnets
  public_subnets             = module.network.public_subnets
  db_instance_endpoint       = module.database[0].db_instance_endpoint
  database_masterdb_username = var.database_masterdb_username
  database_masterdb_password = var.database_masterdb_password
  database_demodb_username   = var.database_demodb_username
  database_demodb_password   = var.database_demodb_password

  count      = var.create_bastion ? 1 : 0
  depends_on = [module.network, module.database]
}

module "cluster" {
  source                            = "./cluster"
  providers                         = { aws = aws.default }
  region                            = var.region
  prefix                            = var.prefix
  environment                       = var.environment
  vpc_id                            = module.network.vpc_id
  vpc_security_group_ids            = [module.network.vpc_default_security_group_id]
  subnets                           = concat(module.network.private_subnets, module.network.public_subnets)
  eks_kubernetes_version            = var.eks_kubernetes_version
  eks_managed_instance_min_size     = var.eks_managed_instance_min_size
  eks_managed_instance_max_size     = var.eks_managed_instance_max_size
  eks_managed_instance_desired_size = var.eks_managed_instance_desired_size
  eks_managed_instance_types        = var.eks_managed_instance_types
  eks_managed_capacity_type         = var.eks_managed_capacity_type

  count      = var.create_eks_cluster ? 1 : 0
  depends_on = [module.network]
}
