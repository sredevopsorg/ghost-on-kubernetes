# Ghost on Kubernetes by SREDevOps.Org

[![SREDevOps.org](https://github.com/sredevopsorg/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f)](https://www.sredevops.org)

_**SREDevOps.org**: SRE, DevOps, Linux, Ethical Hacking, AI, ML, Open Source, Cloud Native, Platform Engineering en Español, Portugués (Brasil) and English_

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888) [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ghost-on-kubernetes)](https://artifacthub.io/packages/search?repo=ghost-on-kubernetes)

## Introduction

This repository implements Ghost CMS v6.xx.x from [@TryGhost (Official)](https://github.com/TryGhost/Ghost) on Kubernetes, with our custom image, which has significant improvements intended to be used on Kubernetes [(Dockerfile)](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile). See this whole README for more information.

## Features

- Both Ghost and MySQL components run as non-root user in Kubernetes, which significantly improves security, in addition to our custom image enhancements.
- Multi-arch support (amd64 and arm64).
- We use the official Node 22 Jod LTS image as our build environment. [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile#L5).
- We introduce a multi-stage build, which reduces the final image size and improves security by removing unnecessary components from the final image.
- [Distroless Node 22 Debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) as our runtime environment for the final image stage.
- The official Ghost image used gosu, but we removed it in favor of a clean and native container based executions. Now everything runs as non-root (UID/GID 65532) inside the Distroless container. This change alone reduces 6 critical vulnerabilities and 34 high vulnerabilities reported by Docker Scout in the original Ghost image. References:

  - Example scan for the [Ghost Official Image](https://hub.docker.com/_/ghost/tags)

    ![Docker Scout Report - Ghost Official Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ghost.png)

  - Example of our [Ghost on Kubernetes Image on Docker Hub](https://hub.docker.com/r/ngeorger/ghost-on-kubernetes/tags)

    ![Docker Scout Report - Ghost on Kubernetes Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ngeorger.png)

- New Entrypoint flow, using a Node.js script executed by the unprivileged Node user inside the Distroless container, which updates the default themes and starts the Ghost application, an operation that is performed inside the Distroless container itself.
- We use the latest version of Ghost 6 (when the image is built).

## Recent updates and changes

We've made some significant updates to improve the security and efficiency of our Ghost implementation on Kubernetes:

- **Updated Ghost v6**: We are using the new Ghost v6, please check the [Official Docs](https://docs.ghost.org/update) for more details. 
- **Updated NodeJS version**: From Iron LTS (Node v20) into Jod LTS (Node v22)
- **Multi-arch support**: The images are now multi-arch, with support for amd64 and arm64.
- **Distroless Image**: We use [@GoogleContainerTools](https://github.com/GoogleContainerTools)'s [Distroless NodeJS](https://github.com/ogleContainerTools/distroless/blob/main/examples/nodejs/Dockerfile) as the execution environment for the final image. Distroless images e minimal images that contain only the necessary components to run the application, making them more secure and efficient than aditional images.
- **MySQL StatefulSet**: We've changed the MySQL implementation to a StatefulSet. This provides stable network identifiers and rsistent storage, which is important for databases like MySQL that need to maintain state.
- **Init Container**: We've added an init container to the Ghost deployment. This container is responsible for setting up the necessary nfiguration files and directories before the main Ghost container starts, ensuring the right directories are created, correct ownership r user node inside distroless container UID/GID to 65532, and the correct permissions are set.  Check [deploy/06-ghost-deployment.yaml]ttps://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml) for details on these changes.
- **Entrypoint Script**: We've introduced a new entrypoint script that runs as the non-privileged user inside the distroless container. is script is responsible for updating the default themes then starts the Ghost application. This script is executed by the nonroot user thout privileges within the Distroless container, which updates default themes and starts the Ghost application, operation performed to the distroless container in runtime. [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)

## Installation Instructions

### 0. Clone the repository or fork it

  ```bash
  ## Clone the repository
  git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
  ## Change directory
  cd ghost-on-kubernetes
  ## Create a new branch for your changes (optional but   recommended).
  git checkout -b my-branch --no-track --detach
  ```

### 1. Check the example configurations

- There are some example configuration files in the [examples](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/) directory. We use the stored configuration as a `kind: Secret` in the `ghost-on-kubernetes` namespace for Ghost and MySQL configuration. There are two example configuration files:
  - `config.development.sample.yaml`: This configuration file is for the Ghost development environment. It uses SQLite as the database. It can be useful if you want to test the Ghost configuration before implementing it in a production environment.
  - `config.production.sample.yaml`: This configuration file is for the Ghost production environment. It uses MySQL 8, and is the recommended configuration for production environments. It requires a valid top-level domain (TLD) and [configuration for Ingress to access Ghost from the Internet](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml).
- If you need more information on the configuration, check the [official Ghost documentation](https://ghost.org/docs/config/#custom-configuration-files).

### 2. Edit the default values and make changes as needed

Remember to edit the values according to your needs, the details for every files are provided on each manifest file inside the [deploy folder](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/) and the following steps.

### Understanding the Ghost Deployment Architecture on Kubernetes

Deploying a sophisticated application like Ghost on Kubernetes involves orchestrating several components. Let's break down the essential Kubernetes resources we'll use:

### Namespaces: Isolating Our Ghost Instance

Namespaces in Kubernetes provide a logical separation of resources. We'll use the `ghost-on-kubernetes` namespace to contain all resources related to our Ghost deployment. This approach enhances organization and prevents resource conflicts with other applications running on the same cluster.

> _*Note*: You can even host multiple Ghost instances on the same cluster by replacing the Namespace specification in each manifest file._

Full file: [deploy/00-namespace.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/00-namespace.yaml)

```yaml
# Source code example excerpt:
apiVersion: v1
kind: Namespace
metadata:
  name: ghost-on-kubernetes
  labels:
    app: ghost-on-kubernetes
    # ... other labels
```

### Secrets: Securely Storing your Ghost Configuration

Secrets in Kubernetes allow us to store and manage sensitive data, such as database credentials and TLS certificates, securely. We'll use the following Secrets:

- `ghost-config-prod`: Stores the Ghost configuration, including database connection details and mail server settings.
- `ghost-on-kubernetes-mysql-env`: Contains environment variables for the MySQL database, including the database name, username, and password.
- `tls-secret`: Holds the TLS certificate and key for enabling HTTPS on our Ghost blog.

Full file: [deploy/01-mysql-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-mysql-config.yaml)

Full file: [deploy/04-ghost-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/04-ghost-config.yaml)

Full file: [deploy/01-tls.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-tls.yaml)

```yaml
# Source code example excerpt:
apiVersion: v1
kind: Secret
metadata:
  name: ghost-config-prod
  namespace: ghost-on-kubernetes
  # ... other metadata
type: Opaque
stringData:
  config.production.json: |-
    {
      # ... Ghost configuration
    }
```

### PersistentVolumeClaims: Persistent Storage for Our Blog

PersistentVolumeClaims (PVCs) in Kubernetes enable us to request persistent storage volumes. We'll use two PVCs:

- `k8s-ghost-content`: Provides persistent storage for Ghost's content, including images, themes, and uploaded files.
- `ghost-on-kubernetes-mysql-pvc`: Offers persistent storage for the MySQL database, ensuring data persistence across pod restarts and reschedulings.

Full file: [deploy/02-pvc.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/02-pvc.yaml)

```yaml
# Source code example excerpt:
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: k8s-ghost-content
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... PVC specification
```

### Services: Exposing Ghost and MySQL Within the Cluster

Services in Kubernetes provide a way to expose our applications running on a set of pods as a network service. We'll define two services:

- `ghost-on-kubernetes-service`: Exposes the Ghost application internally within the cluster on port 2368.
- `ghost-on-kubernetes-mysql-service`: Exposes the MySQL database internally on port 3306, allowing the Ghost application to connect to the database.

Full file: [deploy/03-service.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/03-service.yaml)

```yaml
# Source code example excerpt:
apiVersion: v1
kind: Service
metadata:
  name: ghost-on-kubernetes-service
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Service specification
```

### StatefulSet: Managing the MySQL Database

A StatefulSet in Kubernetes is designed to manage stateful applications, such as databases, that require persistent storage and stable network identities. We'll use a StatefulSet to deploy a single replica of the MySQL database.

Full file: [deploy/05-mysql.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/05-mysql.yaml)

```yaml
# Source code example excerpt:
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ghost-on-kubernetes-mysql
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... StatefulSet specification
```

### Deployment: Managing the Ghost Application

Deployments in Kubernetes manage the deployment and scaling of stateless applications. We'll use a Deployment to deploy a single replica of the Ghost application.

Full file: [deploy/06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml)

```yaml
# Source code example excerpt:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost-on-kubernetes
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Deployment specification
```

### Ingress: Exposing Ghost to the Outside World

An Ingress resource in Kubernetes acts as a reverse proxy, routing external traffic to services within the cluster. We'll use an Ingress to expose our Ghost blog to the internet using a domain name.

File: [deploy/07-ingress.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml)

```yaml
# Source code example excerpt:
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghost-on-kubernetes-ingress
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Ingress specification
```

## Bringing It All Together: Deploying Ghost on Kubernetes

With our Kubernetes resources defined, we can now deploy Ghost on our cluster. Follow these general steps:

_IMPORTANT NOTE_: You need to apply those commands or deploy files in order, or you could face inconsistences on your MySQL StatefulSet and/or other components.

1. **Create the Namespace:**

   ```bash
   kubectl apply -f deploy/00-namespace.yaml
   ```

2. **Create the Secrets:**

   ```bash
   kubectl apply -f deploy/01-mysql-config.yaml
   kubectl apply -f deploy/04-ghost-config.yaml
   kubectl apply -f deploy/01-tls.yaml
   ```

3. **Create the PersistentVolumeClaims:**

   ```bash
   kubectl apply -f deploy/02-pvc.yaml
   ```

4. **Create the Services:**

   ```bash
   kubectl apply -f deploy/03-service.yaml
   ```

5. **Deploy the MySQL Database:**

   ```bash
   kubectl apply -f deploy/05-mysql.yaml
   ```

6. **Deploy the Ghost Application:**

   ```bash
   kubectl apply -f deploy/06-ghost-deployment.yaml
   ```

7. **Expose Ghost with Ingress (Optional):**

   ```bash
   kubectl apply -f deploy/07-ingress.yaml
   ```

## Your Ghost Blog is deployed! 🎉

Congratulations! You've successfully deployed Ghost on a Kubernetes cluster. This setup provides a robust and scalable foundation for your blogging platform. Remember to customize the configurations, such as storage class, resource limits, and domain name, to suit your specific requirements.

## A final trick: Access Ghost on Kubernetes without a domain name

If you want to use a port forwarding to preview the website, be sure to configure both url and admin URLs in the config file as `http://localhost:2368/`, resttart the pod and then run the kubectl port-forwarding like:

  ```bash
  kubectl port-forward -n ghost-on-kubernetes services ghost-on-kubernetes-service 2368:2368
  ```

## Contributing

We welcome contributions from the community! Please check the [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md) file for more information on how to contribute to this project.

## License and Credits

- This project is licensed under the MIT License. Please check the [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE) file for more information.
- The Ghost CMS is licensed under the [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
- The node image and the Distroless image are licensed by their respective owners.

## Star History

![Star History Chart](https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark)
