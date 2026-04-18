#!/usr/bin/env bash
# Set up Workload Identity Federation: Cloud Build SA → AWS IAM Role
# This eliminates static AWS credentials from Cloud Build pipelines.
#
# Architecture:
#   Cloud Build (opsnexus-ci-sa) → GCP OIDC token
#   → AWS STS AssumeRoleWithWebIdentity
#   → AWS Role (opsnexus-cloudbuild-ecr-role)
#   → ECR push permissions
#
# Run this ONCE from a workstation with both gcloud and aws admin access.

set -euo pipefail

GCP_PROJECT="dotted-saga-493511-a1"
GCP_SA="opsnexus-ci-sa@${GCP_PROJECT}.iam.gserviceaccount.com"
AWS_ACCOUNT="262270938572"
AWS_REGION="us-east-1"
POOL_ID="cloudbuild-aws-pool"
PROVIDER_ID="cloudbuild-provider"
AWS_ROLE_NAME="opsnexus-cloudbuild-ecr-role"

echo "=== Step 1: Create GCP Workload Identity Pool ==="
gcloud iam workload-identity-pools create "${POOL_ID}" \
  --project="${GCP_PROJECT}" \
  --location=global \
  --display-name="Cloud Build → AWS Federation" \
  --description="Allows Cloud Build SA to assume AWS IAM roles via OIDC"

POOL_RESOURCE=$(gcloud iam workload-identity-pools describe "${POOL_ID}" \
  --project="${GCP_PROJECT}" --location=global \
  --format="value(name)")

echo "Pool: ${POOL_RESOURCE}"

echo "=== Step 2: Create OIDC Provider in Pool ==="
gcloud iam workload-identity-pools providers create-oidc "${PROVIDER_ID}" \
  --project="${GCP_PROJECT}" \
  --location=global \
  --workload-identity-pool="${POOL_ID}" \
  --issuer-uri="https://accounts.google.com" \
  --allowed-audiences="https://iam.googleapis.com/projects/$(gcloud projects describe ${GCP_PROJECT} --format='value(projectNumber)')/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}" \
  --attribute-mapping="google.subject=assertion.sub,attribute.sa_email=assertion.email" \
  --attribute-condition="attribute.sa_email == '${GCP_SA}'"

echo "=== Step 3: Create AWS IAM Trust Policy ==="
GCP_PROJECT_NUMBER=$(gcloud projects describe "${GCP_PROJECT}" --format="value(projectNumber)")
PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT}:oidc-provider/accounts.google.com"

# AWS trust policy — trusts GCP WI Pool OIDC tokens from the CI SA
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:sub": "$(gcloud iam service-accounts describe ${GCP_SA} --format='value(uniqueId)')"
        }
      }
    }
  ]
}
EOF

echo "=== Step 4: Create AWS IAM Role with ECR Push Permission ==="
aws iam create-role \
  --role-name "${AWS_ROLE_NAME}" \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  --description "Assumed by GCP Cloud Build CI SA to push images to ECR" \
  --region "${AWS_REGION}"

# ECR push policy
cat > /tmp/ecr-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository"
      ],
      "Resource": "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT}:repository/opsnexus/*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "${AWS_ROLE_NAME}" \
  --policy-name "ECRPushPolicy" \
  --policy-document file:///tmp/ecr-policy.json

AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT}:role/${AWS_ROLE_NAME}"
echo ""
echo "=== Step 5: Store AWS Role ARN in Secret Manager (for Cloud Build) ==="
echo "${AWS_ROLE_ARN}" | gcloud secrets create aws-ecr-role-arn \
  --project="${GCP_PROJECT}" \
  --data-file=-

# Grant CI SA access to secret
gcloud secrets add-iam-policy-binding aws-ecr-role-arn \
  --project="${GCP_PROJECT}" \
  --member="serviceAccount:${GCP_SA}" \
  --role="roles/secretmanager.secretAccessor"

echo ""
echo "=== Federation setup complete ==="
echo ""
echo "AWS Role ARN: ${AWS_ROLE_ARN}"
echo "Secret:       aws-ecr-role-arn (in ${GCP_PROJECT})"
echo ""
echo "Update cicd/cloudbuild-catalog.yaml mirror-to-ecr step to use:"
echo "  gcloud auth print-identity-token --audiences=... to get OIDC token"
echo "  aws sts assume-role-with-web-identity --role-arn \$ROLE_ARN ..."
echo "  Then use returned credentials to run 'aws ecr get-login-password'"
