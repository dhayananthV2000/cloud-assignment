Cloud Infrastructure Assignment
This project demonstrates the deployment of a WordPress application, custom microservice, and other infrastructure components using AWS services such as ECS, RDS, SecretsManager, EC2 instances, and more. The infrastructure is managed with Terraform, and deployment automation is handled with GitHub Actions.

1. Private Subnet & VPC Setup
Private subnets have been configured to deploy ECS services securely. A VPC with necessary routing, security groups, and subnets is created to ensure isolation and security. Resources deployed include the WordPress app and a simple Node.js microservice containerized using Docker.

Private Subnet Terraform Code:
https://github.com/dhayananthV2000/cloud-assignment/tree/main/private-subnet
2. ECS Setup
An ECS cluster has been set up with services running within the private subnets. Two Dockerized applications are deployed:

WordPress App: A containerized WordPress application, which connects securely to the RDS database.
Custom Microservice: A lightweight Node.js microservice that responds with "Hello from Microservice."
Auto-scaling has been configured for both services based on CPU and memory utilization.

Dockerfile and ECS Configuration for WordPress and Microservice:
The Dockerfile for the custom Node.js microservice and ECS configuration can be found here: https://github.com/dhayananthV2000/cloud-assignment/tree/main/ecs

ECS IAM Role Configuration:
The IAM role required for ECS task execution to access necessary resources is located here: https://github.com/dhayananthV2000/cloud-assignment/tree/main/ecs/iam
3. RDS and SecretsManager
The WordPress application requires an RDS database to store data. An RDS instance has been provisioned in a private subnet with the following configuration:

Database Credentials: Credentials for the RDS instance are stored securely in AWS SecretsManager.

Automated Backups: Backups are configured for the RDS instance to ensure data safety.

RDS Configuration and SecretsManager Integration:
The Terraform code to create the RDS instance and store the database credentials in SecretsManager can be found here: https://github.com/dhayananthV2000/cloud-assignment/tree/main/rds-and-secret-manager
4. EC2 Instances & NGINX Configuration
Two EC2 instances have been created in private subnets with NGINX installed. CloudWatch agents are also configured to monitor instance performance. 


EC2 Instance Code:
https://github.com/dhayananthV2000/cloud-assignment/tree/main/ec2

Dockerfile for EC2:
Available in the https://github.com/dhayananthV2000/cloud-assignment/tree/main/ec2 repository, the container responds with "Namaste from Docker" when accessed via http://localhost:8080.

5. Application Load Balancer (ALB)
An ALB has been set up in public subnets to handle HTTP/HTTPS traffic. SSL certificates are applied, ensuring all traffic is redirected to HTTPS. The ALB is configured to associate with the domain names for the WordPress application, microservice, EC2 instances, and Docker containers.

ALB Configuration:
https://github.com/dhayananthV2000/cloud-assignment/tree/main/alb
6. GitHub Actions Workflow
The custom microservice is stored in a GitHub repository, and GitHub Actions is used to automate the process of building the Docker image, pushing it to ECS, and deploying to ECR.

GitHub Actions Workflow:
https://github.com/dhayananthV2000/cloud-assignment/actions/workflows/deploy.yml
7. Terraform Data Blocks
Terraform data blocks are used to reference existing resources (such as VPC, private subnets, etc.) during the infrastructure setup. These resources are also present in this repository.
