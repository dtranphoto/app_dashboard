resource "aws_lb" "dashboard_alb" {
  name               = "dashboard-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "dashboard-alb"
    autodelete  = "true"
    environment = "dev"
  }
}

resource "aws_lb_target_group" "dashboard_tg" {
  name     = "dashboard-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  target_type = "ip"

  tags = {
    Name        = "dashboard-tg"
    autodelete  = "true"
    environment = "dev"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.dashboard_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dashboard_tg.arn
  }

  tags = {
    Name        = "dashboard-http-listener"
    autodelete  = "true"
    environment = "dev"
  }
}
