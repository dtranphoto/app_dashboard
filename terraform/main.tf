provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "lucid_dashboard" {
  name = var.app_name
}

resource "aws_ecs_cluster" "lucid_cluster" {
  name = "${var.app_name}-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "lucid_task" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = var.app_name
      image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.app_name}:latest"
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

resource "aws_ecs_service" "lucid_service" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.lucid_cluster.id
  task_definition = aws_ecs_task_definition.lucid_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dashboard_tg.arn
    container_name   = var.container_name       # Match this to what's in your task definition
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}