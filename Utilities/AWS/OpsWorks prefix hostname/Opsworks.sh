#!/bin/bash

# Log levels
readonly LOG_LEVEL_ERROR="ERROR"
readonly LOG_LEVEL_INFO="INFO"
readonly LOG_LEVEL_DEBUG="DEBUG"

function validate {
  if [ -z $OPSWORKS_STACK_ID ] || [ -z $OPSWORKS_LAYER_ID ] || [ -z $OPSWORKS_STACK_TYPE ] || [ -z $HOSTNAME_PREFIX ]; then
    log_error "OPSWORKS_STACK_TYPE, OPSWORKS_STACK_ID and OPSWORKS_LAYER_ID, HOSTNAME_PREFIX are required"
    exit 1
  fi
}

function disable_requiretty {
  log_info "Disabling requiretty"
  echo 'Defaults:root !requiretty' > /etc/sudoers.d/999-cloud-init-requiretty
  chmod 440 /etc/sudoers.d/999-cloud-init-requiretty
}

function install_deps {
 log_info "Installing dependencies"
 # Install deps.
 packages=$1
 for package in $packages; do
   installed=$(which $package)
   not_found=$(echo `expr index "$installed" "no $package in"`)
   if [ -z $installed ] && [ "$not_found" == "0" ]; then
     log_info "Installing $package"
     if [ -f /etc/redhat-release ] || [ -f /etc/system-release ]; then
       yum install -y $package
     elif [ -f /etc/arch-release ]; then
       pacman install -y $package
     elif [ -f /etc/gentoo-release ]; then
       emerge install -y $package
     elif [ -f /etc/SuSE-release ]; then
       zypp install -y $package
     elif [ -f /etc/debian_version ]; then
       apt-get update
       apt-get install -y $package
     fi
     log_info "$package successfully installed"
   fi
 done
}

function install_awscli {
  # Install the Python Package Index (pip).
  installed=$(which pip)
  if [ -z $installed ]; then
    curl -O https://bootstrap.pypa.io/get-pip.py
    
    isPython2Installed=$(which python)
    if [ $isPython2Installed ]; then
      python get-pip.py
    else
      python3 get-pip.py
    fi
    log_info "pip successfully installed"
  fi
  # Install the AWS CLI.
  installed=$(which aws)
  if [ -z $installed ]; then
    pip install awscli --ignore-installed
  fi
}

function install_opsworks {

  if [ $OPSWORKS_STACK_TYPE == "CLASSIC" ]; then
    readonly OPSWORKS_ENDPOINT="us-east-1"
  else
    readonly OPSWORKS_ENDPOINT=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}'`
  fi

  new_hostname=`curl -s http://169.254.169.254/latest/meta-data/local-hostname | sed "s/.us-west-2.compute.internal//g"`

  log_info "Trying to register the instance to AWS OpsWorks stack: $OPSWORKS_STACK_ID"
  aws opsworks register --infrastructure-class ec2 --use-instance-profile --region $OPSWORKS_ENDPOINT --stack-id $OPSWORKS_STACK_ID --local --override-hostname $HOSTNAME_PREFIX-$new_hostname 
  
  log_info "Instance successfully registered"
  log_info "Going to sleep for 150 seconds" && sleep 150
  log_info "Trying to assign the instance to AWS OpsWorks layer: $OPSWORKS_LAYER_ID"
  instanceOpsworksId=`aws opsworks --region $OPSWORKS_ENDPOINT describe-instances --stack-id $OPSWORKS_STACK_ID --output json | jq --arg hostname \`hostname\` '.Instances[] | select(.Hostname == $hostname)| .InstanceId' | awk -F '\"' {'print $2'}`

  aws opsworks assign-instance --region $OPSWORKS_ENDPOINT --layer-ids $OPSWORKS_LAYER_ID --instance-id $instanceOpsworksId
  log_info "Instance successfully assigned"
}

function cleanup {
  log_info "Cleaning up"
  rm -rf /etc/sudoers.d/999-cloud-init-requiretty
}

function format_timestamp {
  date +"%Y-%m-%d %H:%M:%S"
}

function log_error {
  log "$(format_timestamp)" "$LOG_LEVEL_ERROR" "$@"
}

function log_info {
  log "$(format_timestamp)" "$LOG_LEVEL_INFO" "$@"
}

function log_debug {
  log "$(format_timestamp)" "$LOG_LEVEL_DEBUG" "$@"
}

function log {
  local readonly timestamp="$1"
  shift
  local readonly log_level="$1"
  shift
  local readonly message="$@"
  echo -e "${timestamp} [${log_level}] ${message}"
}

validate
log_info "Registering the instance to AWS OpsWorks"
disable_requiretty
install_deps "curl python jq"
install_awscli
install_opsworks
cleanup
log_info "Instance successfully registered and assigned to AWS OpsWorks; DONE"