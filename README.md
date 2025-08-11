# bookwork-Gitops


GitOps pipeline for the Bookwork project, managing infrastructure and application delivery using ArgoCD and Kustomize.

## Project Overview


This repository implements a GitOps workflow for deploying and managing the Bookwork application on Kubernetes using ArgoCD and Kustomize. It provides a declarative, version-controlled approach to infrastructure and application delivery, including namespace management, ingress, TLS certificates, frontend, and backend (API) deployment. The repository is structured for extensibility and production-readiness, with clear separation of concerns for infrastructure, frontend, and backend components.


## Directory and File Structure

- **apps/**
  - `app-of-apps/bookwork-apps.yaml`: ArgoCD ApplicationSet for managing all Bookwork applications (infrastructure, frontend, API) as a group.
  - `bookwork/infrastructure.yaml`: ArgoCD Application for infrastructure (namespace, ingress, cert-manager issuer).
  - `bookwork/frontend.yaml`: ArgoCD Application for the frontend deployment and service.
  - `bookwork/api.yaml`: ArgoCD Application for the backend API (currently manual sync, with sealed secret for credentials).

- **tenants/bookwork/base/**
  - `kustomization.yaml`: Aggregates all Bookwork resources (infrastructure, frontend, API) for deployment.
  - **components/infrastructure/**: Namespace, ingress, and cert-manager issuer manifests, with its own kustomization.
    - `namespace.yaml`, `ingress.yaml`, `letsencrypt-issuer.yaml`, `kustomization.yaml`
  - **components/frontend/**: Frontend deployment and service, with kustomization and image tag management.
    - `deployment.yaml`, `service.yaml`, `kustomization.yaml`
  - **components/api/**: Backend API deployment, service, sealed secret, and kustomization. Deployment and service are commented out by default to avoid unnecessary costs.
    - `deployment.yaml`, `service.yaml`, `sealed-secret.yaml`, `kustomization.yaml`

- **clusters/base/**
  (Currently empty, reserved for future cluster-wide base configurations.)

- **clusters/overlays/production/**
  (Currently empty, intended for production-specific overlays.)

- **bootstrap/**
  - `argocd-cm.yaml`: ArgoCD configuration (OIDC, resource customizations, etc).
  - `argocd-notifications-cm.yaml`: Notification templates and triggers (Slack integration).
  - `argocd-rbac-cm.yaml`: RBAC configuration for ArgoCD.
  - `bookwork-project.yaml`, `notifications-rbac.yaml`: Project and notification RBAC (if present).

- **backup-bookwork-apps.yaml**
  Backup of the main ArgoCD Application resource for Bookwork (for disaster recovery or reference).


## How it Works

1. **ArgoCD** watches this repository and applies the manifests defined in the `apps/` directory, including the app-of-apps pattern for grouping related applications.
2. **Kustomize** composes the resources in `tenants/bookwork/base/` using a layered approach (infrastructure, frontend, API), with image tags managed for CI/CD.
3. **Cert-Manager** provisions TLS certificates using Let's Encrypt for secure ingress, via a ClusterIssuer and NGINX Ingress.
4. **NGINX Ingress** exposes the frontend application to the internet, with TLS and host-based routing.
5. **Namespace and Service** resources ensure isolation and network access for the Bookwork frontend and API.
6. **Sealed Secrets** are used for securely managing API credentials.
7. **Bootstrap** directory provides ArgoCD configuration, notifications, and RBAC for secure and automated operations.


## Extending the Project

- Add or enable backend/API manifests in `tenants/bookwork/base/components/api/` (uncomment in kustomization.yaml when ready).
- Add production-specific overlays in `clusters/overlays/production/`.
- Add cluster-wide resources in `clusters/base/`.
- Use the `bootstrap/` directory for initial cluster setup, ArgoCD config, notifications, and RBAC.


