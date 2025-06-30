#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io awscli
sudo usermod -aG docker ubuntu
