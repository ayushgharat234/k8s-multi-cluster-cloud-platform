terraform {
  required_version = ">= 1.0"

  backend "gcs" {
    bucket = "opsnexus-tfstate-8b5ea7ba"
    prefix = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}
