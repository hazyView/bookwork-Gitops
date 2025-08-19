# Bookwork GitOps Repository

This repository contains the GitOps configuration for the Bookwork application, delivered as ArgoCD Applications and Kustomize manifests. It is intended to boot, configure, and continuously deploy the Bookwork tenant into a Kubernetes cluster using an App-of-Apps pattern.

---

## Repository layout (top-level)

```text
Repository root
├─ bootstrap/                 # ArgoCD bootstrapping (ConfigMaps, RBAC, secrets, ingress)
├─ apps/                      # ArgoCD Application CRs
│  ├─ app-of-apps/            # Root App-of-Apps (points at tenants/bookwork/base)
│  └─ bookwork/               # Per-component Applications (infrastructure, frontend, api)
├─ tenants/bookwork/base/     # Kustomize tenant layer (components + kustomization)
│  ├─ components/
│  │  ├─ infrastructure/      # namespace, ingress, letsencrypt issuer (wave 0)
│  │  ├─ frontend/            # Deployment + Service (wave 10)
│  │  ├─ api/                 # SealedSecret (deployment/service commented out, wave 20)
│  │  └─ observability/       # Prometheus, Grafana, Alertmanager, dashboards
│  └─ kustomization.yaml      # image tags + component references
├─ grafana-github-oauth-sealed.yaml  # Optional top-level SealedSecret for Grafana OAuth
└─ clusters/                  # Cluster overlays (minimal/empty)
```

---

## Components and current operational status

- Frontend
  - Location: `tenants/bookwork/base/components/frontend`
  - Kustomize: exposes a Deployment and Service
  - ArgoCD App: `apps/bookwork/frontend.yaml`
  - Sync policy: automated with prune and self-heal
  - Image configured via kustomize (image tag present in `tenants/bookwork/base` and component kustomization)

- Infrastructure
  - Location: `tenants/bookwork/base/components/infrastructure`
  - Includes: Namespace, Ingress, Let's Encrypt Issuer
  - ArgoCD App: `apps/bookwork/infrastructure.yaml`
  - Sync policy: automated, CreateNamespace enabled

- API (backend)
  - Location: `tenants/bookwork/base/components/api`
  - Current state: Deployment and Service are commented out in the component kustomization and tenant kustomization to avoid database costs; only the SealedSecret is applied by default
  - ArgoCD App: `apps/bookwork/api.yaml`
  - Sync policy: automated with self-heal but `prune: false` (manual control intended)
  - To enable: uncomment `deployment.yaml` and `service.yaml` in `tenants/bookwork/base/components/api/kustomization.yaml` (and the tenant-level overrides if applicable)

- Observability
  - Location: `tenants/bookwork/base/components/observability`
  - Includes Prometheus, Grafana, Alertmanager, dashboard resources, ServiceMonitors, and sealed secrets
  - Grafana GitHub OAuth config exists as a SealedSecret in `tenants/.../grafana/graf-sealed-secret.yaml` and at repo root as `grafana-github-oauth-sealed.yaml`

---

## ArgoCD / App-of-Apps configuration

- Root Application: `apps/app-of-apps/bookwork-apps.yaml`
  - Points to `tenants/bookwork/base`
  - Automated sync with `prune: true` and `selfHeal: true`
  - `CreateNamespace=true` set on syncOptions to ensure `bookwork` namespace is created if missing
- Per-component sync waves (declared via Application `info` entries):
  - Infrastructure: Wave 0
  - Frontend: Wave 10
  - API: Wave 20
- Notifications
  - Slack channel ID used across Application manifests: `C0958PSUQ74` (ArgoCD Notifications annotations present)
- Dex / GitHub OAuth
  - `bootstrap/argocd-cm.yaml` configures Dex GitHub connector
  - Client ID appears in `bootstrap/argocd-cm.yaml` and the client secret is stored in `bootstrap/argocd-github-oauth-secret.yaml` (base64-encoded)

---

## Image management

Images are managed with Kustomize image transformations. The tenant kustomization contains entries for:
- `bookwork-frontend` image (tag present in `tenants/bookwork/base/kustomization.yaml`)
- `bookwork-api` image (tag present but API deployment is currently commented out)

When updating images, update the `newTag` values in the relevant `kustomization.yaml` files and commit.

---

## Prerequisites for cluster and deployment

- Kubernetes cluster (tested with a standard managed or upstream cluster)
- NGINX Ingress Controller (Ingress manifests assume NGINX)
- Cert-Manager (for Let's Encrypt issuer and Certificate resources)
- ArgoCD installed in the cluster
- Sealed Secrets controller (Bitnami SealedSecrets) to decrypt/apply sealed secrets

---

## Quick bootstrap and deployment steps

1. Install required controllers on the cluster if not already present: NGINX Ingress, Cert-Manager, SealedSecrets, ArgoCD.
2. Apply ArgoCD bootstrap resources (config, RBAC, secrets, ingress):

   kubectl apply -f bootstrap/

3. Create the root App-of-Apps (alternatively you can apply the single Application CRs in `apps/`):

   kubectl apply -f apps/app-of-apps/bookwork-apps.yaml

4. Monitor ArgoCD UI (configured URL in `argocd-cm.yaml`) and the Applications created under the `bookwork` project.

Notes:
- The API Application is intentionally conservative: it is set to `prune: false` so you retain manual control over rollouts when you enable it.

---

## How to enable the API component

1. Edit `tenants/bookwork/base/components/api/kustomization.yaml` and remove the comment markers for `deployment.yaml` and `service.yaml` (they are intentionally commented out).
2. Ensure any required backing services (database) are available and configured.
3. Commit the change and allow ArgoCD to sync the tenant or manually sync the `bookwork-api` Application if it exists.

---

## Security and secrets

- SealedSecrets are used to keep sensitive data encrypted in the repository. The repository contains sealed secrets for Grafana and other observability/auth components.
- The ArgoCD GitHub OAuth client secret is stored in `bootstrap/argocd-github-oauth-secret.yaml` as a Kubernetes Secret (base64-encoded string). Treat that file accordingly and rotate credentials as needed.

---

## Maintainers

- Repository: hazyView/bookwork-gitops
- Maintainer: Fred Lopez

Last Updated: 2025-08-19