# Deploying Nodejs Webapp on EKS cluster with Terraform, Ansible, Istio, Jenkins and Argocd
## Project Diagram

## Project Description
- Provisioning 3 servers for jenkins, nexus and nginx with Terraform and configuring them with Ansible
- Dockerize a nodejs web app and push it to private docker registry hosted on nexus running behind nginx reverse proxy with tls configured
- Provisioning EKS cluster using Terraform with Istio gateway to be the entrypoint of our cluster
- Finally we can access our web app through our Domain using HTTPS

## Details
### Nexus
- we will create a docker hosted repository on nexus with a new user and role
- configure Docker bearer token realm
- In order for K8s to pull an image it needs to be connected to a secured registry so in order to secure our registry we need tls

### Nginx
- we will use nginx as a reverse proxy for our nexus and jenkins servers as well as the docker repo
- we needed tls so we installed certbot and generate a certificate for our duckdns domain

### Jenkins (CICD)
- we need to define our credentials in jenkins like the AWS and nexus credentials so that the pipeline can be executed successfully
- Our jenkins CICD pipeline consists of 5 stages 
    1. Building and push docker image to nexus registry
    2. Create our infrastruture with terraform
    3. Updating the K8s manifests with the new image tag and substituting environment variables with credentials in order not to hardcode them in the manifests 
    4. Committing the changes to the CD repository 
    5. Finally applying the argocd app of apps manifest

### Ansible
- I used ansible for configuring the 3 servers provisioned by terraform, it will run after terraform automatically using local-exec provisioner
- Instead of defining the IP addresses of the servers I used AWS dynamic inventory which will get the servers' addresses using a tag assigned to them with terraform
- After ansible complete configuring the servers and install the necessary tools it will get us the initial admin passwords for jenkins and nexus which we will use to login

### EKS cluster
- I created a K8s cluster in 2 public and 2 private subnets in 2 AZs
- Installed components like autoscaler and EBS CSI for dynamic provisioning of volumes with openid connect provider 
- Used Helm provider to install components on the K8s cluster 

### Prometheus
- For monitoring our infrastructure and our K8s cluster 
- enabled service monitor argument during the installation of cert-manager to allow prometheus to scrape cert-manager we also created a grafana dashboard for cert-manager using a ConfigMap
- Deployed mongodb exporter for exposing mongodb metrics 
- Defined alert rules to fire and send notification to slack channel in case some conditions occured like a high CPU load 

### Istio
- To enable Mtls by default in our application namespace
- I used istio gateway and virtual service to route the traffic to our webapp internal service 

### Certmanager
- I used certmanager with duckdns webhook in order to create a certificate for our domain that we can use to configure HTTPS to the K8s entrypoint

### Argocd
- To achieve continious deployment we need to follow Gitops approach by using CD tools like argocd to configure our cluster automatically when pushing to the Git repo instead of appling the K8s manifests manually

## To start the application
### Prerequisites
- Terraform
- Ansible
- boto3 and botocore installed
- Duckdns account for the nexus server and loadbalancer Domains
- Slack account for notifications
- AWS keypair installed 

### Steps

Step 1: Clone This repo

Step 2: Push it to your GitHub account

Step 3: Go to the Initial_servers directory
 
    cd Initial_Servers
    
Step 4: Provision and configure our servers

    terraform apply -auto-approve
    
Step 5: access nexus through the nginx URL and port and create docker hosted repo

Step 6: access jenkins and configure a pipeline with the github repo as a source and configure the credentials in the jenkins file

Step 7: run the jenkins pipeline
