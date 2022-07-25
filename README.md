# aws-eks-boilerplate

[![Build](https://github.com/ankursoni/aws-eks-boilerplate/actions/workflows/build.yml/badge.svg)](https://github.com/ankursoni/aws-eks-boilerplate/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/ankursoni/aws-eks-boilerplate/branch/main/graph/badge.svg?token=ZZWMD4FB93)](https://codecov.io/gh/ankursoni/aws-eks-boilerplate)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![License](https://img.shields.io/github/license/ankursoni/aws-eks-boilerplate)](/LICENSE)


> AWS EKS Boilerplate
This project helps serve as a boilerplate / template for a typical application running on Kubernetes which has been setup with:
- [AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) cluster
- [AWS RDS DB Instance (MySQL)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.DBInstance.html) for database
- [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) for storage
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) for secrets
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) for load balancing
- [AWS CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html) for monitoring
- [AWS Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html) for dns
- [AWS VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) for networking

![aws topology infrastructure](docs/images/aws-topology-Infrastructure.png)

## Install demo app locally

### Pre-requisites
- Install python 3.9.13: https://www.python.org/downloads/release/python-3913/
- Install mysql: https://dev.mysql.com/downloads/mysql/
- Install redis: https://developer.redis.com/create/windows
- Install docker desktop: https://docs.docker.com/get-docker/
- Install local kubernetes by docker desktop: https://docs.docker.com/desktop/kubernetes/
- Install helm: https://helm.sh/docs/intro/install/
- Install aws cli: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Setup demo app
```sh
# create a virtual environment
# assuming you have "python3 --version" = "Python 3.9.13" installed in the current terminal session
python3 -m venv ./demo/venv

# activate virtual environment
# for macos or linux
source ./demo/venv/bin/activate
# for windows
.\demo\venv\Scripts\activate

# upgrade pip
python -m pip install --upgrade pip

# install python dependencies
pip install -r ./demo/requirements.txt -r ./demo/requirements_dev.txt

# lint python code
pylint ./demo
```

### Setup demodb database with user
```sh
# assuming you have a mysql instance running locally

# connect to mysql instance and enter '<DATABASE_MASTERDB_PASSWORD>' for password prompt
mysql -u <DATABASE_MASTERDB_USERNAME> -h <RDS DATABASE ENDPOINT DNS> -P 3306 -p

# run the following scripts by replacing:
# - 'user1' with <username>
# - 'password1' with <password>
# - 'localhost' with <database server>
create database if not exists demodb;

create user if not exists user1@localhost identified by 'password1';

grant all on demodb.* to user1@localhost;
```

### Setup s3 bucket with access credentials
Create or reuse an S3 bucket with a user credential
that is assigned an IAM policy that allows read from the s3 bucket and its objects.  
Follow step 1 from
https://www.gormanalysis.com/blog/connecting-to-aws-s3-with-python/#1-set-up-credentials-to-connect-python-to-s3  
Finally, upload the file - 'demo/data/s3_demo.txt' to the s3 bucket

### Setup redis with key/value pair
```sh
# assuming you have a redis server running locally
redis-cli

# set value for key - 'demo'
set demo "This is a demo text from redis!"
```

### Install demo app locally
1. Run as web api server:
```sh
# run the database migrations
# environment DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
DB_CONNECTION_URL="mysql+mysqldb://user1:password1@localhost/demodb" \
alembic -c ./demo/alembic_dev.ini upgrade head
```

NOTE: to check if the database migrations ran successfully, connect with your locally running mysql db instance:
```sh
mysql -u root
```
```sql
show databases;
+--------------------+
| Database           |
+--------------------+
| demodb             |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+

use demodb

show tables;
+------------------+
| Tables_in_demodb |
+------------------+
| alembic_version  |
| demo             |
+------------------+

select * from demo;
+----+-------------+
| id | description |
+----+-------------+
|  1 | demo1       |
|  2 | demo2       |
+----+-------------+
```

