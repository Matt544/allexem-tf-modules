#!/bin/bash

set -euo pipefail
apt update -y
apt install -y curl unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

cd /home/ubuntu

aws s3api get-object --bucket "allexem-${staging_or_prod}-tf-scripts" \
    --key scripts/main-app/get_secrets.sh get_secrets.sh

# Run script to save secrets to ./secrets
chmod +x get_secrets.sh
staging_or_prod="${staging_or_prod}" ./get_secrets.sh

aws s3api get-object --bucket "allexem-${staging_or_prod}-tf-scripts" \
    --key scripts/main-app/dependencies.sh dependencies.sh

# Install the dependencies
chmod +x dependencies.sh
ecr_url="${ecr_url}" ./dependencies.sh

# create the api-network, assigning an interface and network name
docker network create -d bridge -o \
    com.docker.network.bridge.name="${api_net_interface_name}" "${api_net_name}"

# Get and run the iptables script
aws s3api get-object --bucket "allexem-${staging_or_prod}-tf-scripts" \
    --key scripts/iptables.sh iptables.sh

chmod +x iptables.sh
rds_elastic_net_ip="${rds_elastic_net_ip}" \
    subnets="${aws_subnets}" \
    vpc_cidr_block="${vpc_cidr_block}" \
    api_net_interface_name="${api_net_interface_name}" \
    ./iptables.sh

# NOTE: `compose ... up` and `rm -R ./secrets` should be commented in/out together
docker compose --env-file .env.live.${staging_or_prod} -f compose.base.yaml -f compose.live.yaml up -d

# remove the secrets dir. 
rm -R ./secrets
rm get_secrets.sh

# sleep 15
