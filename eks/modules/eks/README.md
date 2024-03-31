    module "eks_cluster" {
      source               = ""
      env                  = var.env
      team                 = var.team
      cluster_name         = var.cluster_name
      cluster_version      = var.cluster_version
      vpc_id               = var.vpc_id[var.env]
      subnet_ids           = var.private_subnets[var.env]
      nodegroup_properties = var.nodegroup_properties
      users                = var.users
    
      providers = {
        kubernetes = kubernetes.k8s
      }
    }