```sh
# run the flask api
# environment DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
# environment REDIS_HOST = redis server host
# environment AWS_REGION = aws region code like 'ap-southeast-2'
# environment AWS_S3_BUCKET = aws s3 bucket name
# environment AWS_ACCESS_KEY_ID = aws user credential access key id
# environment AWS_SECRET_ACCESS_KEY = aws user credential secret access key
# argument --debug-mode = true or false (default) to enable debug mode logging
FLASK_ENV=development \
DB_CONNECTION_URL="mysql+mysqldb://user1:password1@localhost/demodb" \
AWS_REGION="<AWS REGION>" \
AWS_S3_BUCKET="<AWS S3 BUCKET>" \
AWS_ACCESS_KEY_ID="<AWS ACCESS KEY ID>" \
AWS_SECRET_ACCESS_KEY="<AWS SECRET ACCESS KEY>" \
REDIS_HOST="localhost" \
python -m demo.app --debug-mode true

# curl to hit demo api
curl http://localhost:8080
>>> Welcome to demo api!

curl http://localhost:8080/rds
>>> [{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
>>> This is a demo text file from s3!

curl http://localhost:8080/redis
>>> This is a demo text from redis!
```

2. Or, build and run in docker container:
```sh
# change directory to demo
cd demo

# build docker image
# --build-arg DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
# using 'host.docker.internal' as database server to reach out to local mysql running on host
# --build-arg DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
# --build-arg REDIS_HOST = redis server host
# --build-arg AWS_REGION = aws region code like 'ap-southeast-2'
# --build-arg AWS_S3_BUCKET = aws s3 bucket name
# --build-arg AWS_ACCESS_KEY_ID = aws user credential access key id
# --build-arg AWS_SECRET_ACCESS_KEY = aws user credential secret access key
docker build \
	--build-arg DB_CONNECTION_URL="mysql+mysqldb://user1:password1@host.docker.internal/demodb" \
	--build-arg AWS_REGION="<AWS REGION>" \
	--build-arg AWS_S3_BUCKET="<AWS S3 BUCKET>" \
	--build-arg AWS_ACCESS_KEY_ID="<AWS ACCESS KEY ID>" \
	--build-arg AWS_SECRET_ACCESS_KEY="<AWS SECRET ACCESS KEY>" \
	--build-arg REDIS_HOST="host.docker.internal" \
	-t eks-demo:app --platform linux/amd64 .

# run docker container with 'migrateThenApi' command
# you can also use other commands:
# - 'migrate' for running database migrations
# - 'api' for running the demo api
docker run -d -p 8080:8080 --name eks-demo-app eks-demo:app \
	migrateThenApi --debug-mode=true

# check docker container logs
docker logs eks-demo-app

# curl to hit demo api
curl http://localhost:8080
>>> Welcome to demo api!

curl http://localhost:8080/rds
>>> [{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
>>> This is a demo text file from s3!

curl http://localhost:8080/redis
>>> This is a demo text from redis!

# stop and remove docker container
docker stop eks-demo-app
docker rm eks-demo-app

# tag docker image and push to your container repository in docker hub
docker tag eks-demo:app docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app
docker push docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app
```

3. Or, run in local kubernetes cluster with local redis running on host:
```sh
# change directory to .deploy/helm
cd .deploy/helm

# check the values file for the helm chart
cat eks-demo-app/values.yaml
# modify the value for 'image.repository' assuming image tag to be 'app'
docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo
# additionally, you may need to modify the values 'env' and 'secretEnv'

# install/upgrade helm chart
helm upgrade -i eks-demo-app eks-demo-app \
	-n eks-demo --create-namespace

# list helm charts
helm list -A

# port forward to kubernetes demo app service
kubectl --namespace eks-demo port-forward svc/eks-demo-app 8080:8080

# curl to hit demo api
curl http://localhost:8080
>>> Welcome to demo api!

curl http://localhost:8080/rds
>>> [{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
>>> This is a demo text file from s3!

curl http://localhost:8080/redis
>>> This is a demo text from redis!

# if you want to stop and remove helm chart and namespace
helm uninstall eks-demo-app -n eks-demo
kubectl delete namespace eks-demo
```

