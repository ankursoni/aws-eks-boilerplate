# aws-eks-boilerplate

[![Build](https://github.com/ankursoni/aws-eks-boilerplate/actions/workflows/build.yml/badge.svg)](https://github.com/ankursoni/aws-eks-boilerplate/actions/workflows/build.yml)
[![codecov](https://codecov.io/gh/ankursoni/aws-eks-boilerplate/branch/main/graph/badge.svg?token=ZZWMD4FB93)](https://codecov.io/gh/ankursoni/aws-eks-boilerplate)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![License](https://img.shields.io/github/license/ankursoni/aws-eks-boilerplate)](/LICENSE)


> AWS EKS Boilerplate


## Install infrastructure on aws

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

# - bastion_key_pair_name is the name of key pair used by ec2 instance for ssh into bastion hosts for e.g. access_key. This has to be created beforehand by the user: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html
```

### Run terraform
```sh
cd infra

terraform init

terraform apply -var-file=values.tfvars

# delete all resources created by terraform
terraform destroy
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

# connect to rds and enter '<DATABASE_MASTERDB_PASSWORD>' for password prompt
mysql -u <DATABASE_MASTERDB_USERNAME> -h <RDS DATABASE ENDPOINT DNS> -P 3306 -p

# press ctrl+d multiple times to exit
```


## Install demo app

### Pre-requisites
- Install python 3.9.13: https://www.python.org/downloads/release/python-3913/
- Install mysql: https://dev.mysql.com/downloads/mysql/
- Install redis: https://developer.redis.com/create/windows
- Install docker desktop: https://docs.docker.com/get-docker/
- Install local kubernetes by docker desktop: https://docs.docker.com/desktop/kubernetes/
- Install helm: https://helm.sh/docs/intro/install/

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
# assuming you have a mysql instance running locally or on aws rds
# run the following scripts by replacing:
# - 'user1' with <username>
# - 'password1' with <password>
# - 'localhost' with <database server>
create database if not exists demodb

create user if not exists user1@localhost identified by 'password1';

grant all on demodb.* to user1@localhost
```

### Setup redis with key/value pair
```sh
# assuming you have a redis server running locally
redis-cli

# set value for key - 'demo'
set demo "This is a demo text from redis!"
```

### Setup s3 bucket with access credentials
Create or reuse an S3 bucket with a user credential
that is assigned an IAM policy that allows read from the s3 bucket and its objects.  
Follow step 1 from
https://www.gormanalysis.com/blog/connecting-to-aws-s3-with-python/#1-set-up-credentials-to-connect-python-to-s3  
Finally, upload the file - 'demo/data/s3_demo.txt' to the s3 bucket

### Install
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
Welcome to demo api!

curl http://localhost:8080/rds
[{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
This is a demo text file from s3!

curl http://localhost:8080/redis
This is a demo text from redis!
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
	-t eks-demo:app .

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
Welcome to demo api!

curl http://localhost:8080/rds
[{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
This is a demo text file from s3!

curl http://localhost:8080/redis
This is a demo text from redis!

# stop and remove docker container
docker stop eks-demo-app
docker rm eks-demo-app

# tag docker image and push to your container repository in docker hub
docker tag eks-demo:app docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app
docker push docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo:app
```

3. Or, run in local kubernetes cluster with local redis running on host:
```sh
# upgrade or install helm chart, if not preset
cd .deploy/helm

# check the values file for the helm chart
cat eks-demo-app/values.yaml
# modify the value for 'image.repository' assuming image tag to be 'app'
docker.io/<YOUR DOCKER REPOSITORY/USERNAME>/eks-demo
# additionally, you may need to modify the values 'env'

# install/upgrade helm chart
helm upgrade -i eks-demo-app eks-demo-app \
	-n eks-demo --create-namespace

# list helm charts
helm list -A

# port forward to kubernetes demo app service
kubectl --namespace eks-demo port-forward svc/eks-demo-app 8080:8080

# curl to hit demo api
curl http://localhost:8080
Welcome to demo api!

curl http://localhost:8080/rds
[{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]

curl http://localhost:8080/s3
This is a demo text file from s3!

curl http://localhost:8080/redis
This is a demo text from redis!

# stop and remove helm chart and namespace
helm uninstall eks-demo-app -n eks-demo
kubectl delete namespace eks-demo
```

1. Or, run in local kubernetes cluster with local redis running inside kubernetes
```sh
# port forward to kubernetes redis service
kubectl --namespace eks-demo port-forward svc/eks-demo-app-redis 63790:6379

# connect to kubernetes redis service
redis-cli -p 63790

# set value for key - 'demo'
set demo "This is a demo text from k8s redis!"
```
Edit the 'values.yaml' file in ./deploy/helm/eks-demo-app/values.yaml
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
This is a demo text from k8s redis!
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
Welcome to demo api!
```
2. 'http://`{domain name}:{port}`/rds' reading from rds database.
```sh
# example
curl http://localhost:8080/rds
[{"id": 1, "description": "demo1"}, {"id": 2, "description": "demo2"}]
```
3. 'http://`{domain name}:{port}`/s3' reading from s3.
```sh
# example
curl http://localhost:8080/s3
This is a demo text file from s3!
```
4. 'http://`{domain name}:{port}`/redis' reading from redis.
```sh
# example
curl http://localhost:8080/redis
This is a demo text from redis!
```


## Authors

👤 **Ankur Soni**

[![Github](https://img.shields.io/github/followers/ankursoni?style=social)](https://github.com/ankursoni)

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/ankursoniji)

[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/fold_left.svg?style=social&label=Follow%20%40ankursoniji)](https://twitter.com/ankursoniji)


## 📝 License

This project is [MIT](./LICENSE) licensed.
