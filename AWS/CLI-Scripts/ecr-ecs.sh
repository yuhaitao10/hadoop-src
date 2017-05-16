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


# Authenticate your docker client to Amazon ECR
function authen_docker () {
  eval "$(aws ecr get-login)"
}

# Create a dockerzon repository to house the Rails application
# Create an nginx repository to house the custom version of nginx
function create_ecs_repository () {
  aws ecr create-repository --repository-name dockerzon/nginx
  aws ecr create-repository --repository-name dockerzon/dockerzon
}

# Describe all repositories
function describe_repository () {
  aws ecr describe-repositories
}

# Tag the Dockerzon & nginx image
function tag_docker_image () {
  docker tag dockerzon_dockerzon:latest \
  xxx.dkr.ecr.us-east-1.amazonaws.com/dockerzon/dockerzon:latest
  docker tag dockerzon_nginx:latest \
  xxx.dkr.ecr.us-east-1.amazonaws.com/dockerzon/nginx:latest
}


# Push the Dockerzon & nginx image to your repository
function push_image_to_registory () {
  docker push xxx.dkr.ecr.us-east-1.amazonaws.com/dockerzon/dockerzon
  docker push xxx.dkr.ecr.us-east-1.amazonaws.com/dockerzon/nginx
}


# Register the sidekiq task definition that you downloaded
# Make sure you're in the production/ folder when executing this command
aws ecs register-task-definition \
--cli-input-json file://worker-task-definition.json

# Register the web task definition that you downloaded
# Make sure you're in the production/ folder when executing this command
aws ecs register-task-definition \
--cli-input-json file://web-task-definition.json

# Register the db reset task definition that you downloaded
# Make sure you're in the production/ folder when executing this command
aws ecs register-task-definition \
--cli-input-json file://db-reset-task-definition.json
# Initialize the database with the reset task
aws ecs run-task --cluster production --task-definition db-reset --count 1

# Deregister the extremely dangerous reset task
aws ecs deregister-task-definition --task-definition db-reset:1

# Confirm that running the reset task is impossible
aws ecs run-task --cluster production --task-definition db-reset --count 1

# Register the db migrate task definition that you downloaded
# Make sure you're in the production/ folder when executing this command
aws ecs register-task-definition \
--cli-input-json file://db-migrate-task-definition.json

# Run a database migration with the migrate task
aws ecs run-task --cluster production --task-definition db-migrate --count 1

# List all task definitions
aws ecs list-task-definitions

# Create the web service
# Make sure you're in the production/ folder when executing this command
  aws ecs create-service --cli-input-json file://web-service.json

#Describe the web service
  aws ecs describe-services --cluster production --services web

# Create the worker service
# Make sure you're in the production/ folder when executing this command
  aws ecs create-service --cli-input-json file://worker-service.json

# Describe the worker service
  aws ecs describe-services --cluster production --services worker













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