4. Or, run in local kubernetes cluster with local redis running inside kubernetes
```sh
# port forward to kubernetes redis service
kubectl --namespace eks-demo port-forward svc/eks-demo-app-redis 63790:6379

# connect to kubernetes redis service
redis-cli -p 63790

# set value for key - 'demo'
set demo "This is a demo text from k8s redis!"
```
Edit the 'values.yaml' file in .deploy/helm/eks-demo-app/values.yaml
to uncomment the following section under 'env:'
```yaml
  - name: REDIS_HOST
    value: "eks-demo-app-redis"
```
```sh
# install/upgrade helm chart
helm upgrade -i eks-demo-app eks-demo-app \
	-n eks-demo --create-namespace

# port forward to kubernetes demo app service
kubectl --namespace eks-demo port-forward svc/eks-demo-app 8080:8080

curl http://localhost:8080/redis
>>> This is a demo text from k8s redis!
```

### Run tests
```sh
# run unit tests
pytest -v --cov=demo
```

### Usage
When running as an api, use the following endpoints:
1. 'http://`{domain name}:{port}`/' for welcome message.
```sh
# example
curl http://localhost:8080/
>>> Welcome to demo api!
```
2. 'http://`{domain name}:{port}`/rds' reading from rds database.
```sh
# example
curl http://localhost:8080/rds
>>> [{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]
```
3. 'http://`{domain name}:{port}`/s3' reading from s3.
```sh
# example
curl http://localhost:8080/s3
>>> This is a demo text file from s3!
```
4. 'http://`{domain name}:{port}`/redis' reading from redis.
```sh
# example
curl http://localhost:8080/redis
>>> This is a demo text from redis!
```


## Install on AWS

### Pre-requisites
- Install terraform: https://www.terraform.io/downloads

### Create 'values.tfvars' file
```sh
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

# - 'create_bastion' is true / false for creating the bastion hosts i.e. ec2 instances in private and public subnets
# - 'bastion_key_pair_name' is the name of key pair used by ec2 instance for ssh into bastion hosts for e.g. access_key. This has to be created beforehand by the user: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html

# - 'create_eks_cluster' is true / false for creating the eks cluster
# - 'eks_managed_instance_types' contains the instance types to choose from
# - 'eks_managed_capacity_type' is either 'SPOT' or 'ON_DEMAND' (default)

```

### Run terraform
```sh
# change directory to infra
cd infra

# initialise providers and modules
terraform init

# install infrastructure
terraform apply -var-file=values.tfvars

# if you want to delete all resources created by terraform
terraform destroy -var-file=values.tfvars
```

### Access RDS database instance from bastion hosts
If the user has not enabled 'enable_database_public_access' then, the rds database instance is only accessible to the bastion host running inside the private subnet. And the bastion host running inside private subnet is only accessible to the bastion host running inside the public subnet.

```sh
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
# or
sudo yum install mariadb105

# connect to rds and enter '<DATABASE MASTERDB PASSWORD>' for password prompt
mysql -u <DATABASE MASTERDB USERNAME> -h <RDS DATABASE ENDPOINT DNS> -P 3306 -p

# press ctrl+d multiple times to exit
```

### Setup demodb database with user on RDS
```sh
# connect to mysql instance and enter '<DATABASE MASTERDB PASSWORD>' for password prompt
# refer to terraform - values.tfvars for <DATABASE MASTERDB USERNAME>
mysql -u <DATABASE MASTERDB USERNAME> -h <RDS DATABASE ENDPOINT DNS> -P 3306 -p
# where <RDS DATABASE ENDPOINT DNS> can be found from AWS console

# run the following scripts by replacing:
# - 'user1' with <username>
# - 'password1' with <password>
create database if not exists demodb;

create user if not exists user1 identified by 'password1';

grant all on demodb.* to user1;

# press ctrl+d to exit
```

