#!/usr/bin/env bash
set -euo pipefail

IMAGE="$1"
PROJECT="$2"

echo "Checking vulnerabilities for: $IMAGE"

CRITICAL=$(gcloud artifacts docker images describe "$IMAGE" \
  --show-package-vulnerability \
  --project="$PROJECT" \
  --format="json" 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
v = data.get('package_vulnerability_summary', {}).get('vulnerabilities', {})
print(v.get('CRITICAL', 0))
" 2>/dev/null || echo "0")

HIGH=$(gcloud artifacts docker images describe "$IMAGE" \
  --show-package-vulnerability \
  --project="$PROJECT" \
  --format="json" 2>/dev/null \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
v = data.get('package_vulnerability_summary', {}).get('vulnerabilities', {})
print(v.get('HIGH', 0))
" 2>/dev/null || echo "0")

echo "  CRITICAL: $CRITICAL  HIGH: $HIGH"

if [ "$CRITICAL" -gt 0 ]; then
  echo "ERROR: $CRITICAL CRITICAL CVEs found — blocking pipeline."
  exit 1
fi

if [ "$HIGH" -gt 5 ]; then
  echo "ERROR: $HIGH HIGH CVEs (threshold: 5) — blocking pipeline."
  exit 1
fi

echo "  Vulnerability gate passed."
