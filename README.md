# Bookwork GitOps Repository

This repository contains the GitOps configuration for the Bookwork application, implementing a complete continuous deployment pipeline using ArgoCD on Kubernetes.

## 🏗️ Architecture Overview

The Bookwork application follows a microservices architecture with the following components:

- **Frontend**: Web application served via NGINX
- **API**: Backend service (currently disabled to avoid database costs)
- **Infrastructure**: Shared resources including ingress, SSL certificates, and namespace management

## 📁 Repository Structure

```
├── apps/                           # ArgoCD Application definitions
│   ├── app-of-apps/
│   │   └── bookwork-apps.yaml     # Root application managing all sub-applications
│   └── bookwork/
│       ├── api.yaml               # API application configuration
│       ├── frontend.yaml          # Frontend application configuration
│       └── infrastructure.yaml   # Infrastructure application configuration
├── bootstrap/                     # ArgoCD cluster-level configuration
│   ├── argocd-cm.yaml            # ArgoCD ConfigMap with customizations
│   ├── argocd-rbac-cm.yaml       # Role-based access control
│   ├── argocd-notifications-cm.yaml # Slack notification templates
│   ├── argocd-server-ingress.yaml   # ArgoCD UI ingress configuration
│   ├── bookwork-project.yaml        # ArgoCD project definition
│   └── ...                          # Additional ArgoCD configuration files
├── tenants/bookwork/base/         # Application manifests
│   ├── kustomization.yaml         # Main Kustomize configuration
│   └── components/
│       ├── api/                   # API service resources
│       ├── frontend/              # Frontend service resources
│       └── infrastructure/       # Shared infrastructure resources
└── clusters/                     # Environment-specific configurations
    ├── base/                     # Base cluster configuration (empty)
    └── overlays/production/      # Production environment overrides (empty)
```

## 🚀 Deployment Strategy

### App of Apps Pattern
This repository implements the "App of Apps" pattern where:
1. **Root Application** (`bookwork-apps`) manages all child applications
2. **Child Applications** manage specific components (API, Frontend, Infrastructure)

### Sync Waves
Deployment order is controlled using ArgoCD sync waves:
- **Wave 0**: Infrastructure (namespace, SSL issuer, secrets)
- **Wave 1**: Services and ingress
- **Wave 2**: Application deployments

### Automated Sync Policy
- **Frontend**: Fully automated with auto-prune and self-heal
- **API**: Manual sync for production control (auto-prune disabled)
- **Infrastructure**: Fully automated with namespace creation

## 🔧 Configuration Details

### Container Images
Images are managed through Google Cloud Artifact Registry:
- **Frontend**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-frontend:678c345`
- **API**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-api:6fb3352`

### Domain Configuration
- **Application**: `bookwork-demo.com` and `www.bookwork-demo.com`
- **ArgoCD UI**: `argocd.bookwork-demo.com`

### SSL/TLS
- Automated certificate management via Cert-Manager
- Let's Encrypt ACME v2 certificates
- HTTP01 challenge solver with NGINX ingress

### Security Features
- **Sealed Secrets**: Encrypted secret management for API credentials
- **RBAC**: Role-based access control with GitHub OAuth integration
- **Project Restrictions**: Limited source repositories and deployment destinations
- **Sync Windows**: Deployment restrictions during business hours (9 AM - 5 PM, Mon-Fri, America/Chicago)

## 🔔 Monitoring & Notifications

### Slack Integration
Comprehensive Slack notifications for:
- ✅ Application creation and restoration
- 🚨 Sync failures and health degradation
- ⚠️ Out-of-sync applications
- 🗑️ Application deletion

### Resource Exclusions
ArgoCD is configured to ignore noisy Kubernetes resources:
- Network endpoints and endpoint slices
- Coordination leases
- Authentication/authorization reviews
- Certificate requests
- Cilium internal resources
- Kyverno policy reports

## 🚦 Current Status

### Active Components
- ✅ **Frontend**: Deployed and running (2 replicas)
- ✅ **Infrastructure**: Namespace, ingress, and SSL configured
- ✅ **ArgoCD**: Fully configured with GitHub OAuth and notifications

### Disabled Components
- ❌ **API**: Currently disabled to avoid database costs
  - Deployment and service manifests are commented out
  - Only sealed secrets are deployed

## 🛠️ Getting Started

### Prerequisites
- Kubernetes cluster with NGINX Ingress Controller
- ArgoCD installed and configured
- Cert-Manager for SSL certificate management
- Sealed Secrets controller

### Initial Setup
1. Apply ArgoCD bootstrap configuration:
   ```bash
   kubectl apply -f bootstrap/
   ```

2. Deploy the root application:
   ```bash
   kubectl apply -f apps/app-of-apps/bookwork-apps.yaml
   ```

### Enabling API Component
To enable the API component:
1. Uncomment deployment and service resources in `tenants/bookwork/base/components/api/kustomization.yaml`
2. Ensure database is available and configured
3. Commit changes to trigger ArgoCD sync

## 🔐 Access Control

### GitHub OAuth Integration
- **Client ID**: `Ov23likhDtqBQD2g46ax`
- **Callback URL**: `https://argocd.bookwork-demo.com/api/dex/callback`

### User Roles
- **Admin Access**: `hazyView`, `flmarin86@gmail.com`, user ID `200641523`
- **Default Access**: Read-only for all authenticated users

## 📊 Project Governance

### AppProject Configuration
- **Source Restrictions**: Limited to this GitOps repository
- **Destination Restrictions**: Specific namespaces (bookwork, argocd, ingress-nginx, cert-manager)
- **Resource Whitelist**: Controlled resource types for security
- **Sync Windows**: Business hours deployment restrictions

## 🚨 Troubleshooting

### Common Issues
1. **Sync Failures**: Check ArgoCD UI and Slack notifications
2. **SSL Certificate Issues**: Verify Cert-Manager logs and DNS configuration
3. **Access Denied**: Ensure proper RBAC configuration and GitHub team membership

### Monitoring Resources
- ArgoCD UI: `https://argocd.bookwork-demo.com`
- Application: `https://bookwork-demo.com`
- Slack notifications: Channel `C0958PSUQ74`

## 📝 Maintenance

### Updating Container Images
Images are updated via Kustomize image transformations. Update the `newTag` values in:
- `tenants/bookwork/base/kustomization.yaml` (main configuration)
- Component-specific `kustomization.yaml` files

### Configuration Changes
All configuration changes should be made via Git commits to this repository. ArgoCD will automatically detect and sync changes based on the configured sync policies.

---

**Repository**: [hazyView/bookwork-gitops](https://github.com/hazyView/bookwork-gitops.git)  
**Maintainer**: Fred Marin (flmarin86@gmail.com)  
**Last Updated**: August 2025