### Setup s3 bucket with access credentials
Create or reuse an S3 bucket with a user credential
that is assigned an IAM policy that allows read from the s3 bucket and its objects.  
Follow step 1 from
https://www.gormanalysis.com/blog/connecting-to-aws-s3-with-python/#1-set-up-credentials-to-connect-python-to-s3  
Finally, upload the file - 'demo/data/s3_demo.txt' to the s3 bucket

### Install on AWS EKS
```sh
# change directory to demo
cd demo

# build docker image
# --build-arg DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
# using 'host.docker.internal' as database server to reach out to local mysql running on host
# --build-arg DB_CONNECTION_URL = database connection url for use by sql alchemy and alembic
# --build-arg REDIS_HOST = redis server host
# --build-arg AWS_REGION = aws region code like 'ap-southeast-2'
# --build-arg AWS_S3_BUCKET = aws s3 bucket name
# --build-arg AWS_ACCESS_KEY_ID = aws user credential access key id (optional as it can be overriden via secret environment)
# --build-arg AWS_SECRET_ACCESS_KEY = aws user credential secret access key (optional as it can be overriden via secret environment)
docker build \
	--build-arg DB_CONNECTION_URL="mysql+mysqldb://user1:password1@host.docker.internal/demodb" \
	--build-arg AWS_REGION="<AWS REGION>" \
	--build-arg AWS_S3_BUCKET="<AWS S3 BUCKET>" \
	--build-arg AWS_ACCESS_KEY_ID="<AWS ACCESS KEY ID>" \
	--build-arg AWS_SECRET_ACCESS_KEY="<AWS SECRET ACCESS KEY>" \
	--build-arg REDIS_HOST="host.docker.internal" \
	-t eks-demo:app --platform linux/amd64 .

# tag docker image and push to your container repository in docker hub
docker tag eks-demo:app docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app
docker push docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app

# update kube config with eks cluster context
aws eks list-clusters --region <AWS REGION>
aws eks update-kubeconfig --name <EKS_CUSTER_NAME> --region <AWS REGION>
# where <EKS_CUSTER_NAME> is of the format <ENVIRONMENT>-eks01, refer to terraform - values.tfvars for <ENVIRONMENT> and <AWS REGION>
```

### Install AWS Secrets Manager and Config Provider for Secret Store CSI Driver
Reference:
- https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html
- https://github.com/aws/secrets-store-csi-driver-provider-aws
```sh
# create demo secret in aws secrets manager
aws --region <AWS REGION> secretsmanager create-secret --name demo-secret01 --secret-string '{"username":"user1", "password":"password1"}'
# refer to terraform - values.tfvars for <AWS REGION>

# install secrets store csi driver helm chart
helm install secrets-store-csi-driver secrets-store-csi-driver \
	--repo https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts \
	-n kube-system

# if you want to stop and remove helm chart
helm uninstall secrets-store-csi-driver -n kube-system
```

