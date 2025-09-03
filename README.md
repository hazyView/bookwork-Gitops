# Bookwork GitOps Repository

This repository contains the GitOps configuration for the Bookwork application, delivered as ArgoCD Applications and Kustomize manifests. It follows GitOps best practices to deploy and manage the complete Bookwork platform using an App-of-Apps pattern.

---

## Repository Structure

```text
Repository root
├─ bootstrap/                           # ArgoCD bootstrapping and cluster setup
│  ├─ argocd-cm.yaml                   # ArgoCD server configuration with GitHub OAuth
│  ├─ argocd-rbac-cm.yaml              # Role-based access control
│  ├─ argocd-notifications-cm.yaml     # Slack notification configuration  
│  ├─ argocd-github-oauth-secret.yaml  # GitHub OAuth client secret
│  ├─ argocd-server-ingress.yaml       # ArgoCD web UI ingress
│  ├─ bookwork-project.yaml            # ArgoCD project definition with sync windows
│  └─ prometheus-operator-crds.yaml    # Prometheus CRDs for monitoring
├─ applications/                        # ArgoCD Application definitions
│  ├─ app-of-apps/
│  │  └─ bookwork-apps.yaml            # Root App-of-Apps pattern
│  └─ bookwork/                        # Individual component applications
│     ├─ frontend.yaml                 # Frontend application (sync wave 10)
│     ├─ api.yaml                      # API application (sync wave 20)
│     ├─ infrastructure.yaml           # Infrastructure application (sync wave 0)
│     └─ observability.yaml            # Monitoring stack application (sync wave 30)
├─ manifests/bookwork/                  # Kubernetes manifests organized by component
│  ├─ base/                            # Base application manifests
│  │  ├─ components/
│  │  │  ├─ infrastructure/            # Namespace, ingress, SSL certificates
│  │  │  ├─ frontend/                  # Frontend deployment and service
│  │  │  └─ api/                       # API deployment and service (commented)
│  │  └─ kustomization.yaml            # Base kustomization with image tags
│  └─ observability/                   # Complete monitoring stack
│     ├─ namespace.yaml                # Monitoring namespace
│     ├─ ingress.yaml                  # Monitoring ingress
│     ├─ prometheus/                   # Prometheus configuration
│     ├─ grafana/                      # Grafana with GitHub OAuth
│     └─ alertmanager/                 # Alertmanager with Slack integration
├─ debug-grafana-oauth.sh              # Grafana OAuth debugging script
├─ validate-grafana-oauth.sh           # OAuth configuration validation script
├─ GRAFANA_OAUTH_FIX.md               # Detailed OAuth troubleshooting guide
└─ grafana-github-oauth-sealed.yaml   # Legacy sealed secret (kept for reference)
```

---

## Application Components and Status

### Frontend Application ✅ Active
- **Location**: `manifests/bookwork/base/components/frontend/`
- **Components**: Deployment, Service, Kustomization
- **ArgoCD App**: `applications/bookwork/frontend.yaml`
- **Current Image**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-frontend:f6452a4`
- **Sync Policy**: Automated with prune and self-heal enabled
- **Namespace**: `bookwork` (auto-created)
- **Sync Wave**: 10
- **Status**: Deployed with 2 replicas, metrics enabled

### API Application 🚧 Disabled  
- **Location**: `manifests/bookwork/base/components/api/`
- **Components**: SealedSecret (active), Deployment/Service (commented out)
- **ArgoCD App**: `applications/bookwork/api.yaml`
- **Current Image**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-api:6fb3352`
- **Sync Policy**: Automated but `prune: false` (manual control)
- **Namespace**: `bookwork`
- **Sync Wave**: 20
- **Status**: Only secrets deployed, application components disabled to avoid database costs
- **To Enable**: Uncomment `deployment.yaml` and `service.yaml` in `kustomization.yaml`

