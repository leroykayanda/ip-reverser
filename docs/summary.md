**EKS Setup**

We first set up an EKS cluster. The terraform code for this is in the eks folder. We use a custom terraform module located in the eks/modules/eks folder. These are the components that we set up.

**EKS cluser components**
1.  EKS module
2.  VPC
3. cloudwatch container insights for metrics
4. fluentbit for logs
5.  a cloudwatch dashboard showing key cluster metrics like cpu, memory and disk usage. There are cloudwatch alarms for these key metrics.
6.  argocd for CICD. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
7.  cluster autoscaler
8.  AWS load balancer controller
9.  metrics server
10.  External secrets helm chart

![Cloudwatch dashboard](/docs/images/dash.png "Cloudwatch dashboard")

Of note is that we use the new [access entries](https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/) feature to grant users access to the cluster rather than using the aws-auth config map. This allows us to assign users fine grained permissions eg we can grant a user permissions only to specific namespaces. We can also grant full admin or read only permissions to the cluster.  

