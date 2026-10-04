#!/bin/bash

# Set hostname
hostnamectl set-hostname bastionhost

# Update packages
apt-get update -y

# Install SSM Agent
snap install amazon-ssm-agent --classic

# Enable and start SSM Agent
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
