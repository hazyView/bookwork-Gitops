#!/bin/bash
# Script to properly encrypt GitHub OAuth secret for ArgoCD
# Usage: ./generate-argocd-oauth-secret.sh "your-github-oauth-client-secret"

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <github-oauth-client-secret>"
    echo "Example: $0 'your-actual-github-oauth-client-secret'"
    exit 1
fi

CLIENT_SECRET="$1"
TEMP_FILE=$(mktemp)
SEALED_SECRET_FILE="argocd-github-oauth-sealed-secret.yaml"

echo "🔐 Generating properly encrypted SealedSecret for ArgoCD GitHub OAuth..."

# Create temporary secret
kubectl create secret generic argocd-github-oauth-secret \
    --namespace=argocd \
    --from-literal=clientSecret="$CLIENT_SECRET" \
    --dry-run=client \
    -o yaml > "$TEMP_FILE"

# Encrypt with kubeseal
if ! command -v kubeseal &> /dev/null; then
    echo "❌ Error: kubeseal is not installed. Please install it first."
    echo "   macOS: brew install kubeseal"
    echo "   Or download from: https://github.com/bitnami-labs/sealed-secrets/releases"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Check if we can connect to the cluster and get the public key
if ! kubectl get ns argocd &> /dev/null; then
    echo "❌ Error: Cannot connect to cluster or 'argocd' namespace doesn't exist"
    echo "   Make sure you're connected to the correct cluster and ArgoCD is installed"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Generate the encrypted SealedSecret
cat > "$SEALED_SECRET_FILE" << 'EOF'
# GitHub OAuth SealedSecret for ArgoCD
# This SealedSecret contains the encrypted GitHub OAuth application client secret
# To update the secret:
# 1. Get the new client secret from GitHub OAuth App settings
# 2. Run: ./generate-argocd-oauth-secret.sh "your-new-secret"
# 3. Apply: kubectl apply -f bootstrap/argocd-github-oauth-sealed-secret.yaml
---
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: argocd-github-oauth-secret
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-github-oauth-secret
    app.kubernetes.io/part-of: argocd
spec:
EOF

# Encrypt and append the encrypted data
kubeseal --format=yaml < "$TEMP_FILE" | grep -A 100 "encryptedData:" >> "$SEALED_SECRET_FILE"

# Add the template section
cat >> "$SEALED_SECRET_FILE" << 'EOF'
  template:
    metadata:
      name: argocd-github-oauth-secret
      namespace: argocd
      labels:
        app.kubernetes.io/name: argocd-github-oauth-secret
        app.kubernetes.io/part-of: argocd
    type: Opaque
EOF

# Clean up
rm -f "$TEMP_FILE"

echo "✅ Successfully generated $SEALED_SECRET_FILE"
echo "🔄 Apply with: kubectl apply -f bootstrap/$SEALED_SECRET_FILE"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "   - The original plain-text secret has been replaced with encrypted SealedSecret"
echo "   - Only the cluster with the corresponding private key can decrypt this"
echo "   - Regenerate this secret if you suspect the GitHub OAuth secret is compromised"
echo "   - Consider rotating the GitHub OAuth secret regularly (every 90 days)"