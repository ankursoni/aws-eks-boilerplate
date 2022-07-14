# aws-eks-boilerplate
AWS EKS Boilerplate

## Install infrastructure on aws

### Pre-requisites
- Install terraform: https://www.terraform.io/downloads

### Create 'values.tfvars' file
```shell
cd infra

# copy the .tfvars template to values.tfvars
cp values.tfvars.template values.tfvars

# update the 'values.tfvars' file like the following, where,
# - 'region' is the aws region code for e.g. ap-southeast-2
# - 'prefix' is the prefix for naming resources for e.g. aws-eks-boilerplate
# - 'environment' is the middle name for naming resources for e.g. demo

# - 'create_database_instance' is true / false for creating the rds database instance
# - 'enable_database_public_access' is true / false for enabling public access to the rds database instance (which is given to user's public ip address who is running the terraform script)
# - 'database_instance_name' is rds database instance name for e.g. demo-database
# - 'database_masterdb_username' is rds database masterdb username for e.g. demouser
# - 'database_masterdb_password' is rds database masterdb password for e.g. demouser

# - 'create_s3_bucket' is true / false for creating the s3 bucket
# - 's3_bucket_name' is the globally unique s3 bucket name for e.g. demo-s3-t1234

# - bastion_key_pair_name is the name of key pair used by ec2 instance for ssh into bastion hosts for e.g. access_key. This has to be created beforehand by the user: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html
```

### Run terraform
```shell
cd infra

terraform init

terraform apply -var-file=values.tfvars

# delete all resources created by terraform
terraform destroy
```

### Access RDS database instance from bastion hosts

If the user has not enabled 'enable_database_public_access' then, the rds database instance is only accessible to the bastion host running inside the private subnet. And the bastion host running inside private subnet is only accessible to the bastion host running inside the public subnet.

```shell
# assuming you have created 'bastion_key_pair_name' as 'access_key' and downloaded key pair to ~/Downloads folder
chmod 0700 ~/Downloads/access_key.pem

# copy key pair inside public bastion host
scp -i ~/Downloads/access_key.pem ~/Downloads/access_key.pem ec2-user@<PUBLIC IPv4 DNS OF public-bastion>:~

# ssh into public bastion host
ssh -i ~/Downloads/access_key.pem ec2-user@<PUBLIC IPv4 DNS OF public-bastion>

# ssh into private bastion host from inside public bastion host
ssh -i ~/access_key.pem ec2-user@<PRIVATE IPv4 DNS OF private-bastion>

# install mysql using yum
sudo yum upgrade
sudo yum install mysql

# connect to rds and enter '<DATABASE_MASTERDB_PASSWORD>' for password prompt
mysql -u <DATABASE_MASTERDB_USERNAME> -h <RDS DATABASE ENDPOINT DNS> -P 3306 -p

# press ctrl+d multiple times to exit
```