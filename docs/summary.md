## EKS Setup

We first set up an EKS cluster. The terraform code for this is in the eks folder. We use a custom terraform module located in the eks/modules/eks folder. These are the components that we set up.

**EKS cluser components**
1.  EKS module
2.  VPC
3. cloudwatch container insights for metrics
4. fluentbit for logs
5.  a cloudwatch dashboard showing key cluster metrics like worker node cpu, memory and disk usage. There are also cloudwatch alarms for these key metrics.
6.  argocd for CICD. This installs the core argocd helm chart which comes bundled with argocd notifications. We also install the argocd image updater which triggers kubernetes deployments when an image is pushed to ECR. Argocd is exposed via ingress.
7.  cluster autoscaler
8.  AWS load balancer controller required to set up ingress
9.  metrics server
10.  External secrets helm chart

*Cloudwatch dashboard*

![Cloudwatch dashboard](/docs/images/dash.png )

Of note is that we use the new [access entries](https://aws.amazon.com/blogs/containers/a-deep-dive-into-simplified-amazon-eks-access-management-controls/) feature to grant users access to the cluster rather than using the aws-auth config map. This allows us to assign users fine grained permissions eg we can grant a user permissions only to specific namespaces. We can also grant full admin or read only permissions to the cluster.  

We set up the external-secrets helm chart to sync secrets from AWS secrets manager to kubernetes. The secrets are used by the application as environment variables. For this application, we store the Aurora database connection details i.e MYSQL_HOST, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD

We also set up the reloader helm chart which triggers a deployment when a new secret is added or an existing secret is modified. Production secrets should thus only be modified during a maintenance window to avoid traffic disruption.

## IP-Reverser App Setup

We then set up a python flask application that shows the origin public IP of any request it receives as well as the IP in reverse. These are the components that we create.

**App components**
 - cloudwatch alarms to monitor key application metrics e.g pod memory and cpu usage
 - ECR repo
 - Aurora MySQL DB
 - argocd application
 - AWS secrets manager secret
- kubernetes deployment
- kubernetes service
- kubernetes secrets
- kubernetes AWS load balancer controller
- kubernetes HPA (Horizontal App Autoscaler)
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

**The Flask App**

The EKS ingress spins up an application load balancer. We can thus get the public IP of a user from the **X-Forwarded-For** header.

    @app.route("/")
    def home():
        # get IP from X-Forwarded-For header
        ip = request.headers.get("Host")
        all_headers = dict(request.headers)
    
        # initialize MySQL connection
        cursor = initialize_mysql()
    
        # reverse the IP
        reversed_ip = reverse_ip(ip)
    
        # Insert the ip into the ips table
        save_ip(ip,reversed_ip,cursor)
    
        # retrieve the count of all IPs in the database
        ip_counts = get_ip_count(cursor)
    
        return jsonify({
            "IP": ip,
            "IP Reversed": reversed_ip,
            "ip_counts": ip_counts
        })

Various functionalities are written in python functions.

- We first get the IP from the X-Forwarded-For header
- We then initialise a connection to the Aurora MySQL db and create an ips table to store the IP we retrieve
- We reverse the IP
- We save the IP and reversed IP in the ips table
- We retrieve the count of all IPs stored in the database.
- Finally we display the users IP, the reversed IP and the count of all IPs in the database.

*IPs*

![Cloudwatch dashboard](/docs/images/ips.png )


**Design Decisions**

- We use the development server provided by flask to run the application as it is the quickest way. In production, we would use a production ready web server like nginx.
- We made use of terraform modules to set up various resources such as EKS. This has various advantages like making it quick and easy to set up resources and it allows us to enforce infrastructure standards.
- We use python functions in the flask application to make the code easier to read
- We logged into argocd using the default admin user. In production we would disable this default user and set up Google SSO.