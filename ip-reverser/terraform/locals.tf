locals {
  eks_oidc_issuer = trimprefix(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://")
  app_secrets = {
    MYSQL_HOST     = module.aurora_mysql.aurora_writer_endpoint
    MYSQL_DATABASE = var.db_name
    MYSQL_USER     = var.db_master_username
    MYSQL_PASSWORD = var.db_master_password
  }
}
