# --- VPC MODULE ---
module "vpc" {
  source       = "../modules/aws/vpc"
  env_name     = var.env_name
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
}

# --- KMS MODULE ---
module "kms" {
  source     = "../modules/aws/kms"
  env_name   = var.env_name
  account_id = data.aws_caller_identity.current.account_id
}

# --- IDENTITY MODULE (GitHub OIDC for CI/CD) ---
module "identity" {
  source      = "../modules/aws/identity"
  env_name    = var.env_name
  github_repo = var.github_repo
}

# --- IAM: EKS CLUSTER ROLE ---
resource "aws_iam_role" "cluster_role" {
  name = "${var.cluster_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# --- IAM: EKS NODE ROLE ---
resource "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  policy_arn = each.value
  role       = aws_iam_role.node_role.name
}

# --- EKS MODULE (SPOKE/WORKLOAD) ---
module "eks_spoke" {
  source           = "../modules/aws/eks"
  cluster_name     = var.cluster_name
  env_name         = var.env_name
  vpc_id           = module.vpc.vpc_id
  cluster_role_arn = aws_iam_role.cluster_role.arn
  node_role_arn    = aws_iam_role.node_role.arn
  subnet_ids       = module.vpc.private_subnet_ids
  kms_key_arn      = module.kms.eks_secret_key_arn
  ebs_kms_key_arn  = module.kms.eks_ebs_key_arn
  instance_type        = "t3.micro"
  desired_capacity     = 2
  allowed_public_cidrs = var.eks_allowed_cidrs
}

# Fleet Connect module is intentionally in infra/gcp/ — GCP resources belong in the GCP stack.
# After applying this stack, pass eks_spoke outputs to the GCP stack:
#   terraform output oidc_provider_url → gcp/variables.tf: eks_oidc_url

data "aws_caller_identity" "current" {}

# --- ECR REPOSITORIES ---
locals {
  ecr_repos = ["opsnexus/storefront-catalog"]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.ecr_repos)
  name                 = each.value
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "repos" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images, expire older ones"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# --- IAM ROLE: Cloud Build → ECR push via Workload Identity Federation ---
# GCP Cloud Build SA exchanges a GCP OIDC token for temporary AWS creds.
# Trust policy: only the specific GCP SA unique ID can assume this role.
resource "aws_iam_role" "cloudbuild_ecr" {
  name        = "opsnexus-cloudbuild-ecr-role"
  description = "Assumed by GCP Cloud Build CI SA via OIDC WIF to push images to ECR"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = "accounts.google.com" }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "accounts.google.com:sub" = var.gcp_ci_sa_unique_id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "cloudbuild_ecr_push" {
  name = "ECRPushPolicy"
  role = aws_iam_role.cloudbuild_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = [for repo in aws_ecr_repository.repos : repo.arn]
      },
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      }
    ]
  })
}
