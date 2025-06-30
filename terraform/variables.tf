variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "jenkins-deploy-key"
}

variable "private_key_path" {
  default = "~/.ssh/id_rsa"
}
