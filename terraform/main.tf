provider "aws" {
  region = var.region
}

data "aws_vpc" "main" {
  default = true
}

# Data source to dynamically fetch VPC by name
data "aws_vpc" "dashboard" {
  filter {
    name   = "tag:Name"
    values = ["dashboard-vpc"]
  }
}

# Data source to dynamically fetch subnets with tag Name=private-subnet-a in our VPC
data "aws_subnets" "dashboard_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.dashboard.id]
  }

  filter {
    name   = "tag:Name"
    values = ["private-subnet-a"]
  }
}

resource "aws_ecr_repository" "dashboard" {
  name = var.app_name
}

resource "aws_ecs_cluster" "cluster" {
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

resource "aws_ecs_task_definition" "mock_api_task" {
  family                   = var.mock_api_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = var.mock_api_name
    image     = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.mock_api_name}:latest"
    essential = true
    portMappings = [{
      containerPort = var.mock_api_container_port
      hostPort      = var.mock_api_container_port
    }]
  }])
}

resource "aws_ecs_service" "mock_api_service" {
  name            = "${var.mock_api_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.mock_api_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.dashboard_subnets.ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.mock_api_tg.arn
    container_name   = var.mock_api_name
    container_port   = var.mock_api_container_port
  }

  depends_on = [aws_lb_listener_rule.mock_api_rule]
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "dashboard-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "dashboard-frontend"
    image     = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/dashboard-frontend:latest"
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}

resource "aws_ecs_service" "frontend_service" {
  name            = "dashboard-frontend-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.dashboard_subnets.ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "dashboard-frontend"
    container_port   = 5000
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_route53_record" "monitor_alias" {
  zone_id = var.route53_zone_id                      
  name    = "monitor.dtinfra.site"
  type    = "A"

  alias {
    name                   = aws_lb.dashboard_alb.dns_name
    zone_id                = aws_lb.dashboard_alb.zone_id
    evaluate_target_health = true
  }
}