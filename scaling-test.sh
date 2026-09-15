#!/usr/bin/env bash
# Switches the cluster between the broken and the fixed Socket.io setup.
#   ./scripts/scaling-test.sh broken   3 replicas, no Redis adapter, no sticky sessions
#   ./scripts/scaling-test.sh fixed    3 replicas, Redis adapter and sticky sessions
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-$ROOT/kubeconfig.yaml}"
IMAGE_OWNER="${IMAGE_OWNER:-rakeshreddy3466}"

case "${1:-}" in
  broken) REDIS=false; STICKY=false ;;
  fixed)  REDIS=true;  STICKY=true  ;;
  *) echo "Usage: $0 broken|fixed"; exit 1 ;;
esac

helm upgrade --install skillswap "$ROOT/helm/skillswap" \
  --set imageOwner="$IMAGE_OWNER" \
  --set server.replicaCount=3 \
  --set redis.enabled=$REDIS \
  --set server.stickySessions=$STICKY \
  --wait

kubectl rollout restart deployment/skillswap-server
kubectl rollout status deployment/skillswap-server
echo ""
echo "Mode: $1. Open the app in two different browsers and chat."
echo "Hitting /api/health a few times to see requests spread across pods:"
IP="$(terraform -chdir="$ROOT/terraform" output -raw public_ip)"
for i in 1 2 3 4 5 6; do curl -s "http://$IP/api/health"; echo; done