### Install demo app on eks
```sh
# change directory to .deploy/helm
cd .deploy/helm

# check the values file for the helm chart
cat eks-demo-app/values.yaml
# modify the value for 'image.repository' assuming image tag to be 'app':
# image:
#   repository: docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo

# next, modify the values in 'serviceAccount':
# serviceAccount:
#   create: true
#   annotations:
#     eks.amazonaws.com/role-arn: arn:aws:iam::<AWS ACCOUNT ID>:role/eksawssecretsmanagerrole
# -> where <AWS ACCOUNT ID> can be found from AWS console

# next, modify the values in 'env' and 'secretEnv' by uncommenting
# and populating the - 'value' fields, for example:
# secretEnv:
#   - name: name: DB_CONNECTION_URL
#     value: "mysql+mysqldb://<DATABASE MASTERDB USERNAME>:<DATABASE MASTERDB PASSWORD>@<RDS DATABASE ENDPOINT DNS>/demodb"
# refer to terraform - values.tfvars for <DATABASE MASTERDB USERNAME> and <DATABASE MASTERDB PASSWORD>
# -> where <RDS DATABASE ENDPOINT DNS> can be found from AWS console

# next, modify the values in 'awsCloudWatch':
# awsCloudWatch:
#   enabled: true
#   awsRegion: "<AWS REGION>"
#   eksClusterName: "<EKS CLUSTER NAME>"
# -> where <EKS CUSTER NAME> is of the format <ENVIRONMENT>-eks01, refer to terraform - values.tfvars for <ENVIRONMENT>, <AWS REGION>

# next, modify the values in 'awsSecretsManager':
# awsSecretsManager:
#   enabled: true
#   awsSecretName: "<AWS SECRET NAME>"
# -> where <AWS SECRET NAME> is "demo-secret01"

# next, modify the values in 'awsLoadBalancerController':
# awsLoadBalancerController:
#   enabled: true
#   serviceAccountAnnotations:
#     eks.amazonaws.com/role-arn: arn:aws:iam::<AWS ACCOUNT ID>:role/eks-load-balanacer-role
# -> where <AWS ACCOUNT ID> can be found from AWS console

# install/upgrade helm chart
helm upgrade -i eks-demo-app eks-demo-app \
	-n eks-demo --create-namespace

# list helm charts
helm list -A

# port forward to kubernetes demo app service
kubectl --namespace eks-demo port-forward svc/eks-demo-app 8080:8080

# curl to hit demo api
curl http://localhost:8080
>>> Welcome to demo api!

curl http://localhost:8080/rds
>>> [{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
>>> This is a demo text file from s3!

# port forward to eks redis service
kubectl --namespace eks-demo port-forward svc/eks-demo-app-redis 63790:6379

# connect to kubernetes redis service
redis-cli -p 63790

# set value for key - 'demo'
set demo "This is a demo text from eks redis!"

# press ctrl+d to exit

# port forward to kubernetes demo app service
kubectl --namespace eks-demo port-forward svc/eks-demo-app 8080:8080

curl http://localhost:8080/redis
>>> This is a demo text from eks redis!

# check the aws secrets manager secret mount in the pod
kubectl --namespace eks-demo get pods

# replace eks-demo-app-5db9bbf7b9-p8jt4 by the pod name in the result above
kubectl --namespace eks-demo exec -it eks-demo-app-5db9bbf7b9-p8jt4 -- bash

# check the mount directory for the secret coming from aws secrets manager
cd /mnt/secrets-store

# list directory
ls -la

# extract secret
cat demo-secret01
>>> {"username":"user1", "password":"password1"}

# press ctrl+d to exit
```

### Monitor on AWS CloudWatch
Navigate to 'CloudWatch on AWS console:
Check application logs under 'Log groups' - /aws/containerinsights/<EKS CLUSTER NAME>/application.

### Install cert-manager for generating free TLS certificates from letsencrypt.org
Reference: https://artifacthub.io/packages/helm/cert-manager/cert-manager
```sh
# install cert-manager crds
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.2/cert-manager.crds.yaml

# install cert-manager helm chart
helm install cert-manager cert-manager \
	--repo https://charts.jetstack.io \
	-n cert-manager --create-namespace \
	--version v1.8.2

# if you want to stop and remove helm chart and namespace
helm uninstall cert-manager -n cert-manager
kubectl delete namespace cert-manager
```

### Install AWS Load Balancer Controller after cert-manager is installed
Reference:
- https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
- https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/how-it-works/
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/
```sh
# install aws load balancer controller crds
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"

# install aws load balancer controller helm chart
helm upgrade -i aws-load-balancer-controller aws-load-balancer-controller \
	--repo https://aws.github.io/eks-charts \
	-n kube-system --set clusterName=<EKS CLUSTER NAME> \
	--set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller \
	--set enableCertManager=true --set region=<AWS REGION> \
	--set vpcId=<VPC ID> --set enableWafv2=true
# where <EKS CUSTER NAME> is of the format <ENVIRONMENT>-eks01, refer to terraform - values.tfvars for <ENVIRONMENT>, <AWS REGION>
# where <VPC ID> can be found from AWS console
# check more options like '--set enableWafv2' in https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller

# if you want to stop and remove helm chart
helm uninstall aws-load-balancer-controller -n kube-system
```

