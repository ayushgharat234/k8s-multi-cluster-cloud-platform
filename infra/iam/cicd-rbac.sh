#!/usr/bin/env bash
# CI/CD RBAC Setup — OpsNexus
# Run once from Cloud Shell as project owner.
# Personas: ci-sa (automated), deploy-sa (automated), devops (human), developer (human), release-manager (human)

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dotted-saga-493511-a1}"
REGION="us-central1"

CI_SA="opsnexus-ci-sa@${PROJECT_ID}.iam.gserviceaccount.com"
DEPLOY_SA="opsnexus-deploy-sa@${PROJECT_ID}.iam.gserviceaccount.com"

# ── Create Deploy SA (separate from CI SA) ────────────────────────────────────
gcloud iam service-accounts create opsnexus-deploy-sa \
  --display-name="OpsNexus Cloud Deploy Executor" \
  --project="${PROJECT_ID}" 2>/dev/null || echo "deploy-sa already exists"

# ── CI SA — Cloud Build: build, scan, attest, create releases ────────────────
CI_ROLES=(
  roles/artifactregistry.writer          # push images
  roles/ondemandscanning.admin           # pre-push vulnerability scan
  roles/containeranalysis.occurrences.editor  # write scan results
  roles/cloudkms.signerVerifier          # sign attestations
  roles/binaryauthorization.attestorsViewer   # read attestor config
  roles/clouddeploy.releaser             # create releases only (not manage pipelines)
  roles/logging.logWriter                # write build logs
  roles/storage.objectAdmin              # Cloud Deploy source bucket
)

for ROLE in "${CI_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${CI_SA}" \
    --role="${ROLE}" --condition=None
  echo "  CI SA ← ${ROLE}"
done

# ── Deploy SA — Cloud Deploy executor: deploy to GKE/EKS ─────────────────────
DEPLOY_ROLES=(
  roles/container.developer              # apply manifests to GKE
  roles/iam.serviceAccountUser           # act as workload identity SAs
  roles/logging.logWriter
  roles/storage.objectViewer             # read release source
)

for ROLE in "${DEPLOY_ROLES[@]}"; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member="serviceAccount:${DEPLOY_SA}" \
    --role="${ROLE}" --condition=None
  echo "  Deploy SA ← ${ROLE}"
done

# Allow Cloud Deploy service agent to act as deploy SA
DEPLOY_AGENT="serviceAccount:service-$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')@gcp-sa-clouddeploy.iam.gserviceaccount.com"
gcloud iam service-accounts add-iam-policy-binding "${DEPLOY_SA}" \
  --member="${DEPLOY_AGENT}" \
  --role="roles/iam.serviceAccountTokenCreator"

# ── Human Roles ───────────────────────────────────────────────────────────────
# Usage: set DEVOPS_EMAIL, DEVELOPER_EMAIL, RELEASE_MANAGER_EMAIL before running.

# DevOps Engineer — full CI/CD visibility + trigger builds manually
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${DEVOPS_EMAIL}" \
#   --role="roles/cloudbuild.builds.editor"
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${DEVOPS_EMAIL}" \
#   --role="roles/clouddeploy.operator"
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${DEVOPS_EMAIL}" \
#   --role="roles/artifactregistry.reader"

# Developer — read-only on builds and deployments
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${DEVELOPER_EMAIL}" \
#   --role="roles/cloudbuild.builds.viewer"
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${DEVELOPER_EMAIL}" \
#   --role="roles/clouddeploy.viewer"

# Release Manager — can approve canary → stable promotion
# gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
#   --member="user:${RELEASE_MANAGER_EMAIL}" \
#   --role="roles/clouddeploy.approver"

echo ""
echo "RBAC setup complete."
echo "Uncomment human role blocks above and set email vars to assign team roles."
