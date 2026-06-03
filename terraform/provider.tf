terraform {
  backend "s3" {
    bucket         = "devops-2tier-tfstate-praneshka"
    key            = "devops-2tier-cicd/terraform.tfstate"
    region         = "ap-south-1"
   use_lockfile = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}