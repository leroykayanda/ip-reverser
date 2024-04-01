terraform {
  backend "remote" {
    organization = "RentRahisi"

    workspaces {
      prefix = "ip-reverser-aws-"
    }
  }

  required_version = ">= 1.0.0"

  required_providers {

    aws = {
      version = ">= 5.41.0"
    }

    argocd = {
      source  = "oboukili/argocd"
      version = "6.0.3"
    }

  }
}
