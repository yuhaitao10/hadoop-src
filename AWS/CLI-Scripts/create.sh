#!/usr/bin/env bash

# //////////////////////////////////////////////////////////////////////////////
# This script's purpose is to let you automatically deploy the Ruby on Rails
# demo application provided in this course.
#
# It is meant to be pretty general purpose, but you will likely want to make a
# few edits to customize it for your application or framework's needs.
#
# It is expected that you will at least configure your application by configuring
# the variables below this comment block.
#
# You may also want to adjust a few of the functions to customize them for your
# application. I needed to make a judgment call to balance out making the script
# somewhat general purpose and easy to understand without being a bash wizard.
# //////////////////////////////////////////////////////////////////////////////

# Exit the script as soon as something fails.
set -e

# What is the application's path?
APPLICATION_PATH="$HOME/Dev/scaling-docker-on-aws/dockerzon"

# How is the application defined in your docker-compose.yml file?
APPLICATION_NAME="dockerzon"

# What is the Docker image's name?
IMAGE="dockerzon_dockerzon"

# What is your Docker registry's URL?
REGISTRY="xxx.dkr.ecr.us-east-1.amazonaws.com"

# What is the repository's name?
REPO="dockerzon/dockerzon"

# Which build are you pushing?
BUILD="latest"

# Which cluster are you acting on?
CLUSTER="production"

# //////////////////////////////////////////////////////////////////////////////
# Optional steps that you may want to implement on your own!
# ------------------------------------------------------------------------------
# Run the application's test suite to ensure you always push working builds.
# Push your code to a remote source control management service such as GitHub.
# //////////////////////////////////////////////////////////////////////////////
function install_docker () {
  sudo apt get update
  sudo apt-get install libapparmor1 aufs-tools
}

#///////////////////////////////////////////////////////////////////////////////
# Download and install the latest Docker 1.10 release for your distro
# https://apt.dockerproject.org/repo/pool/main/d/dockerengine/
# Download the latest Docker Compose 1.6 release
# https://github.com/docker/compose/releases
# Verify you can run docker and docker­compose
# docker --version
# docker-compose --version
#///////////////////////////////////////////////////////////////////////////////
function install_docker_compose () {  
  sudo mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
  sudo chown $(whoami):$(whoami) /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  sudo usermod -aG docker $(whoami)
}


#///////////////////////////////////////////////////////////////////////////
# Already have the AWS CLI? Verify it is up to date
# aws acm help
#
# Verify the AWS CLI was installed successfully
# aws --version
# Configure the AWS CLI
#
# aws configure
# > Copy/paste your AWS Access Key ID
# > Copy/paste your AWS Secret Access Key
# > Enter in the us-east-1 region (even if you live somewhere else)
# > Leave the output format blank, it will use JSON by default
# Verify the configuration by listing IAM Users
#
# aws iam list-users
#///////////////////////////////////////////////////////////////////////////
function install_aws_cli () {
  # Install curl and unzip with your package manager if you need them
  sudo apt-get install curl

  # Download the bundle installer
  curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" \

  -o "awscli-bundle.zip"
  # Unzip the bundle
  unzip awscli-bundle.zip

  # Install the AWS CLI on your system path
  sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

  # Clean up the installation files
  rm -rf awscli-bundle.zip awscli-bundle
}

#//////////////////////////////////////////////////////////////////////////
# Verify the keypair has been created
# aws ec2 describe-key-pairs --key-name aws-nick
# (Optionally)​Delete the keypair
# aws ec2 delete-key-pair --key-name aws-nick
#//////////////////////////////////////////////////////////////////////////
function create_a_keypair () {
  aws ec2 create-key-pair --key-name aws-nick --query 'KeyMaterial' \
    --output text > ~/.ssh/aws-nick.pem 
  chmod 400 ~/.ssh/aws-nick.pem
}

#/////////////////////////////////////////////////////////////////////////
#
# Verify the Security Group has been created
# aws ec2 describe-security-groups --group-id sg-5f63c627
#
# (Optionally)​Delete the Security Group
# aws ec2 delete-security-group --group-id sg-5f63c627
#
#/////////////////////////////////////////////////////////////////////////
function create_a_security_group () {
  
  aws ec2 create-security-group --group-name nick_SG_useast1 \
    --description "Security group for nick on us-east-1"

}

