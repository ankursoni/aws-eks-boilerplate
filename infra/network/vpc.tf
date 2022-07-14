locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }

  network_acls = {
    public_subnet_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 130
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.52.0/22" # database subnets cidr
      },
    ]
    public_subnet_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        # cidr_block  = "192.0.2.0/24" # won't let you ssh further inside the machine
        cidr_block = "0.0.0.0/0"
      },
      {
        rule_number = 130
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.52.0/22" # database subnets cidr
      },
    ]

    private_subnet_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "10.0.100.0/22" # public subnets cidr
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "10.0.100.0/22" # public subnets cidr
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "10.0.100.0/22" # public subnets cidr
      },
      {
        rule_number = 130
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.52.0/22" # database subnets cidr
      },
    ]
    private_subnet_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "10.0.100.0/22" # public subnets cidr
      },
      {
        rule_number = 130
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.52.0/22" # database subnets cidr
      },
    ]

    database_subnet_inbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.0.0/22" # private subnets cidr
      },
    ]
    database_subnet_outbound = [
      {
        rule_number = 100
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.0.0/22" # private subnets cidr
      },
    ]

    public_database_subnet_inbound = [
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.0.0/16" # all subnets
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "${chomp(data.http.myip.body)}/32" # your ip address
      },
    ]
    public_database_subnet_outbound = [
      {
        rule_number = 110
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "10.0.0.0/16" # all subnets
      },
      {
        rule_number = 120
        rule_action = "allow"
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_block  = "${chomp(data.http.myip.body)}/32" # your ip address
      },
    ]

    default_subnet_inbound = [
      {
        rule_number = 900
        rule_action = "allow"
        from_port   = 32768 # ephemeral port range
        to_port     = 65535
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
    ]
    default_subnet_outbound = [
      {
        rule_number = 900
        rule_action = "allow"
        from_port   = 32768 # ephemeral port range
        to_port     = 65535
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0" # internet
      },
    ]
  }
}

# fetch your ip address
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "${var.prefix}-${var.environment}-vpc01"
  cidr = "10.0.0.0/16"

  # based on a general assumption that one is deploying in a region with minimum 2 availability zones
  azs                          = ["${var.region}a", "${var.region}b"]
  private_subnets              = ["10.0.0.0/24", "10.0.1.0/24"]
  create_database_subnet_group = var.create_database_instance ? true : false
  database_subnets             = var.create_database_instance ? ["10.0.52.0/24", "10.0.53.0/24"] : []
  public_subnets               = ["10.0.100.0/24", "10.0.101.0/24"]

  public_dedicated_network_acl = true
  public_inbound_acl_rules     = concat(local.network_acls["public_subnet_inbound"], local.network_acls["default_subnet_inbound"])
  public_outbound_acl_rules    = concat(local.network_acls["public_subnet_outbound"], local.network_acls["default_subnet_outbound"])

  private_dedicated_network_acl = true
  private_inbound_acl_rules     = concat(local.network_acls["private_subnet_inbound"], local.network_acls["default_subnet_inbound"])
  private_outbound_acl_rules    = concat(local.network_acls["private_subnet_outbound"], local.network_acls["default_subnet_outbound"])

  database_dedicated_network_acl = var.create_database_instance ? true : false
  database_inbound_acl_rules = var.create_database_instance ? (
    var.enable_database_public_access ? (
      concat(local.network_acls["database_subnet_inbound"], local.network_acls["public_database_subnet_inbound"], local.network_acls["default_subnet_inbound"])
    ) : concat(local.network_acls["database_subnet_inbound"], local.network_acls["default_subnet_inbound"])
  ) : null
  database_outbound_acl_rules = var.create_database_instance ? (
    var.enable_database_public_access ? (
      concat(local.network_acls["database_subnet_outbound"], local.network_acls["public_database_subnet_outbound"], local.network_acls["default_subnet_outbound"])
    ) : concat(local.network_acls["database_subnet_outbound"], local.network_acls["default_subnet_outbound"])
  ) : null

  # enable one nat gateway per availability zone
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_support   = true
  enable_dns_hostnames = true

  create_database_subnet_route_table     = var.create_database_instance && var.enable_database_public_access ? true : false
  create_database_internet_gateway_route = var.create_database_instance && var.enable_database_public_access ? true : false

  tags = local.tags
}

output "vpc_database_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "vpc_database_subnets" {
  value = module.vpc.database_subnets
}

output "vpc_default_security_group_id" {
  value = module.vpc.default_security_group_id
}

output "private_subnets"{
  value = module.vpc.private_subnets
}

output "public_subnets"{
  value = module.vpc.public_subnets
}
