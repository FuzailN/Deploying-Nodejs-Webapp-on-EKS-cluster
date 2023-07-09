pipeline {
    agent any

    environment {       
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        SLACK_WEBHOOK_URL = credentials('SLACK_WEBHOOK_URL')
        DUCKDNS_TOKEN = credentials('DUCKDNS_TOKEN')
        DUCKDNS_EMAIL = credentials('DUCKDNS_EMAIL')
        DUCKDNS_DOMAIN = 'knote-cluster'
        DOCKER_SERVER = "nginx-proxy.duckdns.org"
        DOCKER_PORT = '8083'
        DOCKER_REPO = "${DOCKER_SERVER}:${DOCKER_PORT}"
    }

    stages {
        stage("Build and Push Image") {
            steps {
                script{
                    echo "Logging into the Docker Repo... "

                    COMMIT_SHA = sh(
                            script: "git rev-parse HEAD | cut -c1-8",
                            returnStdout: true
                            ).trim()
                    env.KNOTE_APP= "knote:${COMMIT_SHA}"

                    withCredentials([usernamePassword(credentialsId: "Nexus", usernameVariable: "USER", passwordVariable: "PASS")]) {
                        sh "echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO}"
                    }

                    echo "Building and Pushing the docker image... "
                    sh "docker build -t ${DOCKER_REPO}/${KNOTE_APP} ./App"
                    sh "docker push ${DOCKER_REPO}/${KNOTE_APP}"

                }
            }
        }
        stage("Create Infrastructure") {
            steps {
                script {
                    dir('Terraform') {                    
                        echo "Creating Infrastructure... "   
                        sh "envsubst < ../K8s/Templates/duckdns-webhook-temp.yaml > helm-values-files/duckdns-webhook.yaml"       
                        sh "terraform init"
                        sh "terraform validate"
                        
                        sh "terraform plan -detailed-exitcode"
                        TERRAFORM_EXIT_CODE = sh(script: "echo \$?",returnStdout: true).trim()
                        sh "terraform apply -auto-approve"
                        if (TERRAFORM_EXIT_CODE == '2') {
                            sleep(time:30,unit:"SECONDS")
                            }

                        CLUSTER_NAME = sh(
                            script: "terraform output cluster_name",
                            returnStdout: true
                            ).trim()
                        sh "aws eks update-kubeconfig --name ${CLUSTER_NAME}"

                        LOAD_BALANCER_IP = sh(
                            script: "dig +short \$(aws elbv2 describe-load-balancers --query 'LoadBalancers[].DNSName' --output text) | head -n 1",
                            returnStdout: true
                            ).trim()
                        sh "echo url='https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=${LOAD_BALANCER_IP}' | curl -K -"
                    }
                }
            }
        }
        stage("Updating K8s Manifests") {
            steps {
                script {
                    dir('K8s') {
                        echo "Updating K8s manifests... "
                        
                        withCredentials([usernamePassword(credentialsId: "Nexus", usernameVariable: "USER", passwordVariable: "PASS")]) {
                            sh "kubectl create secret docker-registry my-registry-key --dry-run=client --docker-server=${DOCKER_REPO} --docker-username=$USER --docker-password=$PASS --namespace=application -o yaml > Knote/docker-secret.yaml"
                        }
                        
                        env.SLACK_SECRET = sh(
                            script: "echo -n ${SLACK_WEBHOOK_URL} | base64 | tr -d '\n'",
                            returnStdout: true
                            ).trim()

                        sh "kubectl label --overwrite namespace monitoring cert-manager release=prometheus"
                        sh "envsubst < Templates/knote-temp.yaml > Knote/knote.yaml"
                        sh "envsubst < Templates/slack-secret-temp.yaml > Monitoring/slack-secret.yaml"
                    }
                }
            }
        }   
        stage("Commit version update") {
            steps {
                script {
                    echo "Commit and push K8s manifests... "
                    
                    withCredentials([usernamePassword(credentialsId: "Github", usernameVariable: "USER", passwordVariable: "PASS")]) {
                        sh "git remote set-url origin https://$USER:$PASS@github.com/omarnabil1998/Continuous-deployment.git"
                    }
                    
                    sh "git config --global user.name 'jenkins'"
                    sh "git config --global user.email 'jenkins@email.com'"
                    sh "git rm -rf --cached ."
                    
                    sh "git add K8s && git add K8s/*"
                    sh "git commit -m 'ci version update'"
                    sh "git push origin HEAD:master --force"
                }
            }
        }
        stage("Executing argocd application") {
            steps {
                script {
                    echo "Executing argocd app-of-apps... "
                    sh "kubectl apply -f K8s/Argocd-app-of-apps/App-of-apps.yaml"
                }
            }
        }    
    }
}