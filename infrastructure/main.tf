terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.9.8"
}

locals {
  region = "eu-north-1"
  name   = "devops-project"
}

# TODO: Proper IAM for ECS service 
provider "aws" {
  region = local.region
}

resource "aws_ecr_repository" "default" {
  name = local.name
}