### Infrastructure Application ✅ Active
- **Location**: `manifests/bookwork/base/components/infrastructure/`
- **Components**: Namespace, Ingress (NGINX), Let's Encrypt ClusterIssuer
- **ArgoCD App**: `applications/bookwork/infrastructure.yaml`
- **Domains**: Configured for `bookwork-demo.com` domain
- **Sync Policy**: Automated with namespace creation enabled
- **Namespace**: `bookwork`
- **Sync Wave**: 0 (foundation layer)
- **Status**: Active with SSL certificate automation

### Observability Stack ✅ Active
- **Location**: `manifests/bookwork/observability/`
- **Components**: Prometheus, Grafana, Alertmanager
- **ArgoCD App**: `applications/bookwork/observability.yaml`
- **Namespace**: `monitoring`
- **Sync Wave**: 30
- **Key Features**:
  - **Grafana**: GitHub OAuth integration, custom dashboards, team sync
  - **Prometheus**: Application and infrastructure monitoring with ServiceMonitors
  - **Alertmanager**: Slack integration for alert notifications
  - **Dashboards**: Bookwork-specific application and infrastructure dashboards
- **Access**: `https://grafana.bookwork-demo.com` and `https://prometheus.bookwork-demo.com`

---

## ArgoCD Configuration and App-of-Apps Pattern

### Application Hierarchy
- **Root Application**: `applications/app-of-apps/bookwork-apps.yaml`
  - Points to `applications/bookwork/` directory
  - Manages all component applications via App-of-Apps pattern
  - Automated sync with prune and self-heal enabled
  - Sync Wave: 5

### Sync Waves and Dependencies
Applications are deployed in order using ArgoCD sync waves:
1. **Wave 0**: Infrastructure (namespace, ingress, certificates)
2. **Wave 5**: App-of-Apps (application management)
3. **Wave 10**: Frontend application
4. **Wave 20**: API application (when enabled)
5. **Wave 30**: Observability stack

### ArgoCD Project Configuration
- **Project**: `bookwork` (`bootstrap/bookwork-project.yaml`)
- **Repository Access**: Limited to `https://github.com/hazyView/bookwork-gitops.git`
- **Namespace Access**: `bookwork`, `monitoring`, `argocd`, `ingress-nginx`, `cert-manager`, `kube-system`
- **Sync Windows**: Deployment denied during business hours (9 AM - 5 PM, Mon-Fri, America/Chicago)
- **Notifications**: Slack channel `C0958PSUQ74` for sync failures

### GitHub OAuth Integration
- **ArgoCD UI**: GitHub OAuth enabled for `argocd.bookwork-demo.com`
- **Client Configuration**: Stored in `bootstrap/argocd-github-oauth-secret.yaml`
- **Callback URL**: `https://argocd.bookwork-demo.com/api/dex/callback`

### Resource Tracking and Exclusions
- **Tracking Method**: `annotation+label` for better resource discovery
- **Resource Exclusions**: Network resources, internal K8s resources, and CI/CD artifacts excluded for performance
- **Resource Inclusions**: Default behavior (all application resources tracked)

---

## Image Management and CI/CD Integration

### Kustomize Image Management
Images are managed through Kustomize image transformations:

**Frontend Application:**
- **Base Configuration**: `manifests/bookwork/base/kustomization.yaml` (legacy reference)
- **Component Configuration**: `manifests/bookwork/base/components/frontend/kustomization.yaml`
- **Current Tag**: `f6452a4`
- **Registry**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-frontend`

**API Application:**
- **Base Configuration**: `manifests/bookwork/base/kustomization.yaml`
- **Component Configuration**: `manifests/bookwork/base/components/api/kustomization.yaml`
- **Current Tag**: `6fb3352`
- **Registry**: `us-central1-docker.pkg.dev/bookwork-466915/bookwork-registry/bookwork-api`

### CI/CD Pipeline Integration
**Note**: After repository restructuring from `tenants/` to `manifests/`, CI/CD pipelines need updates:

**Required Changes in Application Repositories:**
```bash
# Old path (needs updating)
cd gitops/tenants/bookwork/base

