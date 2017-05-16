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

# Get a list of subnets in your default VPC
function get_subnets () {
  aws ec2 describe-subnets
}

# Create the ELB
function create_elb () {
  aws elb create-load-balancer --load-balancer-name dockerzon-web \
    --listeners \
    "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80" \
    --subnets subnet-5e40c063 subnet-43bca768 subnet-ffc128a7 subnet-0d61b67b \
    --security-groups sg-5f63c627}

# Get the details of the ELB we just created
function describe_elb () {
  aws elb describe-load-balancers
}

# Configure the idle time­out period

function configure_idle_timeout () {
  aws elb modify-load-balancer-attributes --load-balancer-name dockerzon-web \
    --load-balancer-attributes "{\"ConnectionSettings\":{\"IdleTimeout\":5}}"
}

# Configure the health check
function configure_health_check () {
  aws elb configure-health-check --load-balancer-name dockerzon-web \
    --health-check \
    Target="HTTP:80/health_check,Timeout=5,Interval=30,UnhealthyThreshold=2,Healthy Threshold=10"
}

​# Delete the ELB
function delete_elb () {
  aws elb delete-load-balancer --load-balancer-name dockerzon-web
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
