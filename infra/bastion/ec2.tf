locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

module "private_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name = "private-bastion"

  ami                    = "ami-07620139298af599e"
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = var.private_security_group_ids
  subnet_id              = var.private_subnets[0]

  tags = local.tags
}

module "public_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.0.0"

  name = "public-bastion"

  ami                    = "ami-07620139298af599e"
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = var.public_security_group_ids
  subnet_id              = var.public_subnets[0]

  tags = local.tags
}