# New path (correct)
cd gitops/manifests/bookwork/base/components/frontend  # For frontend
cd gitops/manifests/bookwork/base/components/api       # For API
```

**Image Update Process:**
1. Application builds new image with SHA tag
2. CI/CD pipeline updates `newTag` in component kustomization.yaml
3. ArgoCD detects change and syncs new image to cluster
4. Applications automatically roll out with new image

---

## Monitoring and Observability

### Grafana Configuration
- **URL**: `https://grafana.bookwork-demo.com`
- **Authentication**: GitHub OAuth integration for user access
- **Admin Access**: Local admin account with credentials in sealed secrets
- **Role Assignment**: GitHub users automatically assigned `Viewer` role
- **Dashboards**: Pre-configured Bookwork application and infrastructure dashboards
- **Team Sync**: Automated GitHub team synchronization via CronJob

### Prometheus Setup
- **URL**: `https://prometheus.bookwork-demo.com`
- **Scraping**: Automatic discovery via ServiceMonitors
- **Targets**: Frontend application metrics, Kubernetes cluster metrics
- **Recording Rules**: Pre-aggregated metrics for dashboard performance
- **Retention**: Configured for monitoring workspace requirements

### Alertmanager Integration
- **Slack Integration**: Alert notifications to configured Slack channels
- **Alert Rules**: Frontend application health, infrastructure monitoring
- **Routing**: Different alert severities routed to appropriate channels

### Debugging and Validation Tools
**OAuth Configuration Validation:**
```bash
./validate-grafana-oauth.sh    # Comprehensive validation of OAuth setup
./debug-grafana-oauth.sh       # Active troubleshooting for OAuth issues
```

**Troubleshooting Reference:**
- See `GRAFANA_OAUTH_FIX.md` for detailed OAuth troubleshooting guide
- Contains resolution steps for common dashboard permission issues

---

## Prerequisites and Dependencies

### Required Cluster Components
- **Kubernetes Cluster**: Tested with managed K8s services (GKE, EKS, AKS)
- **NGINX Ingress Controller**: Required for ingress resources (`ingress-nginx` namespace)
- **Cert-Manager**: Automatic SSL certificate management (`cert-manager` namespace)
- **ArgoCD**: GitOps application deployment (`argocd` namespace)
- **Sealed Secrets Controller**: Bitnami SealedSecrets for encrypted secret management

### DNS Configuration
Domain `bookwork-demo.com` configured with the following subdomains:
- `argocd.bookwork-demo.com` - ArgoCD web interface
- `app.bookwork-demo.com` - Frontend application
- `grafana.bookwork-demo.com` - Grafana monitoring
- `prometheus.bookwork-demo.com` - Prometheus metrics

---

## Quick Start and Deployment

### 1. Bootstrap ArgoCD
```bash
# Apply ArgoCD configuration and RBAC
kubectl apply -f bootstrap/

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s
```

### 2. Deploy Applications via App-of-Apps
```bash
# Create the root App-of-Apps
kubectl apply -f applications/app-of-apps/bookwork-apps.yaml

# Monitor deployment progress
kubectl get applications -n argocd
```

### 3. Verify Deployment
```bash
# Check application sync status
kubectl get applications -n argocd -o wide

# Verify pods are running
kubectl get pods -n bookwork
kubectl get pods -n monitoring
```

### 4. Access Applications
- **ArgoCD**: `https://argocd.bookwork-demo.com`
- **Frontend**: `https://app.bookwork-demo.com`
- **Grafana**: `https://grafana.bookwork-demo.com`
- **Prometheus**: `https://prometheus.bookwork-demo.com`

---

## Operational Procedures

### Enabling the API Component
The API application is intentionally disabled to avoid database infrastructure costs:

1. **Ensure Database Availability**: Configure and deploy required database infrastructure
2. **Update Kustomization**: Edit `manifests/bookwork/base/components/api/kustomization.yaml`
   ```yaml
   resources:
   - sealed-secret.yaml
   - deployment.yaml    # Uncomment this line
   - service.yaml       # Uncomment this line
   ```
