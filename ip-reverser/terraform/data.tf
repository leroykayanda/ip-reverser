data "aws_eks_cluster" "cluster" {
  name = "${var.kubernetes_cluster_env[var.env]}-${var.kubernetes_cluster_name}"
}

data "aws_eks_cluster_auth" "auth" {
  name = "${var.kubernetes_cluster_env[var.env]}-${var.kubernetes_cluster_name}"
}

data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "remote"

  config = {
    organization = "RentRahisi"
    workspaces = {
      name = "eks-${var.env}"
    }
  }
}
