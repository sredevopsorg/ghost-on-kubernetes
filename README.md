# Ghost on Kubernetes by [SREDevOps](https://sredevops.org)

[![Build and push image to DockerHub and GitHub Container Registry](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml/badge.svg)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml)

This repo deploys a clean Ghost CMS v5.xx.x from [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) in Kubernetes, as a Deployment using our [custom image](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile) built based on the ["official" Ghost 5 debian image](https://github.com/docker-library/ghost/blob/master/5/debian/Dockerfile), but with some modifications:

## Recent Changes

We've made some significant updates to improve the security and efficiency of our Ghost deployment on Kubernetes:

1. **Distroless Base Image**: The Ghost container image is now based on a Distroless base image. This reduces the attack surface by eliminating unnecessary components like shell, package managers, and utilities that aren't needed for our application to run. The image is also built using a multi-stage build process, which makes the final image smaller and more secure.

2. **MySQL StatefulSet**: We've changed the MySQL deployment back to a StatefulSet. This provides stable network identifiers and persistent storage, which are important for databases like MySQL that need to maintain state.

3. **Non-Root User**: By default, the Ghost container now runs as a non-root user. This is a best practice for security, as it reduces the potential damage if the container is compromised. The Ghost application is started with an init container, which performs necessary setup tasks before the main Ghost container starts.

Please refer to the updated `[deploy/06-ghost-deployment.yaml](deploy/06-ghost-deployment.yaml)` file for the implementation details of these changes.

## Features

- We use the official Node 18 Hydrogen bookworm slim image as build environment.
- Introduced a multi-stage build to compile the image.
- [distroless node 18 debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) as the final image.
- Removed gosu, we use the default user node.
- ~~Modified the entrypoint to run as node user, so we can run the pod as non-root.~~ DELETED ENTRYPOINT
- Update every possible dependencies in the base image to minimize vulnerabilities.
- We update npm and ghost-cli to the latest versions on every build.
- We use the latest version of Ghost 5 (at the time of build the image)

> *Note for ARM users 📌: At this time, we dropped support for arm64 and armv7l [(link to discussion)](https://github.com/sredevopsorg/ghost-on-kubernetes/issues/73#issuecomment-1933939315), but we will add it back soon. Pull requests are welcome._* 

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" />
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" height="300px" />
</picture>

## Installation

## 1. Clone the repository

```bash
# Clone the repository
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Change directory
cd ghost-on-kubernetes
# Create a new branch for your changes in deattach mode (optional but recommended).
git checkout -b my-branch --no-track --detach

```

## 2. Review the default values and make changes as per your requirements, if any into the following files

- deploy/00-namespace.yaml

- deploy/01-secrets.yaml

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysql-ghost-k8s
      namespace: ghost-k8s
    type: Opaque
    stringData:
      MYSQL_DATABASE: mysql-db-name # Same as in deploy/04-config.production.yaml
      MYSQL_USER: mysql-db-user # Same as in deploy/04-config.production.yaml
      MYSQL_PASSWORD: mysql-db-password # Same as in deploy/04-config.production.yaml
      MYSQL_ROOT_PASSWORD: mysql-db-root-password # Same as in deploy/04-config.production.yaml
    ```

- deploy/02-pvc.yaml # Change the storageClassName as per your requirements
- deploy/03-services.yaml # Change the hosts as per your requirements
- deploy/04-config.production.yaml # Change values according to secrets and services
- deploy/05-mysql.yaml # Change values according to secrets and services
- deploy/06-ghost-deployment.yaml # Change values according to secrets and services
- deploy/07-ingress.yaml # Optional

## 3. Apply your manifests

```bash
# Create the namespace
kubectl apply -f deploy/00-namespace.yaml
# Create the secrets
kubectl apply -f deploy/01-secrets.yaml
# Create the persistent volume
kubectl apply -f deploy/02-pvc.yaml
# Create services
kubectl apply -f deploy/03-service.yaml
# Create Ghost config
kubectl apply -f deploy/04-config.production.yaml
# Create the MySQL database
kubectl apply -f deploy/05-mysql.yaml
# Create the Ghost deployment
kubectl apply -f deploy/06-ghost-deployment.yaml
# Create the Ghost Ingrees
kubectl apply -f deploy/07-ghost-ingress.yaml
```

## 4. Access your Ghost CMS

```bash
# Get the ingress IP address
kubectl get ing -n ghost-k8s -o wide 

# Or create a port-forward to access the Ghost CMS
kubectl port-forward -n ghost-k8s svc/ghost-k8s 2368:2368

```

## 5. Open your browser and access the Ghost CMS

[http://localhost:2368](http://localhost:2368)

## 6. Login to your Ghost CMS

[http://localhost:2368/ghost](http://localhost:2368/ghost)
