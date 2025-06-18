resource "aws_ecs_task_definition" "grafana_task" {
  family                   = "grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
  name      = "grafana"
  image     = "386503255039.dkr.ecr.us-west-2.amazonaws.com/grafana:latest"
  essential = true
  portMappings = [{
    containerPort = 3000
    hostPort      = 3000
  }],
  environment = [
    {
        name  = "GF_SERVER_ROOT_URL"
        value = "%(protocol)s://%(domain)s/grafana"
      },
      {
        name  = "GF_SERVER_SERVE_FROM_SUB_PATH"
        value = "true"
      },
      {
        name  = "GF_DATASOURCE_PROMETHEUS_URL"
        value = "http://${aws_lb.dashboard_alb.dns_name}/prometheus"
      },
      {
        name  = "GF_DATASOURCE_ALERTMANAGER_URL"
        value = "http://${aws_lb.dashboard_alb.dns_name}/alertmanager"
      }
  ],
  logConfiguration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = "/ecs/grafana"
      awslogs-region        = "us-west-2"
      awslogs-stream-prefix = "ecs"
    }
  },
  healthCheck = {
    command     = ["CMD-SHELL", "curl -f http://localhost:3000/api/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 10
  }
  }])

}

resource "aws_ecs_service" "grafana_service" {
  name            = "grafana-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.dashboard_subnets.ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana_tg.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener_rule.grafana_rule,
                aws_ecs_cluster.cluster
                ]

}

resource "aws_ecs_task_definition" "prometheus_task" {
  family                   = "prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "prometheus"
    image     = "386503255039.dkr.ecr.us-west-2.amazonaws.com/prometheus:latest"
    essential = true
    portMappings = [{
      containerPort = 9090
      hostPort      = 9090
    }],
    command = [
      "--web.listen-address=0.0.0.0:9090",
      "--web.route-prefix=/prometheus",
      "--web.external-url=http://34.217.98.171:9090/prometheus"
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/prometheus"
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "ecs"
      }
    },
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:9090/prometheus/-/healthy || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
  }])
}

resource "aws_ecs_service" "prometheus_service" {
  name            = "prometheus-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.prometheus_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.dashboard_subnets.ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [
    aws_lb_listener_rule.prometheus_rule,
    aws_ecs_task_definition.prometheus_task,
    aws_ecs_cluster.cluster
  ]
}

resource "aws_ecs_task_definition" "alertmanager_task" {
  family                   = "alertmanager"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "alertmanager"
    image     = "386503255039.dkr.ecr.us-west-2.amazonaws.com/alertmanager:latest"
    essential = true
    portMappings = [{
      containerPort = 9093
      hostPort      = 9093
      protocol      = "tcp"
    }],
    command = [
      "--config.file=/etc/alertmanager/alertmanager.yml",
      "--web.route-prefix=/alertmanager",
      "--web.listen-address=0.0.0.0:9093"
    ],
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/alertmanager"
        awslogs-region        = "us-west-2"
        awslogs-stream-prefix = "ecs"
      }
    },
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:9093/alertmanager/-/healthy || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    },
    #mountPoints = [], # Add if you use volumes
    #environment = [], # Add if you want to pass env vars
    #workingDirectory = "/etc/alertmanager" # Optional
  }])
}

resource "aws_ecs_service" "alertmanager_service" {
  name            = "alertmanager-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.alertmanager_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  enable_execute_command = true

  network_configuration {
    subnets          = data.aws_subnets.dashboard_subnets.ids
    assign_public_ip = true
    security_groups  = [var.security_group_id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alertmanager_tg.arn
    container_name   = "alertmanager"
    container_port   = 9093
  }

  depends_on = [aws_lb_listener_rule.alertmanager_rule, 
                aws_ecs_cluster.cluster
                ]
}