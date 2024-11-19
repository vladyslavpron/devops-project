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

# TODO: Proper IAM for ECS service 
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

      logConfiguration = {
        logDriver : "awslogs"
        options = {
          "awslogs-group" : "${local.name}",
          "awslogs-create-group" : "true",
          "awslogs-region" : local.region,
          "awslogs-stream-prefix" : "ecs"
        }
      }

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


resource "aws_ecs_service" "default" {
  name                       = local.name
  cluster                    = aws_ecs_cluster.default.id
  task_definition            = aws_ecs_task_definition.default.arn
  desired_count              = 1
  deployment_maximum_percent = 200


  load_balancer {
    target_group_arn = aws_lb_target_group.main_target_group.arn
    container_port   = 3000
    container_name   = local.name
  }
  network_configuration {
    subnets = [aws_subnet.main_private_subnet.id]
    security_groups = [ aws_security_group.ecs_sg.id ]
  }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ecs-${local.name}"
}

resource "aws_security_group_rule" "ecs_http_ingress" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "TCP"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main_public_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "main_public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}b"
  cidr_block        = "10.0.2.0/24"
}

resource "aws_subnet" "main_private_subnet" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "${local.region}a"
  cidr_block        = "10.0.3.0/24"
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main_public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main_public_rt_association" {
  subnet_id      = aws_subnet.main_public_subnet.id
  route_table_id = aws_route_table.main_public_rt.id
}


resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "main_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.main_public_subnet.id
}

resource "aws_route_table" "main_private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat.id
  }
}

resource "aws_route_table_association" "main_private_rt_association" {
  subnet_id      = aws_subnet.main_private_subnet.id
  route_table_id = aws_route_table.main_private_rt.id
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  name   = local.name
}

resource "aws_security_group_rule" "alb_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_http_egress_http" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}




resource "aws_alb" "main" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.main_public_subnet.id, aws_subnet.main_public_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "main_target_group" {
  name        = local.name
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 120
  }
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main_target_group.arn
  }
}