module "ecr_repo" {
  source               = "./modules/aws-ecr-repo"
  env                  = var.env
  microservice_name    = var.service
  image_tag_mutability = var.image_tag_mutability
}

module "aurora_mysql" {
  source                       = "./modules/aws-aurora"
  env                          = var.env
  team                         = var.team
  db_engine                    = var.db_engine
  microservice_name            = var.service
  db_subnets                   = data.terraform_remote_state.eks.outputs.public_subnets
  vpc_id                       = data.terraform_remote_state.eks.outputs.vpc_id
  availability_zones           = data.terraform_remote_state.eks.outputs.azs
  db_cluster_instance_class    = var.db_cluster_instance_class[var.env]
  sns_topic                    = var.sns_topic[var.env]
  security_group_id            = aws_security_group.db_sg.id
  engine_version               = var.db_engine_version
  master_password              = var.db_master_password
  master_username              = var.db_master_username
  port                         = var.db_port
  db_instance_count            = var.db_instance_count[var.env]
  database_name                = var.db_name
  region                       = var.region
  publicly_accessible          = var.publicly_accessible
  parameter_group_family       = var.db_parameter_group_family
  performance_insights_enabled = var.performance_insights_enabled
}
