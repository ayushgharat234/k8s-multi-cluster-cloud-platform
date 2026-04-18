#!/usr/bin/env bash
# Bootstrap EKS spoke cluster with ECR image for catalog service.
# Run once after cluster creation and ECR repository setup.
# Requires: aws, kubectl, cluster context set to opsnexus-eks-spoke.
# The catalog image must already be mirrored to ECR (run CI pipeline first).

set -euo pipefail

AWS_ACCOUNT="262270938572"
AWS_REGION="us-east-1"
ECR_REGISTRY="${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_REPO="${ECR_REGISTRY}/opsnexus/storefront-catalog"
NAMESPACE="nexus-app"

echo "==> Ensuring ECR repository exists..."
aws ecr describe-repositories \
  --repository-names "opsnexus/storefront-catalog" \
  --region "${AWS_REGION}" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name "opsnexus/storefront-catalog" \
  --region "${AWS_REGION}" \
  --image-scanning-configuration scanOnPush=true \
  --encryption-configuration encryptionType=AES256

echo "==> Fetching latest catalog image digest from ECR..."
CATALOG_DIGEST=$(aws ecr describe-images \
  --repository-name "opsnexus/storefront-catalog" \
  --region "${AWS_REGION}" \
  --query 'sort_by(imageDetails, &imagePushedAt)[-1].imageDigest' \
  --output text 2>/dev/null)

if [[ -z "${CATALOG_DIGEST}" || "${CATALOG_DIGEST}" == "None" ]]; then
  echo "ERROR: No images found in ECR. Run the catalog CI pipeline first."
  echo "       The pipeline builds, scans, attests, and mirrors the image to ECR."
  exit 1
fi

echo "  storefront-catalog: ${CATALOG_DIGEST}"

echo "==> Applying baseline manifests..."
kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || \
  kubectl create namespace "${NAMESPACE}"

kubectl apply -f apps/storefront/catalog/kubernetes.yaml

echo "==> Patching deployment with ECR digest reference..."
kubectl set image deployment/storefront-catalog \
  catalog="${ECR_REPO}@${CATALOG_DIGEST}" \
  -n "${NAMESPACE}"

echo "==> Waiting for rollout to complete..."
kubectl rollout status deployment/storefront-catalog -n "${NAMESPACE}" --timeout=120s

echo ""
echo "Bootstrap complete. EKS baseline deployment running with ECR image."
echo "Cloud Deploy canary (25→75→100%) can now proceed."
kubectl get pods -n "${NAMESPACE}"
