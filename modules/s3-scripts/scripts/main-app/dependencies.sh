#!/bin/bash
echo ">>>>>> entered dependencies.sh"

sudo apt-get update
apt-get install -y postgresql-client-17
# sudo apt install -y docker.io

# Install Docker following https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install gVisor (runsc)
sudo apt-get update && \
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg
sudo apt-get update && sudo apt-get install -y runsc
runsc --version

sudo tee cat > /etc/docker/daemon.json <<EOL
{
    "runtimes": {
        "runsc": {
          "path": "/usr/bin/runsc"
        }
    }
}
EOL

systemctl enable docker
systemctl start docker
# I'm not sure but a restart might be required (or useful?) for Docker to pick up the 
# config changes in daemon.json
systemctl restart docker

# Allow EC2 user to use Docker
sudo chown ubuntu /var/run/docker.sock
sudo usermod -aG docker ubuntu

aws ecr get-login-password --region ca-west-1 | docker login --username AWS \
  --password-stdin 273354654458.dkr.ecr.ca-west-1.amazonaws.com

echo "<<<<<< exiting dependencies.sh"
