aws_account_id     = "386503255039"
region             = "us-west-2"
app_name           = "lucid-dashboard"

subnet_ids = [
  "subnet-01689f80cd3d0b490",
  "subnet-0ce900d5a1014802b",
  "subnet-074ed09585fbaccb7",
  "subnet-07ee473a38be3bd62"
]

public_subnet_ids = [
  "subnet-01689f80cd3d0b490",
  "subnet-0ce900d5a1014802b",
  "subnet-074ed09585fbaccb7",
  "subnet-07ee473a38be3bd62"
]

security_group_id       = "sg-079645811790ebad6"
alb_security_group_id   = "sg-079645811790ebad6"
ecs_security_group_id   = "sg-079645811790ebad6"

container_name     = "lucid-dashboard"
vpc_id             = "vpc-0b02dde4d7fbd4d60" 
ecs_service_name   = "dashboard-task-service"
ecs_cluster_id     = "arn:aws:ecs:us-west-2:386503255039:cluster/dashboard-cluster"