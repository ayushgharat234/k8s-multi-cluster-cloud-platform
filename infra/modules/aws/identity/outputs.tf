output "ci_role_arn" {
  description = "The ARN of the CI/CD IAM Role."
  value       = aws_iam_role.ci_role.arn
}

output "oidc_provider_arn" {
  description = "The ARN of the GitHub OIDC Provider."
  value       = aws_iam_openid_connect_provider.github.arn
}
