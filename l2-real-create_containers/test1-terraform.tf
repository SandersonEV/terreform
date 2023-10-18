# This is my first try usind terraform.
# My plan is to use localstack insted of the aws cloud to avoid of pay for unused services of the cloud.

terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "3.27"
    }
  }
  required_version = ">= 0.13.4"
}
provider "aws" {
    profile = "san.sev2" # This is the fake profile created to interact with localstak. AWS-CLI always ask to a account on aws even if you are using localstack container to simulate aws
    region = "us-east-2"

}

# Bucket
resource "aws_s3_bucket" "testeTerraform-bucket" {

    # bucket name 
    bucket = "teste-terraform-bucket"

    # Add tags to the bucket
    tags = {
      Environment = "Dev"
      Project     = "Teste"
    }

}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "my_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Route Table
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "associate_rt" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route_table.id
}

# Security Group
resource "aws_security_group" "sg" {
  name        = "my_sg"
  description = "My security group"
  vpc_id      = aws_vpc.my_vpc.id
}


# ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my_cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my_task_family"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "mysql"
    image = "mysql:latest"
    portMappings = [{
      containerPort = 3306
      hostPort      = 3306
    }]
  },
  {
    name  = "pentaho"
    image = "pentaho:latest"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
  },
  {
    name  = "airflow"
    image = "apache/airflow:latest"
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081 # Usando um hostPort diferente para evitar conflito com o Pentaho
    }]
  }])
}

# IAM Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}


# Airflow --------------------------------------------------------------

# Load Balancer 
resource "aws_lb_target_group" "my_target_group_airflow" {
  name     = "my-target-group"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}

resource "aws_ecs_service" "my_service" {
  name            = "my_service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "FARGATE"
  network_configuration {
    subnets = [aws_subnet.my_subnet.id]
  }
  desired_count = 1

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group_airflow.arn
    container_name   = "airflow"
    container_port   = 8081
  }
}

# Airflow --------------------------------------------------------------