3. **Commit and Sync**: Commit changes and allow ArgoCD to sync, or manually sync the `bookwork-api` application

### Image Updates
**Automated via CI/CD:**
- Application repositories update image tags in kustomization files
- ArgoCD automatically detects and deploys changes

**Manual Updates:**
```bash
# Update frontend image
yq eval '.images[0].newTag = "new-tag-here"' -i manifests/bookwork/base/components/frontend/kustomization.yaml

# Update API image  
yq eval '.images[0].newTag = "new-tag-here"' -i manifests/bookwork/base/components/api/kustomization.yaml

# Commit changes
git add . && git commit -m "Update image tags" && git push
```

### Managing Sync Windows
Deployments are restricted during business hours. To override:

```bash
# Temporarily disable sync window
kubectl patch appproject bookwork -n argocd --type='json' -p='[{"op": "remove", "path": "/spec/syncWindows"}]'

# Re-enable sync window
kubectl apply -f bootstrap/bookwork-project.yaml
```

### Troubleshooting Common Issues

**Grafana OAuth Issues:**
```bash
./validate-grafana-oauth.sh    # Run validation
./debug-grafana-oauth.sh       # Debug active issues
```

**Application Sync Issues:**
```bash
# Force refresh and sync
kubectl patch application bookwork-frontend -n argocd --type='json' -p='[{"op": "replace", "path": "/metadata/annotations/argocd.argoproj.io~1refresh", "value": "hard"}]'

# Check application logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

**Resource Tracking Issues:**
- ArgoCD now uses default resource tracking (all application resources)
- No resource.inclusions restrictions configured
- Resources properly labeled with ArgoCD instance tracking

---

## Security and Secret Management

### Sealed Secrets
All sensitive data is encrypted using Bitnami Sealed Secrets:

**ArgoCD Secrets:**
- `bootstrap/argocd-github-oauth-secret.yaml` - GitHub OAuth client credentials
- `bootstrap/argocd-dex-server-secret-reader.yaml` - Dex server secret access

**Application Secrets:**
- `manifests/bookwork/base/components/api/sealed-secret.yaml` - API application secrets
- `manifests/bookwork/observability/grafana-github-oauth-sealed-secret.yaml` - Grafana OAuth
- `manifests/bookwork/observability/observability-auth-sealed-secret.yaml` - Monitoring credentials

### RBAC Configuration
**ArgoCD RBAC** (`bootstrap/argocd-rbac-cm.yaml`):
- GitHub organization-based access control
- Role-based permissions for different user groups
- Audit logging enabled

**Kubernetes RBAC**:
- Service accounts with minimal required permissions
- Namespace-scoped access where possible
- ClusterRole bindings only for required cluster-wide access

### OAuth Integration Details
**ArgoCD GitHub OAuth:**
- Client ID: `Ov23likhDtqBQD2g46ax`
- Callback URL: `https://argocd.bookwork-demo.com/api/dex/callback`

**Grafana GitHub OAuth:**
- Automatic user provisioning with Viewer role
- GitHub team synchronization for group management
- Admin access via local account for emergency access

---

## Repository Information

- **Repository**: `hazyView/bookwork-gitops`
- **Owner**: hazyView organization
- **Maintainer**: Fred Lopez
- **Branch Strategy**: Single `main` branch with direct commits
- **CI/CD Integration**: Connected to application repositories for automated image updates

### Recent Changes
- Repository restructured from `tenants/` to `manifests/` for better GitOps organization
- ArgoCD resource tracking optimized for complete application visibility
- Grafana OAuth configuration resolved for proper dashboard access
- Frontend application running with latest image tag `f6452a4`
- API application deployment controlled (disabled by default)

### Next Steps
1. Update CI/CD pipelines in application repositories to use new `manifests/` structure
2. Consider enabling API application when database infrastructure is ready
3. Monitor and optimize resource tracking and sync performance

---

**Last Updated**: September 3, 2025  
**Documentation Version**: 2.0 (Post-restructuring)