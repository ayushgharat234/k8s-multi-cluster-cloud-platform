output "aws_state_bucket" {
  description = "The name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.state.id
}

output "aws_lock_table" {
  description = "The name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.lock.name
}

output "aws_state_key_arn" {
  description = "The ARN of the KMS key for state encryption"
  value       = aws_kms_key.state_key.arn
}
