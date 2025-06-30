output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "deployment_ip" {
  value = aws_instance.deployment.public_ip
}
