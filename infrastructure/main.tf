terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.9.8"
}

locals {
  region = "eu-north-1"
  name   = "devops-project"
}


provider "aws" {
  region = local.region
}

resource "aws_ecr_repository" "default" {
  name = local.name
}

resource "aws_ecs_cluster" "default" {
  name = local.name
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name = aws_ecs_cluster.default.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 100
    base              = 1
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "default" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = local.name
      image = "${aws_ecr_repository.default.repository_url}:latest"

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

resource "aws_default_subnet" "default_az1" {
  availability_zone = "${local.region}a"
}

resource "aws_ecs_service" "default" {
  name                       = local.name
  cluster                    = aws_ecs_cluster.default.id
  task_definition            = aws_ecs_task_definition.default.arn
  desired_count              = 1
  deployment_maximum_percent = 200
  network_configuration {
    subnets          = [aws_default_subnet.default_az1.id]
    assign_public_ip = true
  }

}