#/////////////////////////////////////////////////////////////////////////
function autorizes_ingress_rules_to_sg () {
  # Authorize SSH and HTTP access for everyone
  aws ec2 authorize-security-group-ingress --group-id sg-5f63c627 \
      --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --group-id sg-5f63c627 \
      --protocol tcp --port 80 --cidr 0.0.0.0/0

  #Authorize future EC2 instances to connect to RDS and ElastiCache
  aws ec2 authorize-security-group-ingress --group-id sg-5f63c627 \
     --protocol tcp --port 5432 --source-group sg-5f63c627
  aws ec2 authorize-security-group-ingress --group-id sg-5f63c627 \
     --protocol tcp --port 6379 --source-group sg-5f63c627
}

#/////////////////////////////////////////////////////////////////////////
#
# List all clusters
# aws ecs list-clusters
#
# A deeper look into the cluster's state
# aws ecs describe-clusters --clusters deepdive
#
# (Optionally)​Delete the cluster
# aws ecs delete-cluster --cluster deepdive
#
#/////////////////////////////////////////////////////////////////////////
function create_a_cluster () {
  #Create a cluster
  aws ecs create-cluster --cluster-name deepdive
}

#////////////////////////////////////////////////////////////////////////
# Verify the ECS config is in the S3 bucket
# aws s3 ls s3://nickjj_deepdive
#////////////////////////////////////////////////////////////////////////
function create_a_bucket () {
  aws s3api create-bucket --bucket nickjj_deepdive
}

function copy_to_a_bucket () {
  aws s3 cp ecs.config s3://nickjj_deepdive/ecs.config
}


#////////////////////////////////////////////////////////////////////////
#
# Get EC2 instance status
# aws ec2 describe-instance-status --instance-id i-02914f86
#
# Verify the EC2 instance is now part of the deepdive cluster
# aws ecs list-container-instances --cluster deepdive
#
# Get detailed stats about a specific container instance
# aws ecs describe-container-instances --cluster deepdive \
#     --container-instances xxx
# Replace the xxx with your containerArn
#
# Review the state of the deepdive cluster
# aws ecs describe-clusters --cluster deepdive
#
# ​Delete the EC2 instance
# aws ec2 terminate-instances --instance-ids i-02914f86
#
#////////////////////////////////////////////////////////////////////////
function create_a_ec2_instance () {
  # Make sure you're in the deepdive/ folder when executing this command
  aws ec2 run-instances --image-id ami-2b3b6041 --count 1 \
    --instance-type t2.micro --iam-instance-profile Name=ecsInstanceRole \
    --key-name aws-nick --security-group-ids sg-5f63c627 \
    --user-data file://copy-ecs-config-to-s3
}

#////////////////////////////////////////////////////////////////////////
# List all task definition families
# aws ecs list-task-definition-families
#
# List all task definitions
# aws ecs list-task-definitions
#
# List the web task definition's first revision
# aws ecs describe-task-definition --task-definition web:1
#
# Explore the AWS CLI's help menu
# aws ecs register-task-definition help
#
# Generate a skeleton task definition to the terminal
# aws ecs register-task-definition --generate-cli-skeleton#////////////////////////////////////////////////////////////////////////
function register_a_task_definition () {
# Make sure you're in the deepdive/ folder when executing this command
  aws ecs register-task-definition \
    --cli-input-json file://web-task-definition.json
}

#////////////////////////////////////////////////////////////////////////
#
# List all services
# aws ecs list-services --cluster deepdive
#
# Take a closer look at the service we created
# aws ecs describe-services --cluster deepdive --services web
# Make note of the runnningCount field in the JSON output
# Visit the public DNS address in a browser
#
# Describe your instances to find the public DNS
# aws ec2 describe-instances
#
# Run a second service by updating it
# aws ecs update-service --cluster deepdive --service web \
#   --task-definition web --desired-count 2##///////////////////////////////////////////////////////////////////////
function create_a_service () {
  # This also runs a service
  aws ecs create-service --cluster deepdive --service-name web \
    --task-definition web --desired-count 1
}
#///////////////////////////////////////////////////////////////////////
#
# List all services again to make sure it's gone
# aws ecs list-services --cluster deepdive
#
# Generate a skeleton service
# aws ecs create-service --generate-cli-skeleton
#
#///////////////////////////////////////////////////////////////////////

function delete_a_service () {
  # You must update it to have a desired count of 0 before deleting a se rvice
  aws ecs update-service --cluster deepdive --service web \
    --task-definition web --desired-count 0
  aws ecs delete-service --cluster deepdive --service web
}

