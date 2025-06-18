output "ecr_repository_url" {
  value = aws_ecr_repository.dashboard.repository_url
}

output "prometheus_alb_dns" {
  value = aws_lb.dashboard_alb.dns_name
}