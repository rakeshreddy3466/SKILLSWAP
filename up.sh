#!/usr/bin/env bash
# Creates the whole environment with one command and prints how long it took:
#   EC2 node (Terraform) -> k3s -> kubeconfig -> SkillSwap (Helm)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KUBECONFIG_FILE="$ROOT/kubeconfig.yaml"
IMAGE_OWNER="${IMAGE_OWNER:-rakeshreddy3466}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR"

SECONDS=0

echo "==> 1/4 Creating infrastructure with Terraform"
terraform -chdir="$ROOT/terraform" init -input=false >/dev/null
terraform -chdir="$ROOT/terraform" apply -auto-approve -input=false
IP="$(terraform -chdir="$ROOT/terraform" output -raw public_ip)"
echo "    Node IP: $IP"

echo "==> 2/4 Waiting for k3s to finish installing"
until ssh $SSH_OPTS "ubuntu@$IP" "test -f /etc/rancher/k3s/k3s.yaml" 2>/dev/null; do
  sleep 5
done

echo "==> 3/4 Fetching kubeconfig"
ssh $SSH_OPTS "ubuntu@$IP" "cat /etc/rancher/k3s/k3s.yaml" \
  | sed "s/127.0.0.1/$IP/" > "$KUBECONFIG_FILE"
chmod 600 "$KUBECONFIG_FILE"
export KUBECONFIG="$KUBECONFIG_FILE"
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do
  sleep 3
done

echo "==> 4/4 Installing SkillSwap with Helm"
helm upgrade --install skillswap "$ROOT/helm/skillswap" \
  --set imageOwner="$IMAGE_OWNER" \
  --wait --timeout 5m

echo ""
echo "Done in $((SECONDS / 60)) min $((SECONDS % 60)) s"
echo "App:        http://$IP"
echo "kubectl:    export KUBECONFIG=$KUBECONFIG_FILE"
