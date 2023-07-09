terraform {

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

locals {
  common_tags = {
    Project   = var.project
    Owner     = var.owner
    ManagedBy = "Terraform"
  }
}

data "aws_region" "current" {}