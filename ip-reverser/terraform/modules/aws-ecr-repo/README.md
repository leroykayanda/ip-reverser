    module "ecr_repo" {
      source            = "modules/aws-ecr-repo?ref=v1.0.9"
      env               = var.env
      microservice_name = "${var.microservice_name}"
    }