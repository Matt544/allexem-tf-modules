#!/bin/bash
set -euo pipefail
apt update -y
apt install -y curl unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version

cd /home/ubuntu

aws s3api get-object --bucket allexem-tf-scripts \
--key scripts/${staging_or_prod}/main-app/get_secrets.sh get_secrets.sh

# Run script to save secrets to ./secrets
chmod +x get_secrets.sh
# ./get_secrets.sh
staging_or_prod="${staging_or_prod}" ./get_secrets.sh

aws s3api get-object --bucket allexem-tf-scripts \
--key scripts/${staging_or_prod}/main-app/dependencies.sh dependencies.sh

# Install the dependencies
chmod +x dependencies.sh
./dependencies.sh

# create the api-network, assigning an interface and network name
export API_NET_INTERFACE_NAME=api-network-if
export API_NET_NAME=api-network
docker network create -d bridge -o com.docker.network.bridge.name=$API_NET_INTERFACE_NAME $API_NET_NAME

# Get and run the iptables script
aws s3api get-object --bucket allexem-tf-scripts \
--key scripts/iptables.sh iptables.sh

chmod +x iptables.sh
rds_elastic_net_ip="${rds_elastic_net_ip}" subnets="${aws_subnets}" vpc_cidr_block="${vpc_cidr_block}" ./iptables.sh

# NOTE: `compose ... up` and `rm -R ./secrets` should be commented in/out together
docker compose -f compose.base.yaml -f compose.${staging_or_prod}.yaml up -d

# remove the secrets dir. 
rm -R ./secrets
rm get_secrets.sh

# sleep 15
