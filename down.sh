#!/usr/bin/env bash
# Removes everything so the EC2 instance stops costing money.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
terraform -chdir="$ROOT/terraform" destroy -auto-approve
rm -f "$ROOT/kubeconfig.yaml"
echo "Environment destroyed."
