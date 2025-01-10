provider "aws" {
  region = "us-east-1"  # Adjust the region as needed
}

data "aws_vpc" "main_vpc" {
  filter {
    name   = "tag:Name"
    values = ["main-vpc"]
  }
}

data "aws_subnet" "private_subnet" {
  filter {
    name   = "tag:Name"
    values = ["private-subnet"]
  }
}

resource "aws_instance" "ec2_docker1" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.private_subnet.id
  associate_public_ip_address = false

  tags = {
    Name = "ec2-docker1"
  }

  user_data = <<-EOF
    #!/bin/bash
    
    sudo apt-get update -y
    sudo apt-get install -y amazon-cloudwatch-agent docker.io nginx

    
    sudo systemctl enable docker
    sudo systemctl start docker

    
    sudo systemctl enable nginx
    sudo systemctl start nginx

    
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "metrics_collection_interval": 60
          },
          "mem": {
            "measurement": [
              "mem_used_percent",
              "mem_available_percent"
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOT

    
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
  EOF
}

resource "aws_instance" "ec2_docker2" {
  ami           = "ami-005fc0f236362e99f"
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.private_subnet.id
  associate_public_ip_address = false

  tags = {
    Name = "ec2-docker2"
  }

  user_data = <<-EOF
    #!/bin/bash
    
    sudo apt-get update -y
    sudo apt-get install -y amazon-cloudwatch-agent docker.io nginx

    
    sudo systemctl enable docker
    sudo systemctl start docker

    
    sudo systemctl enable nginx
    sudo systemctl start nginx

    
    cat <<EOT > /opt/aws/amazon-cloudwatch-agent/bin/config.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      },
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "metrics_collection_interval": 60
          },
          "mem": {
            "measurement": [
              "mem_used_percent",
              "mem_available_percent"
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOT

    
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
  EOF
}

resource "aws_eip" "ec2_docker1_eip" {
  instance = aws_instance.ec2_docker1.id
}
