# bookwork-Gitops

GitOps pipeline for the Bookwork project.

## Project Overview

This repository implements a GitOps workflow for deploying and managing the Bookwork application on Kubernetes using ArgoCD and Kustomize. It provides a declarative, version-controlled approach to infrastructure and application delivery, including namespace management, ingress, TLS certificates, and frontend deployment.

## Directory and File Structure

- **apps/bookwork-app.yaml**  
  Defines an ArgoCD `Application` resource that points to the main Kustomize base for the Bookwork tenant. It configures automated sync, namespace creation, and server-side apply.

- **tenants/bookwork/base/**  
  The main Kustomize base for the Bookwork tenant, containing all Kubernetes manifests and Kustomize configuration:
  - `kustomization.yaml`:  
    Aggregates all resources for deployment, including namespace, ingress, certificate issuer, and frontend.
  - `namespace.yaml`:  
    Declares the `bookwork` Kubernetes namespace.
  - `ingress.yaml`:  
    Configures an NGINX Ingress for the Bookwork frontend, with TLS via cert-manager and Let's Encrypt.
  - `letsencrypt-issuer.yaml`:  
    Defines a cert-manager `ClusterIssuer` for Let's Encrypt, using HTTP01 challenge with NGINX.
  - `frontend/`
    - `deployment.yaml`:  
      Deploys the Bookwork frontend as a Kubernetes Deployment, with image and replica configuration.
    - `service.yaml`:  
      Exposes the frontend Deployment as a Kubernetes Service on port 80.
  - `api/`:  
    (Currently empty, reserved for future backend/API manifests.)

- **clusters/base/**  
  (Currently empty, reserved for future cluster-wide base configurations.)

- **clusters/overlays/production/**  
  (Currently empty, intended for production-specific overlays.)

- **bootstrap/**  
  (Currently empty, reserved for future bootstrap resources.)

## How it Works

1. **ArgoCD** watches this repository and applies the manifests defined in `apps/bookwork-app.yaml`.
2. **Kustomize** composes the resources in `tenants/bookwork/base/` for deployment.
3. **Cert-Manager** provisions TLS certificates using Let's Encrypt for secure ingress.
4. **NGINX Ingress** exposes the frontend application to the internet.
5. **Namespace and Service** resources ensure isolation and network access for the Bookwork frontend.

## Extending the Project

- Add backend/API manifests to `tenants/bookwork/base/api/`.
- Add production-specific overlays in `clusters/overlays/production/`.
- Add cluster-wide resources in `clusters/base/`.
- Use the `bootstrap/` directory for initial cluster setup if needed.