#////////////////////////////////////////////////////////////////////////
#
# List all tasks
# aws ecs list-tasks --cluster deepdive
#
#////////////////////////////////////////////////////////////////////////
function run_a_task () {
  aws ecs run-task --cluster deepdive --task-definition web --count 1
}


#///////////////////////////////////////////////////////////////////////////
#
# List all tasks to get the task Arn
# aws ecs list-tasks --cluster deepdive
#
#///////////////////////////////////////////////////////////////////////////
function stop_a_task () {
  aws ecs stop-task --cluster deepdive --task xxx(taskArn)
}

#///////////////////////////////////////////////////////////////////////////
# Get the containerArn so we can pass it into the start task command below
# aws ecs list-container-instances --cluster deepdive
#///////////////////////////////////////////////////////////////////////////

function start_a_task () {
  aws ecs start-task --cluster deepdive --task-definition web \
    --container-instances xxx(containerArn)
}
#///////////////////////////////////////////////////////////////////////////
#
# Tear down a cluster
#
#///////////////////////////////////////////////////////////////////////////

function tear_down_a_cluster () {
# Terminate the EC2 instance
  aws ec2 terminate-instances --instance-ids i-02914f86

# Delete the files in the S3 bucket
  aws s3 rm s3://nickjj_deepdive --recursive

# Delete the S3 bucket
  aws s3api delete-bucket --bucket nickjj_deepdive

# Delete the nginx repository and its images
  aws ecr delete-repository --repository-name deepdive/nginx --force

#Delete the cluster
  aws ecs delete-cluster --cluster deepdive
}



#///////////////////////////////////////////////////////////////////////////
#
# Authenticate your Docker client to Amazon ECR
# aws ecr get-login#
# Describe all repositories
# aws ecr describe-repositories
#
# List all images in the deepdive/nginx repository
# aws ecr list-images --repository-name deepdive/nginx
#
#//////////////////////////////////////////////////////////////////////////////
function push_to_registry () {
  # Move into the application's path and build the Docker image.
  cd "${APPLICATION_PATH}" && docker-compose build "${APPLICATION_NAME}" && cd -

  docker tag "${IMAGE}:${BUILD}" "${REGISTRY}/${REPO}:${BUILD}"

  # Automatically refresh the authentication token with ECR.
  eval "$(aws ecr get-login)"

  docker push "${REGISTRY}/${REPO}"
}

function update_web_service () {
  aws ecs register-task-definition \
    --cli-input-json file://web-task-definition.json
  aws ecs update-service --cluster "${CLUSTER}" --service web \
    --task-definition web --desired-count 2
}

function update_worker_service () {
  aws ecs register-task-definition \
    --cli-input-json file://worker-task-definition.json
  aws ecs update-service --cluster "${CLUSTER}" --service worker \
    --task-definition worker --desired-count 1
}

function run_database_migration () {
  aws ecs run-task --cluster "${CLUSTER}" --task-definition db-migrate --count 1
}

function all_but_migrate () {
  # Call the other functions directly, but skip migrating simply because you
  # should get used to running migrations as a separate task.
  push_to_registry
  update_web_service
  update_worker_service
}

function help_menu () {
cat << EOF
Usage: ${0} (-h | -p | -w | -r | -d | -a)

OPTIONS:
   -h|--help             Show this message
   -p|--push-to-registry Push the web application to your private registry
   -w|--update-web       Update the web application
   -r|--update-worker    Update the background worker
   -d|--run-db-migrate   Run a database migration
   -a|--all-but-migrate  Do everything except migrate the database

EXAMPLES:
   Push the web application to your private registry:
        $ ./deploy.sh -p

   Update the web application:
        $ ./deploy.sh -w

   Update the background worker:
        $ ./deploy.sh -r

   Run a database migration:
        $ ./deploy.sh -d

   Do everything except run a database migration:
        $ ./deploy.sh -a

EOF
}

# Deal with command line flags.
while [[ $# > 0 ]]
do
case "${1}" in
  -p|--push-to-registry)
  push_to_registry
  shift
  ;;
  -w|--update-web)
  update_web_service
  shift
  ;;
  -r|--update-worker)
  update_worker_service
  shift
  ;;
  -d|--run-db-migrate)
  run_database_migration
  shift
  ;;
  -a|--all-but-migrate)
  all_but_migrate
  shift
  ;;
  -h|--help)
  help_menu
  shift
  ;;
  *)
  echo "${1} is not a valid flag, try running: ${0} --help"
  ;;
esac
shift
done
