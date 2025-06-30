provider "aws" {
  region = var.region
}

// jenkins
resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "jenkins_secrets_policy" {
  name = "jenkins-secrets-access"
  role = aws_iam_role.jenkins_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "secretsmanager:GetSecretValue",
		  "secretsmanager:DescribeSecret",
		  "secretsmanager:ListSecrets",
          "ecr:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_instance" "jenkins" {
  ami                    = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS (adjust if needed)
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.jenkins_key.key_name
  security_groups        = [aws_security_group.jenkins_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name
  user_data              = file("${path.module}/userdata/jenkins.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}



// deployment server 

resource "aws_security_group" "deploy_sg" {
  name_prefix = "deploy-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "deploy_role" {
  name = "deploy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_ecr_policy" {
  role       = aws_iam_role.deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "deploy_profile" {
  name = "deploy-profile"
  role = aws_iam_role.deploy_role.name
}

resource "aws_instance" "deployment" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t3.medium"
  key_name               = aws_key_pair.jenkins_key.key_name
  security_groups        = [aws_security_group.deploy_sg.name]
  iam_instance_profile   = aws_iam_instance_profile.deploy_profile.name
  user_data              = file("${path.module}/userdata/deploy.sh")

  tags = {
    Name = "App-Host"
  }
}


// get jenkins password 

resource "null_resource" "get_jenkins_password" {
  depends_on = [aws_instance.jenkins]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    host        = aws_instance.jenkins.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      # Wait for Jenkins to be up
      "while ! sudo test -f /var/lib/jenkins/secrets/initialAdminPassword; do echo 'Waiting for Jenkins...'; sleep 5; done",
      "echo 'Jenkins is ready. Fetching initial admin password...'",
      "sudo cp /var/lib/jenkins/secrets/initialAdminPassword /tmp/initialAdminPassword",
      "sudo chown ubuntu:ubuntu /tmp/initialAdminPassword"
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -i ${var.private_key_path} ubuntu@${aws_instance.jenkins.public_ip}:/tmp/initialAdminPassword ./jenkins_admin_password.txt"
  }
}

