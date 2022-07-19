variable "region" {
  default = ""
}
variable "prefix" {
  default = ""
}
variable "environment" {
  default = ""
}

variable "create_database_instance" {
  default = false
}
variable "enable_database_public_access" {
  default = false
}
variable "database_engine" {
  default = "mysql"
}
variable "database_engine_version" {
  default = "8.0.29"
}
variable "database_db_parameter_group_family" {
  default = "mysql8.0"
}
variable "database_db_option_group_major_engine_verion" {
  default = "8.0"
}
variable "database_is_multi_az" {
  default = false
}
variable "database_instance_class" {
  default = "db.t3.micro"
}
variable "database_instance_name" {
  default = ""
}
variable "database_storage_gb" {
  default = 10
}
variable "database_storage_type" {
  default = "gp2"
}
variable "database_masterdb_username" {
  default = ""
}
variable "database_masterdb_password" {
  default = ""
}

variable "create_s3_bucket" {
  default = false
}
variable "s3_bucket_name" {
  default = ""
}

variable "create_bastion" {
  default = false
}
variable "bastion_key_pair_name" {
  default = ""
}

variable "create_eks_cluster" {
  default = false
}
variable "eks_kubernetes_version" {
  default = "1.22"
}
variable "eks_managed_instance_min_size" {
  default = 1
}
variable "eks_managed_instance_max_size" {
  default = 10
}
variable "eks_managed_instance_desired_size" {
  default = 1
}
variable "eks_managed_instance_types" {
  default = ["t3.medium"]
}
variable "eks_managed_capacity_type" {
  default = "ON_DEMAND" # SPOT or ON_DEMAND
}
