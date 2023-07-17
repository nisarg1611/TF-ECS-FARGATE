output "alb-sg-id" {
  value = module.security_groups.alb-sg-id
}
output "ecs_tasks-sg-id" {
  value = module.security_groups.ecs_tasks-sg-id
}

output "ecr-repository-url" {
  value = module.ecr.ecr-repository-url
}