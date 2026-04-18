#!/usr/bin/env bash
# Bootstrap GKE spoke cluster with BinauthZ-attested images.
# Run once after cluster creation before Cloud Deploy canary works.
# Requires: gcloud, kubectl, cluster context set to opsnexus-spoke-cluster.

set -euo pipefail

PROJECT_ID="dotted-saga-493511-a1"
DATA_PROJECT="data-493511"
REGISTRY="us-central1-docker.pkg.dev/${PROJECT_ID}/opsnexus"
NAMESPACE="nexus-app"

echo "==> Fetching latest attested digests from Artifact Registry..."

FE_DIGEST=$(gcloud artifacts docker images list \
  "${REGISTRY}/storefront-frontend" \
  --project="${PROJECT_ID}" \
  --format="value(version)" \
  --sort-by="~createTime" \
  --limit=1 2>/dev/null | grep "^sha256:")

PAY_DIGEST=$(gcloud artifacts docker images list \
  "${REGISTRY}/storefront-payment" \
  --project="${PROJECT_ID}" \
  --format="value(version)" \
  --sort-by="~createTime" \
  --limit=1 2>/dev/null | grep "^sha256:")

if [[ -z "$FE_DIGEST" || -z "$PAY_DIGEST" ]]; then
  echo "ERROR: Could not retrieve digests. Run CI pipelines first to build and attest images."
  echo "  frontend: ${FE_DIGEST:-MISSING}"
  echo "  payment:  ${PAY_DIGEST:-MISSING}"
  exit 1
fi

echo "  storefront-frontend: ${FE_DIGEST}"
echo "  storefront-payment:  ${PAY_DIGEST}"

echo "==> Verifying BinauthZ attestations exist..."
gcloud beta container binauthz attestations list \
  --attestor="opsnexus-hub-attestor" \
  --attestor-project="${PROJECT_ID}" \
  --artifact-url="${REGISTRY}/storefront-frontend@${FE_DIGEST}" \
  --project="${PROJECT_ID}" | grep -q "name:" || {
    echo "ERROR: No attestation found for storefront-frontend@${FE_DIGEST}"
    echo "       The image must pass the CI pipeline (build→scan→push→attest) before bootstrapping."
    exit 1
  }

gcloud beta container binauthz attestations list \
  --attestor="opsnexus-hub-attestor" \
  --attestor-project="${PROJECT_ID}" \
  --artifact-url="${REGISTRY}/storefront-payment@${PAY_DIGEST}" \
  --project="${PROJECT_ID}" | grep -q "name:" || {
    echo "ERROR: No attestation found for storefront-payment@${PAY_DIGEST}"
    exit 1
  }

echo "==> Attestations verified. Applying baseline manifests..."

kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1 || \
  kubectl create namespace "${NAMESPACE}"

kubectl apply -f apps/storefront/frontend/kubernetes.yaml
kubectl apply -f apps/storefront/payment/kubernetes.yaml

echo "==> Patching deployments with attested digest references..."

kubectl set image deployment/storefront-frontend \
  frontend="${REGISTRY}/storefront-frontend@${FE_DIGEST}" \
  -n "${NAMESPACE}"

kubectl set image deployment/storefront-payment \
  payment="${REGISTRY}/storefront-payment@${PAY_DIGEST}" \
  -n "${NAMESPACE}"

echo "==> Waiting for rollouts to complete..."
kubectl rollout status deployment/storefront-frontend -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/storefront-payment -n "${NAMESPACE}" --timeout=120s

echo ""
echo "Bootstrap complete. GKE baseline deployments running with attested images."
echo "Cloud Deploy canary (25→75→100%) can now proceed."
kubectl get pods -n "${NAMESPACE}"
