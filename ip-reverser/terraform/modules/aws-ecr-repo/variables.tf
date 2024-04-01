variable "microservice_name" {
  type        = string
  description = "Name of the ECS service"
}

variable "env" {
  type        = string
  description = "Deployment environment eg prod, dev"
}

variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}
