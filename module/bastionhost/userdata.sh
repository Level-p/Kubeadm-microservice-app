#!/bin/bash

# Set hostname
hostnamectl set-hostname bastionhost

mkdir -p /home/ubuntu/.ssh
echo "${privatekey}" > /home/ubuntu/.ssh/id_rsa
chmod 400 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# Update packages
apt-get update -y

# Install SSM Agent
snap install amazon-ssm-agent --classic

# Enable and start SSM Agent
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
