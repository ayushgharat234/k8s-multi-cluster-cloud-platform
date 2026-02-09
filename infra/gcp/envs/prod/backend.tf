terraform {
  backend "gcs" {
    bucket = "tf-state-platform-prod"
    prefix = "networking/state"
  }
}
