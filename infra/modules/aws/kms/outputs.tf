output "eks_secret_key_arn" {
  description = "The ARN of the KMS key for EKS secret encryption."
  value       = aws_kms_key.eks_secret_key.arn
}

output "eks_ebs_key_arn" {
  description = "The ARN of the KMS key for EKS EBS encryption."
  value       = aws_kms_key.eks_ebs_key.arn
}
