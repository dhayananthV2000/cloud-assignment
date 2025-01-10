Cloud Infrastructure Assignment
This project demonstrates the deployment of a WordPress application, custom microservice, and other infrastructure components using AWS services such as ECS, RDS, SecretsManager, EC2 instances, and more. The infrastructure is managed with Terraform and deployment automation is handled with GitHub Actions.

1. Private Subnet & VPC Setup
Private subnets have been configured to deploy ECS services securely. A VPC with necessary routing, security groups, and subnets is created to ensure isolation and security. Resources deployed include the WordPress app and a simple Node.js microservice containerized using Docker.

Private Subnet Terraform Code:
Private Subnet
2. ECS Setup
The ECS cluster is set up to run the WordPress app and custom Node.js microservice within private subnets. Auto-scaling has been configured based on CPU and memory usage.

WordPress App and Custom Node.js Microservice:
The Dockerfile for the custom microservice and ECS configuration is available here.

ECS IAM Role:
The IAM role required for ECS task execution is configured and stored in the IAM folder.

3. RDS and SecretsManager
An RDS instance is configured to host the WordPress database, with automated backups enabled. The database credentials are securely stored in AWS SecretsManager and are used by the WordPress application.

RDS and SecretsManager Configuration:
The code to deploy RDS and manage secrets is stored here.
4. EC2 Instances & NGINX Configuration
Two EC2 instances have been created in private subnets with NGINX installed. CloudWatch agents are also configured to monitor instance performance. NGINX serves the following:

The text "Hello from Instance" for the ec2-instance.<domain-name>

The output from a Docker container running on the same EC2 instance, which responds with "Namaste from Container" for ec2-docker.<domain-name>

EC2 Instance Code:
EC2 Instances with NGINX Setup

Dockerfile for EC2:
Available in the EC2 repository, the container responds with "Namaste from Docker" when accessed via http://localhost:8080.

5. Application Load Balancer (ALB)
An ALB has been set up in public subnets to handle HTTP/HTTPS traffic. SSL certificates are applied, ensuring all traffic is redirected to HTTPS. The ALB is configured to associate with the domain names for the WordPress application, microservice, EC2 instances, and Docker containers.

ALB Configuration:
ALB Terraform Code
6. GitHub Actions Workflow
The custom microservice is stored in a GitHub repository, and GitHub Actions is used to automate the process of building the Docker image, pushing it to ECS, and deploying to ECR.

GitHub Actions Workflow:
Deployment Workflow
7. Terraform Data Blocks
Terraform data blocks are used to reference existing resources (such as VPC, private subnets, etc.) during the infrastructure setup. These resources are also present in this repository.
