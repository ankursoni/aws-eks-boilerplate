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

module "public_ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 4.1.1"

  name = "public-bastion"

  ami                    = data.aws_ami.latestec2ami.image_id
  instance_type          = "t2.micro"
  key_name               = var.bastion_key_pair_name
  vpc_security_group_ids = var.public_security_group_ids
  subnet_id              = var.public_subnets[0]

  user_data_replace_on_change = true
  user_data = base64encode(<<EOM
#!/bin/bash

sudo yum update -y
sudo yum install -y mariadb105

mysql -u${var.database_masterdb_username} -p${var.database_masterdb_password} -h ${split(":", var.db_instance_endpoint)[0]} -P 3306 <<EOS
create database if not exists demodb;
create user if not exists ${var.database_demodb_username} identified by '${var.database_demodb_password}';
grant all on demodb.* to ${var.database_demodb_username};
EOS

EOM
)

  tags = local.tags
}
