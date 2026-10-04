#!/bin/bash
# ===============================
# Ansible Server Setup Script
# ===============================

# Update system
apt-get update -y
apt-get upgrade -y
echo "${privatekey}" > /home/ubuntu/.ssh/id_rsa
chmod 400 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
# Set hostname
hostnamectl set-hostname ansible
sudo bash -c 'echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config'

# install aws cli
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Install required packages
apt-get install -y software-properties-common git python3-pip sshpass

# Install latest Ansible
add-apt-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Create playbooks folder
mkdir -p /etc/ansible/playbooks
chown ubuntu:ubuntu /etc/ansible/playbooks

# Pull playbooks from S3 bucket
aws s3 cp s3://"${bucket_name}"/playbooks /etc/ansible/playbooks --recursive

# Test Ansible installation
ansible --version

# Update Ansible inventory file
echo "[main-master]" > /etc/ansible/hosts
echo "${master1_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "[member-master]" >> /etc/ansible/hosts
echo "${master2_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "${master3_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "[worker-nodes]" >> /etc/ansible/hosts
echo "${worker1_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "${worker2_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "${worker3_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "[haproxy-1]" >> /etc/ansible/hosts
echo "${haproxy1_ip} ansible_user=ubuntu" >> /etc/ansible/hosts
echo "[haproxy-2]" >> /etc/ansible/hosts
echo "${haproxy2_ip} ansible_user=ubuntu" >> /etc/ansible/hosts

# Create Variable file for Ansible
echo haproxy_1: "${haproxy1_ip}" > /etc/ansible/haproxy.yml
echo haproxy_2: "${haproxy2_ip}" >> /etc/ansible/haproxy.yml

# Executing playbooks as Ubuntu user
chown -R ubuntu:ubuntu /etc/ansible
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/kubernetes_dependence.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/keepalived.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/init_control_plane.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/member_control_plane.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/join_worker_node.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/kubectl.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/stage.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/prod.yml"
su - ubuntu -c "ansible-playbook /etc/ansible/playbooks/monitoring_stack.yml"