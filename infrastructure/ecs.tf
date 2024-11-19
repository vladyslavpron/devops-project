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

