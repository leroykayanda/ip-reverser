#general

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "service" {
  type        = string
  description = "The name of the product or service being built"
  default     = "ip-reverser"
}

variable "env" {
  type        = string
  description = "The environment i.e prod, dev etc"
}

variable "team" {
  type        = string
  description = "Used to tag resources"
  default     = "devops"
}

variable "sns_topic" {
  type = map(string)
  default = {
    "dev"  = "arn:aws:sns:eu-west-1:REDACTED:Tell-Developers"
    "prod" = ""
  }
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

#R53 alias
variable "zone_id" {
  type        = string
  description = "Route53 zone to create app dns name in"
  default     = "Z10421303ISFAWMPOGQET"
}

variable "dns_name" {
  type        = map(string)
  description = "dns name of the app"
  default = {
    "dev"  = "ip-reverser.rentrahisi.co.ke"
    "prod" = ""
  }
}
#

#k8s
variable "kubernetes_cluster_name" {
  type    = string
  default = "compute"
}

variable "kubernetes_cluster_env" {
  type = map(string)
  default = {
    "dev"   = "dev"
    "stage" = "dev"
    "sand"  = "dev"
    "prod"  = "prod"
  }
}

#argocd
variable "argo_annotations" {
  type = map(map(string))
  default = {
    "dev" = {
      "notifications.argoproj.io/subscribe.on-health-degraded.slack" = "rentrahisi"
      "argocd-image-updater.argoproj.io/image-list"                  = "repo=735265414519.dkr.ecr.eu-west-1.amazonaws.com/dev-ip-reverser"
      "argocd-image-updater.argoproj.io/repo.update-strategy"        = "latest"
      "argocd-image-updater.argoproj.io/myimage.ignore-tags"         = "latest"
    },
    "prod" = {
    }
  }
}

variable "argo_repo" {
  type        = string
  description = "repo containing manifest files"
  default     = "git@github.com:leroykayanda/ip-reverser.git"
}

variable "argo_target_revision" {
  description = "branch containing app code"
  type        = map(string)
  default = {
    "dev"  = "main"
    "prod" = ""
  }
}

variable "argo_path" {
  type        = map(string)
  description = "path of the manifest files"
  default = {
    "dev"  = "ip-reverser/manifests/overlays/dev"
    "prod" = ""
  }
}

variable "argo_server" {
  type        = map(string)
  description = "dns name of the argocd server"
  default = {
    "dev"  = "dev-argo.rentrahisi.co.ke:443"
    "prod" = ""
  }
}

# variable "app_secrets" {
#   type        = map(string)
#   description = "app environment variables"
#   default = {
#     MYSQL_HOST     = "value1"
#     MYSQL_DATABASE = "value2"
#     MYSQL_USER     = "value3"
#     MYSQL_PASSWORD = "value4"
#   }
# }

# database
variable "db_cluster_instance_class" {
  type        = map(string)
  description = "Aurora DB instance class"
  default = {
    "dev"  = "db.t3.medium"
    "prod" = ""
  }
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_engine_version" {
  default = "8.0.mysql_aurora.3.06.0"
}

variable "db_name" {
  type    = string
  default = "ip_reverser"
}

variable "db_master_username" {
  type = string
}

variable "db_master_password" {
  type = string
}

variable "db_instance_count" {
  type = map(number)
  default = {
    "dev"  = 1
    "prod" = 1
  }
}

variable "db_engine" {
  type        = string
  description = "Valid Values: aurora-mysql, aurora-postgresql, mysql, postgres"
  default     = "aurora-mysql"
}

variable "db_parameter_group_family" {
  type        = string
  description = "eg aurora-postgresql13"
  default     = "aurora-mysql8.0"
}

variable "publicly_accessible" {
  default = true
}

variable "performance_insights_enabled" {
  default = false
}
