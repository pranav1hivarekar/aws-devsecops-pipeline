# AWS DevSecOps CI/CD Pipeline Using Jenkins

This is an end-to-end DevSecOps CI/CD pipeline I built from scratch on AWS. My main goal was to fully automate the software delivery lifecycle – from code commit straight to deployment – while embedding essential security checks at every single stage.

Given my background as a security professional, I focused heavily on designing this pipeline with security baked in from day one. It's a practical demonstration of robust cloud architecture, continuous security integration, and efficient automation.

## The Architecture: 
I've structured this project around two core components: the AWS infrastructure I define with Terraform, and the CI/CD workflow orchestrated by Jenkins.

### AWS Infrastructure (Terraform)
1. Jenkins Server - EC2 instance with IAM role (`jenkins_role`) which grants only necessary permissions for pipeline operations like pulling secrets from AWS Secrets Manager and managing Docker images in AWS ECR.
2. Deployment Server - EC2 instance with IAM role (`deploy_role`) which grants only necessary permissions for pulling images from AWS ECR.


![AWS-architecture](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/aws-architecture.png)

### The Jenkins CI/CD Pipeline

| Stage | Tool | Description | 
| --- | --- | --- |
| SCA | safety | Catches known vulnerabilities in third-party libraries |
| Secrets Scanning | trufflehog | Searches the codebase for accidentally committed |
| SAST | bandit | Reviews source code for security vulnerabilities |
| IaC Scanning | checkov | Validates Terraform configurations against security best practices |
| Image Scanning | trivy | Scans the built Docker image for vulnerabilities |
| Hardening | ansible | Remotely hardens the deployment server |
| DAST | zap | Dynamic scan against running application |
<br /><br />
<img src="https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/jenkinslandscape.cicd.png" height="500">
<br />

## Security & DevOps Principles in Action
- **Principle of Least Privilege**: Used IAM Roles for both Jenkins and the deployment server granting minimal required permissions.
- **Centralized Secrets Management**: Jenkins is integrated with AWS Secrets Manager and the Jenkins IAM role is specifically granted required permissions. This allows for dynamic, secure retrieval and rotation of sensitive credentials, preventing hardcoding and improving overall security posture.
- **"Shift-Left" Security**: Security isn't an afterthought; it's integrated throughout the CI/CD pipeline, catching vulnerabilities early when they're cheapest and easiest to fix.
- **Proactive System Hardening**: The Ansible stage specifically addresses operational security by automating the hardening of the deployment server's SSH configuration, reducing its attack surface.
- **Infrastructure as Code (IaC)**: Terraform ensures consistent, auditable, and repeatable infrastructure deployments, minimizing configuration drift and human error.
- **Immutable Infrastructure**: Leveraging containers and automated deployments means new changes always result in new deployments, promoting consistency and easier rollbacks.
- **Audit**: All security tools integrated in Jenkins build artifacts (including all security scan reports) provide clear audit trails for compliance and post-incident analysis.

### Important Considerations 
When designing this pipeline, I kept a few key DevSecOps principles in mind for real-world application:
- **Actionable Security Findings**: All integrated security tools are configured to generate their output in a structured JSON format. This allows easy access to findings via Jenkins build artifacts. Same can also be integrated into any vulnerability management tool for easy tracking, reporting and remediation.
- **Progressive Security Enforcement**: Currently, the pipeline is designed not to fail immediately if security issues are found. As the organization's DevSecOps maturity increases, the pipeline can be configured to fail builds based on predefined thresholds for critical vulnerabilities.

## Screenshots
Here are some screenshots from a live run of the pipeline, showcasing key stages and security scan results:

### AWS ECR and Secrets Manager
![AWS-ECR](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/aws-ecr.png)
![AWS-Secrets-Manager](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/aws-secrets.png)

### Jenkins Pipeline Overview:
![Jenkins-Pipeline](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/jenkinscicd1.png)

### Jenkins Credentials:
![Jenkins-Credentials](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/jenkins-credentials-aws.png)

### Jenkins Security Scan Results 
![Jenkins-Security-Results](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/security-tools-results-artifacts.png)

