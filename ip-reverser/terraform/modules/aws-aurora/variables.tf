variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "microservice_name" {
  type        = string
  description = "Name of the service"
}

variable "team" {
  type        = string
  description = "For resource tags"
}

variable "region" {
  type = string
}


variable "db_subnets" {
  type        = list(string)
  description = "subnets to create the db in"
}

variable "vpc_id" {
  type = string
}

variable "availability_zones" {
  type        = list(string)
  description = "For Aurora"
}

variable "db_cluster_instance_class" {
  type        = string
  description = "Aurora DB instance class"
}

variable "sns_topic" {
  type        = string
  description = "SNS topic ARN for notifications"
}

variable "security_group_id" {
  type = string
}

variable "engine_version" {
}

variable "master_username" {
  type = string
}

variable "master_password" {
  type = string
}

variable "backup_retention_period" {
  type    = number
  default = 35
}

variable "port" {
  type = number
}

variable "database_name" {
  type = string
}

variable "create_cpu_credit_alarm" {
  type        = string
  description = "Create alarm only if a burstable instance class has been chosen. Possible values - yes or no"
  default     = "no"
}

variable "preferred_maintenance_window" {
  type    = string
  default = "sun:00:00-sun:01:00"
}

variable "preferred_backup_window" {
  type    = string
  default = "02:00-03:00"
}

variable "db_instance_count" {
  type = number
}

variable "db_engine" {
  type        = string
  description = "Valid Values: aurora-mysql, aurora-postgresql, mysql, postgres"
}

variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = []
}

variable "snapshot_cluster" {
  type        = string
  description = "cluster whose snapshot we are using"
  default     = null
}

variable "db_cluster_snapshot_identifier" {
  type    = string
  default = null
}

variable "parameter_group_family" {
  type        = string
  description = "eg aurora-postgresql13"
}

variable "creating_db" {
  type    = bool
  default = false
}

variable "local_storage_threshold" {
  type    = number
  default = 10
}

variable "dbload_threshold" {
  type    = number
  default = 5
}

variable "publicly_accessible" {
  default = false
}

variable "performance_insights_enabled" {
  default = false
}
