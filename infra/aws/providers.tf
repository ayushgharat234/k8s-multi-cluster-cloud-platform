terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "opsnexus-tfstate-0b48f6b3"
    key            = "terraform/state"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:262270938572:key/44a42337-1e38-42a3-8544-746f53643a84"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
}
