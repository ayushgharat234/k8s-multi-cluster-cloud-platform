# Key for EKS Secret Encryption
resource "aws_kms_key" "eks_secret_key" {
  description             = "KMS key for EKS secret encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "eks_secret_alias" {
  name          = "alias/${var.env_name}-eks-secrets"
  target_key_id = aws_kms_key.eks_secret_key.key_id
}

# Key for EKS EBS Volume Encryption
resource "aws_kms_key" "eks_ebs_key" {
  description             = "KMS key for EKS worker node disks"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  # WHY this policy is needed:
  # When a launch template specifies a KMS key for EBS encryption, EC2 Auto Scaling
  # calls kms:CreateGrant on behalf of the instance. Without explicit permission,
  # the key refuses even though "root" has kms:*, because resource-based policies
  # for KMS require the grant action to be explicitly delegated to the service.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowRootAdminAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid    = "AllowAutoScalingServiceToUseKey"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource = "*"
      },
      {
        Sid    = "AllowAutoScalingToCreateGrants"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = { "kms:GrantIsForAWSResource" = "true" }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "eks_ebs_alias" {
  name          = "alias/${var.env_name}-eks-ebs"
  target_key_id = aws_kms_key.eks_ebs_key.key_id
}
