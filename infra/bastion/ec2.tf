locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

data "aws_ami" "latestec2ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2022-ami-2022.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "private_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "private-bastion"

  ami                    = data.aws_ami.latestec2ami.image_id
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = var.private_security_group_ids
  subnet_id              = var.private_subnets[0]

  tags = local.tags
}

module "public_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "public-bastion"

  ami                    = data.aws_ami.latestec2ami.image_id
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = var.public_security_group_ids
  subnet_id              = var.public_subnets[0]

  tags = local.tags
}
