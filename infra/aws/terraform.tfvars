region       = "us-east-1"
env_name     = "opsnexus"
cluster_name = "opsnexus-eks-spoke"
vpc_cidr     = "172.16.0.0/16"

github_repo       = "ayushgharat234/k8s-multi-cluster-cloud-platform"
github_thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"

# Get this with: gcloud iam service-accounts describe opsnexus-ci-sa@dotted-saga-493511-a1.iam.gserviceaccount.com --format="value(uniqueId)"
gcp_ci_sa_unique_id = "REPLACE_WITH_UNIQUE_ID"
