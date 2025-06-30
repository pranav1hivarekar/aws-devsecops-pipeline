#!/bin/bash
set -e

sudo apt update -y
sudo apt install -y openjdk-17-jdk docker.io unzip jq awscli git ansible

# Docker group
sudo usermod -aG docker ubuntu

# Add Jenkins key and repo
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# Add users to docker group
sudo usermod -aG docker jenkins


# Enable Jenkins to start at boot
sudo systemctl enable jenkins
#start jenkins
sudo systemctl restart jenkins