### Deployed Application
![Jenkins-Security-Results](https://github.com/pranav1hivarekar/aws-devsecops-pipeline/blob/main/images/liveapp.png)

## Tools & Technologies Used
This project brings together a powerful stack:
- **Cloud Platform**: AWS (EC2, ECR, IAM, Security Groups, Secrets Manager readiness)
- **Infrastructure as Code**: Terraform
- **CI/CD Orchestration**: Jenkins
- **Containerization**: Docker
- **Configuration Management/Hardening**: Ansible
- **Version Control**: Git
- **Security Scanners**:
  - **SAST**: Bandit
  - **SCA**: Safety
  - **Secret Scanning**: TruffleHog
  - **IaC Security**: Checkov
  - **Container Image Scanning**: Trivy
  - **DAST**: OWASP ZAP (Baseline Scan)
- **Scripting**: Bash
- **Sample Application**: Python Flask


## Quick Start
### Pre-requisites - Setting your own machine
1. Install Required Tools -
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```
2. Configure AWS CLI with your access key 
```
aws configure
# Provide Access Key, Secret Key, Region
```
3. Generate SSH Key Pair
```
ssh-keygen -t rsa -f ~/.ssh/id_rsa
```
4. Store Private Key in AWS Secrets Manager
```
aws secretsmanager create-secret --name /jenkins/deploy_ssh_key --secret-string "$(cat ~/.ssh/id_rsa)"
```
5. Store github token in AWS Secrets Manager 
```
aws secretsmanager create-secret --name /jenkins/github_token --description "GitHub token for Jenkins to pull private repos" --secret-string "ghp_ZlgsSMuzdummygdummyVdummy37Ia42dummy"
```
6. Tag secrets so we can access it inside of jenkins 
```
aws secretsmanager tag-resource \
  --secret-id /jenkins/github_token \
  --tags Key=jenkins:credentials:type,Value=usernamePassword Key=jenkins:credentials:username,Value=github

aws secretsmanager tag-resource \
  --secret-id /jenkins/deploy_ssh_key \
  --tags \
    Key=jenkins:credentials:type,Value=sshUserPrivateKey \
    Key=jenkins:credentials:username,Value=ec2-user
```
7. Setup ECR repository 
```
aws ecr create-repository --repository-name aws-devsecops-pipeline --region us-east-1
```
8. Install Terraform

Install terraform/ https://developer.hashicorp.com/terraform/install - This is for Amazon Linux. Select appropriate for yourself.
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```
9. Clone the repo and start
```bash
cd terraform/
terraform init
terraform apply
```
### Jenkins With DevSecOps Pipeline
1. Output after your run terraform
```
deployment_ip = "34.229.75.108"
jenkins_url = "http://13.219.105.33:8080"
[ec2-user@ip-172-31-80-7 terraform]$ cat jenkins_admin_password.txt
d4e1a7e6fcb34a3497c0ff5e553515c4
```
2. Access jenkins and install AWS Secrets Manager Credentials Provider plugin. IAM role will automatically load it in Jenkins credential store.
3. Create jenkins pipeline inside of jenkins and check if you are able to access your Github Repo
4. Update Jenkinsfile in the repo with following values you got from terraform output - 
```
REPO_NAME = 'aws-devsecops-pipeline'
ECR_URI = 'YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com'
IMAGE_TAG = "v1.${BUILD_ID}"
DEPLOY_IP = '34.229.75.108'
```
5. Pipeline will run
6. Security tools are configured to generate their output in a structured JSON format. This allows easy access to findings via Jenkins build artifacts.
7. Access the live app - http://34.229.75.108

### Destroying Infrastructure 
Teardown infrastructure
```
terraform destroy
```
Also, need to manually delete AWS ECR and Secrets added in the AWS secrets manager. 


## Contribute
Ideas or improvements? I am always open to feedback! Feel free to open an issue or submit a pull request.

## Get In Touch
- Linkedin - https://www.linkedin.com/in/pranavhivarekar/
- Github - https://github.com/pranav1hivarekar
