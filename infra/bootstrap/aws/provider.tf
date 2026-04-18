provider "aws" {
  region = var.aws_region
  # Credentials resolved from environment: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY,
  # or an IAM role attached to the CI runner. Do not hardcode profile names here.
}
