## EKS Setup

We first set up an EKS cluster. The terraform code for this is in the eks folder. We use a custom terraform module located in the eks/modules/eks folder. These are the components that we set up.

**EKS cluser components**
1.  EKS module
2.  VPC
3. cloudwatch container insights for metrics
4. fluentbit for logs
5.  a cloudwatch dashboard showing key cluster metrics like cpu, memory and disk usage. There are also cloudwatch alarms for these key metrics.
6.  argocd for CICD. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers deployments when an image is pushed to ECR. Argocd is exposed via ingress.
7.  cluster autoscaler
8.  AWS load balancer controller
9.  metrics server
10.  External secrets helm chart

*Cloudwatch dashboard*

![Cloudwatch dashboard](/docs/images/dash.png )

Of note is that we use the new [access entries](https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/) feature to grant users access to the cluster rather than using the aws-auth config map. This allows us to assign users fine grained permissions eg we can grant a user permissions only to specific namespaces. We can also grant full admin or read only permissions to the cluster.  

We set up the external-secrets helm chart to sync secrets from AWS secrets manager to kubernetes. The secrets are used by the application as environment variables. For this application, we store the database connection details i.e MYSQL_HOST, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD

We also set up the reloader helm chart which triggers a deployment when a new secret is added or an existing secret is modified. Production secrets should thus only be modified during a maintenance window.

## IP-Reverser App Setup

We then set app a python flask application that shows the origin public IP of any request it receives as well as the IP in reverse. These are the components that we set up.

**App components**
 - cloudwatch alarms to monitor key application metrics
 - ECR repo
 - Aurora MySQL DB
 - argocd application
 - AWS secrets manager secret
- kubernetes deployment
- kubernetes service
- kubernetes secrets
- kubernetes AWS load balancer controller
- kubernetesHPA (Horizontal App Autoscaler)
- kubernetes app namespace 
- kubernetes app service account. We use IRSA (IAM Role for Service Accounts)

We use [kustomize](https://kustomize.io/) to manage the application's yaml files. It allows us to have a base config and environment specific overlays where we can specify the configs that differ across environments eg pod cpu and memory.

**Github Actions Pipeline**
We use github actions to push an image to ECR. ArgoCD image updater will detect this new image and trigger a new kubernetes deployment.

*ArgoCD Application*

![Cloudwatch dashboard](/docs/images/argo-app.png )

We have also set up argocd notifications to send alerts to slack whenever the application is unhealthy.

*Slack Notification*

![Cloudwatch dashboard](/docs/images/slack.png )