terraform {
  backend "s3" {
    bucket         = "knote-app-devops-tfstate"
    key            = "knote-app.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.39.0"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.knote-cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.knote-cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.knote-cluster.name]
      command     = "aws"
    }
  }
}

locals {
  common_tags = {
    Project   = var.project
    Owner     = var.owner
    ManagedBy = "Terraform"
  }
}

data "aws_region" "current" {}