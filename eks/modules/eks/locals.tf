locals {
  eks_oidc_issuer = var.cluster_created ? trimprefix(data.aws_eks_cluster.cluster[0].identity[0].oidc[0].issuer, "https://") : ""
}
