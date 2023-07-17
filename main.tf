# provider "aws" {
#   access_key = var.aws-access-key
#   secret_key = var.aws-secret-key
#   region     = var.aws-region
#   version    = "~> 2.0"
# }

# terraform {
#   backend "s3" {
#     bucket  = "terraform-backend-store"
#     encrypt = true
#     key     = "terraform.tfstate"
#     region  = "eu-central-1"
#     # dynamodb_table = "terraform-state-lock-dynamo" - uncomment this line once the terraform-state-lock-dynamo has been terraformed
#   }
# }

# resource "aws_dynamodb_table" "dynamodb-terraform-state-lock" {
#   name           = "terraform-state-lock-dynamo"
#   hash_key       = "LockID"
#   read_capacity  = 20
#   write_capacity = 20
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
#   tags = {
#     Name = "DynamoDB Terraform State Lock Table"
#   }
# }

# module "vpc" {
#   source             = "./vpc"
#   name               = var.name
#   cidr               = var.cidr
#   private_subnets    = var.private_subnets
#   public_subnets     = var.public_subnets
#   availability_zones = var.availability_zones
#   environment        = var.environment
# }

module "security_groups" {
  source         = "./modules/security-groups"
  name           = var.name
  vpc_id         = var.vpc_id
  environment    = var.environment
  container_port = var.container_port
}

module "alb" {
  source              = "./modules/alb"
  name                = var.name
  vpc_id              = var.vpc_id
  subnets             = var.private_subnets
  environment         = var.environment
  alb_security_groups = [module.security_groups.alb-sg-id]
  alb_tls_cert_arn    = var.alb_tls_cert_arn
  health_check_path   = var.health_check_path
}

module "ecr" {
  source      = "./modules/ecr"
  name        = var.name
  environment = var.environment
}


# module "secrets" {
#   source              = "./secrets"
#   name                = var.name
#   environment         = var.environment
#   application-secrets = var.application-secrets
# }

module "ecs" {
  source                      = "./modules/ecs"
  name                        = var.name
  environment                 = var.environment
  region                      = var.aws-region
  subnets                     = var.public_subnets
  aws_alb_target_group_arn    = module.alb.aws_alb_target_group_arn
  ecs_service_security_groups = [module.security_groups.ecs_tasks-sg-id]
  container_port              = var.container_port
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  service_desired_count       = var.service_desired_count
  container_environment = [
    { name = "LOG_LEVEL",
    value = "DEBUG" },
    { name = "PORT",
    value = var.container_port }
  ]
  # container_secrets      = module.secrets.secrets_map
  # container_image = module.ecr.ecr-repository-url
  container_image = "nisarg1611/flask-sample"
  # container_secrets_arns = module.secrets.application_secrets_arn
}

