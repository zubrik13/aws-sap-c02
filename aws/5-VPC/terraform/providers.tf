terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.47.0"
    }
  }

  required_version = "~> 1.8.0"
}

provider "aws" {
  profile = var.profile
  region  = var.region

  default_tags {
    tags = {
      module = "05 Advanced VPC"
    }
  }
}
