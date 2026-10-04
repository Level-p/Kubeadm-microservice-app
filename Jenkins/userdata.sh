#!/bin/bash

# Stop script if a command fails
set -e

# Update system packages
apt-get update -y
apt-get upgrade -y

# Install basic dependencies
apt-get install -y \
  fontconfig \
  openjdk-21-jre \
  git \
  maven\
  curl \
  wget \
  unzip \
  gnupg \
  python3 python3-pip\
  software-properties-common
  

# -------------------------
# Install Jenkins
# -------------------------

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# -------------------------
# Install Docker
# -------------------------

apt-get install -y docker.io

systemctl enable docker
systemctl start docker

# Allow Jenkins to run Docker commands
usermod -aG docker jenkins

# -------------------------
# Install Terraform
# -------------------------

wget -O- https://apt.releases.hashicorp.com/gpg \
  | gpg --dearmor \
  | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install -y terraform

# -------------------------
# Install AWS CLI
# -------------------------

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o "/tmp/awscliv2.zip"

unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# -------------------------
# Install Ansible
# -------------------------

apt-get install -y ansible

# -------------------------
# Install kubectl
# -------------------------

curl -LO "https://dl.k8s.io/release/$(curl -L -s \
  https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# -------------------------
# Prepare Jenkins
# -------------------------

# Wait for Jenkins to become available
until curl -s http://localhost:8080/login > /dev/null; do
  sleep 10
done

# Display the initial Jenkins admin password in the user-data log
echo "Jenkins initial admin password:"
cat /var/lib/jenkins/secrets/initialAdminPassword

# Restart Jenkins after configuration
systemctl restart jenkins

echo "Jenkins server bootstrap completed successfully."