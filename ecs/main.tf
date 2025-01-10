provider "aws" {
  region = "us-east-1"
}

# Data sources to reference the existing VPC and private subnet
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"] # Adjust to match the VPC Name tag
  }
}

data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet"] # Adjust to match the Private Subnet Name tag
  }
}
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"  # Replace with the actual IAM role name if it differs
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

# Security Group for ECS
resource "aws_security_group" "ecs_sg" {
  name   = "ecs-sg"
  vpc_id = data.aws_vpc.existing_vpc.id

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

  tags = {
    Name = "ecs-sg"
  }
}

# WordPress Task Definition
resource "aws_ecs_task_definition" "wordpress_task" {
  family                   = "wordpress-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn
   container_definitions = jsonencode([
    {
      name      = "wordpress"
      image     = "wordpress:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        {
          name  = "WORDPRESS_DB_USER"
          valueFrom = "arn:aws:secretsmanager:us-east-1:124355673439:secret:rds-credentials:username"
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          valueFrom = "arn:aws:secretsmanager:us-east-1:124355673439:secret:rds-credentials:password"
        }
      ]
    }
  ])
}

# Custom Microservice Task Definition
resource "aws_ecs_task_definition" "microservice_task" {
  family                   = "microservice-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_execution_role.arn


  container_definitions = jsonencode([
    {
      name      = "microservice"
      image     = "your-dockerhub-account/microservice:latest" # Replace with your Docker image
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}

# ECS Services
resource "aws_ecs_service" "wordpress_service" {
  name            = "wordpress-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.wordpress_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.aws_subnet.private_subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

resource "aws_ecs_service" "microservice_service" {
  name            = "microservice-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.microservice_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.aws_subnet.private_subnet.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }
}

# Auto Scaling for WordPress
resource "aws_appautoscaling_target" "wordpress_scaling_target" {
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.wordpress_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "wordpress_scaling_policy" {
  name                    = "wordpress-scaling-policy"
  policy_type             = "TargetTrackingScaling"
  resource_id             = aws_appautoscaling_target.wordpress_scaling_target.resource_id
  scalable_dimension      = aws_appautoscaling_target.wordpress_scaling_target.scalable_dimension
  service_namespace       = aws_appautoscaling_target.wordpress_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Auto Scaling for Microservice
resource "aws_appautoscaling_target" "microservice_scaling_target" {
  max_capacity       = 5
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.microservice_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "microservice_scaling_policy" {
  name                    = "microservice-scaling-policy"
  policy_type             = "TargetTrackingScaling"
  resource_id             = aws_appautoscaling_target.microservice_scaling_target.resource_id
  scalable_dimension      = aws_appautoscaling_target.microservice_scaling_target.scalable_dimension
  service_namespace       = aws_appautoscaling_target.microservice_scaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

