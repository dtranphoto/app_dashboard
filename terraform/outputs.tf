output "ecr_repository_url" {
  value = aws_ecr_repository.dashboard.repository_url
}

output "grafana_url" {
  value = "https://monitor.dtinfra.site/grafana"
}

output "prometheus_url" {
  value = "https://monitor.dtinfra.site/prometheus"
}

output "alertmanager_url" {
  value = "https://monitor.dtinfra.site/alertmanager"
}