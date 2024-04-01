## EKS Setup Instructions
- set up a terraform cloud workspace named eks-dev.
- set up aws credentials by adding 2 terraform cloud environment variables AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY
- Clone this repo
- Navigate to the eks folder
- set up eks/backend.tf
- set up these environment variables in terraform cloud.

1. access_entries
2. argo_slack_token
3. argo_ssh_private_key
4. env
5. sns_topic

- set up these variables in eks/variables.tf. Modify any other variables that you may need to e.g region

1. zone_id
2. certificate_arn
3. argo_domain_name
4. argocd_image_updater_values
5. company_name

- Run terraform init and terraform apply
- At this point, the cluster has been created
- To log in via kubectl, use:

`aws eks update-kubeconfig --region eu-west-1 --name dev-compute --profile rr`

- verify the worker nodes are ready

 `kubectl get nodes`

- set the value of the cluster_created variable in eks/variable.ts to true. This will create resources that needed the cluster to be created first eg the cluster autoscaler helm chart
- run terraform apply
- verify that

1. A cloudwatch dashboard named dev-compute-kubernetes-cluster has been created
2. Four cluster cloudwatch alarms have been created with the prefix dev-compute
3. A load balancer has been created with a port 443 listener rule pointing to the argocd service
4. Navigate to the argocd domain name.
5. use the username admin and run cmd below to get the password

`kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode`

6. After logging in, go to settings>repositories to make sure argocd has credentials to log in to your github organization.