### Upgrade demo app to use ingress via AWS Load Balancer
```sh
# change directory to .deploy/helm
cd .deploy/helm

# check the values file for the helm chart
cat eks-demo-app/values.yaml
# modify the value for 'ingress':
# ingress:
#   enabled: true
# ...
#   hosts:
#     - host: <HOST>
#   tlsEnabled: false
# ...
# -> update the <HOST> to any domain that you own

# install/upgrade helm chart
helm upgrade -i eks-demo-app eks-demo-app \
	-n eks-demo --create-namespace
# where <EKS CUSTER NAME> is of the format <ENVIRONMENT>-eks01, refer to terraform - values.tfvars for <ENVIRONMENT>, <AWS REGION>

# curl to hit the demo api via load balancer
curl -H "Host: <HOST>" http://<LOAD BALANCER PUBLIC DNS>/
# where <HOST> is the value configured above and find <LOAD BALANCER PUBLIC DNS> from aws console, if it was successfully created by automation
>>> Welcome to demo api!

# if you want to stop and remove helm chart and namespace
helm uninstall eks-demo-app -n eks-demo
kubectl delete namespace eks-demo
```

### Upgrade demo app to use free TLS certificate from letsencrypt.org
Setup AWS Route53 for your <HOST> with nameserver entries from your registrar pointing to AWS.
Next, create an 'A' record with alias pointing to the AWS Load Balancer created in the previous section:
![example aws route53 A record](./docs/images/aws-route53-a-record.png)

```sh
# test the host url after few minutes
curl http://<HOST>/
>>> Welcome to demo api!

# check the values file for the helm chart
cat eks-demo-app/values.yaml
# modify the value for 'ingress':
# ingress:
#   enabled: true
#   className: "alb"
#   annotations:
#     # comment this line for 'tlsEnabled: true':
#     # alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
#     ...
# ...
#   tlsEnabled: true
# ...

# modify the value for 'letsencrypt':
# letsencrypt:
#   enabled: true
#   className: "alb"
#   email: "<EMAIL ADDRESS>"
#   # letsencrypt staging:
#   server: https://acme-staging-v02.api.letsencrypt.org/directory
#   # letsencrypt production:
#   # server: https://acme-v02.api.letsencrypt.org/directory
# ...
# -> uncomment the line for 'server' following 'letsencrypt staging'
# later, you can uncomment the line for 'server' following 'letsencrypt production' instead

# manually import the certificate to aws certificates manager
kubectl get secret -n eks-demo eks-demo-app-tls -o yaml | yq '.data."tls.crt"' | base64 -d | sed -e '/-----END CERTIFICATE-----/q' > certificate.pem

kubectl get secret -n eks-demo eks-demo-app-tls -o yaml | yq '.data."tls.crt"' | base64 -d > certificate-chain.pem

kubectl get secret -n eks-demo eks-demo-app-tls -o yaml | yq '.data."tls.key"' | base64 -d > private-key.pem

aws acm import-certificate \
	--certificate fileb://certificate.pem \
	--certificate-chain fileb://certificate-chain.pem \
	--private-key fileb://private-key.pem

# test the host url on 'http' after few minutes
curl http://<HOST>/
>>> <html>
>>> <head><title>301 Moved Permanently</title></head>
>>> <body>
>>> <center><h1>301 Moved Permanently</h1></center>
>>> </body>
>>> </html>

# test the host url on 'https' after few minutes
curl -k https://<HOST>/
# or
curl https://<HOST>/
>>> Welcome to demo api!
```

Refer to the following issues for future improvements in automatic import of tls certificate secret to AWS Certificates Manager:
- https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1084
- https://github.com/cert-manager/cert-manager/issues/3711


## Authors

👤 **Ankur Soni**

[![Github](https://img.shields.io/github/followers/ankursoni?style=social)](https://github.com/ankursoni)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ankursoniji)

[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/fold_left.svg?style=social&label=Follow%20%40ankursoniji)](https://twitter.com/ankursoniji)


## 📝 License

This project is [MIT](./LICENSE) licensed.

