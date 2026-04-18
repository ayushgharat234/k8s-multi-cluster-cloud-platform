variable "env_name" {
  description = "Environment name."
  type        = string
}

variable "github_repo" {
  description = "The GitHub repository in 'owner/repo' format."
  type        = string
}

variable "github_thumbprint" {
  description = "Thumbprint for the GitHub OIDC provider."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}
