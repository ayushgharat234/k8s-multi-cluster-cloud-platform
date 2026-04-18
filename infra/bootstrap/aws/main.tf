resource "random_id" "suffix" {
  byte_length = 4
}

# 1. S3 Bucket for Terraform State
resource "aws_s3_bucket" "state" {
  bucket        = "opsnexus-tfstate-${random_id.suffix.hex}"
  force_destroy = false
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 2. DynamoDB for State Locking
resource "aws_dynamodb_table" "lock" {
  name         = "opsnexus-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# 3. KMS Key for State Encryption
resource "aws_kms_key" "state_key" {
  description             = "KMS key for OpsNexus state encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "state_key" {
  name          = "alias/opsnexus-state-key"
  target_key_id = aws_kms_key.state_key.key_id
}
