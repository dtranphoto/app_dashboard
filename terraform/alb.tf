resource "aws_lb" "dashboard_alb" {
  name               = "dashboard-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "dashboard-alb"
    autodelete  = "true"
    environment = "dev"
  }
}

# Dashboard target group
resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  target_type = "ip"

  tags = {
    Name        = "frontend-tg"
    autodelete  = "true"
    environment = "dev"
  }
}

# Grafana target group
resource "aws_lb_target_group" "grafana_tg" {
  name        = "grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "grafana-tg"
    autodelete  = "true"
    environment = "dev"
  }
}

# Prometheus target group
resource "aws_lb_target_group" "prometheus_tg" {
  name        = "prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
  path                = "/prometheus/-/healthy"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  matcher             = "200"
  }

  tags = {
    Name        = "prometheus-tg"
    autodelete  = "true"
    environment = "dev"
  }
}

resource "aws_lb_target_group" "alertmanager_tg" {
  name        = "alertmanager-tg"
  port        = 9093
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
  path                = "/alertmanager/-/healthy"
  protocol            = "HTTP"
  matcher             = "200"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  }

  tags = {
  Name        = "alertmanager-tg"
  autodelete  = "true"
  environment = "dev"
  }
}

resource "aws_lb_target_group" "mock_api_tg" {
  name        = "mock-api-tg"
  port        = 5001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "mock-api-tg"
    autodelete  = "true"
    environment = "dev"
  }
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.dashboard_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name        = "dashboard-http-listener"
    autodelete  = "true"
    environment = "dev"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.dashboard_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-west-2:386503255039:certificate/42c0ec1e-6870-49c4-8b8a-b0176b1d6782"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = {
    Name        = "dashboard-https-listener"
    autodelete  = "true"
    environment = "dev"
  }
}


# Grafana path rule
resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }

  condition {
    path_pattern {
      values = ["/grafana*", "/grafana"]
    }
  }
}

# Prometheus path rule
resource "aws_lb_listener_rule" "prometheus_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }

  condition {
    path_pattern {
      values = ["/prometheus*", "/prometheus"]
    }
  }
}

resource "aws_lb_listener_rule" "alertmanager_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 40

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alertmanager_tg.arn
  }

  condition {
    path_pattern {
      values = ["/alertmanager*", "/alertmanager/*"]
    }
  }
}

# Route /services.json to mock-api
resource "aws_lb_listener_rule" "mock_api_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 15

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mock_api_tg.arn
  }

  condition {
    path_pattern {
      values = ["/services.json", "/services.json*"]
    }
  }
}