provider "aws" {
  region = "us-east-1"
}

# Data block to reference the existing VPC by its name or tag
data "aws_vpc" "existing_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]  
  }
}

# Data block to reference the existing private subnet by its name
data "aws_subnet" "existing_private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet"]  
  }
}

# Create Security Group for RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Allow access to RDS instance"
  vpc_id      = data.aws_vpc.existing_vpc.id  
  ingress {
    from_port   = 3306  # MySQL default port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  tags = {
    Name = "rds-sg"
  }
}


data "aws_subnet" "private_subnet_1" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet-1"] 
  }
}


resource "aws_db_subnet_group" "main_subnet_group" {
  name       = "main-subnet-group"
  subnet_ids = [data.aws_subnet.existing_private_subnet.id, data.aws_subnet.private_subnet_1.id]

  tags = {
    Name = "main-subnet-group"
  }
}
resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "rds-credentials"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id     = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "wp_user"
    password = "wp_password"  # Replace with a secure password
  })
}

resource "aws_db_instance" "wordpress_db" {
  allocated_storage       = 20
  storage_type            = "gp2"
  instance_class          = "db.t3.micro"  
  engine                  = "mysql"
  engine_version          = "8.0.39"
  db_name                 = "wordpress"
  username                = "wp_user"
  password                = "wp_password"  
  backup_retention_period = 7
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.main_subnet_group.id
  multi_az                = false
}

