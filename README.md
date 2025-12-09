# **Ghost on Kubernetes (v6.x) by SREDevOps.Org**

Deploy the leading open-source publishing platform, Ghost, on Kubernetes with maximum **security** and **efficiency** using a hardened, multi-arch container image.

Maintained by ***[SREDevOps.org](https://www.sredevops.org)**: SRE, DevOps, Linux, Ethical Hacking, AI, ML, Open Source, Cloud Native, Platform Engineering in English, Español, and Portugués (Brasil).*

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888) [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ghost-on-kubernetes)](https://artifacthub.io/packages/search?repo=ghost-on-kubernetes)

## **Key Highlights: Security & Efficiency**

This repository implements Ghost CMS v6.xx.x from [@TryGhost (Official)](https://github.com/TryGhost/Ghost) on Kubernetes with a custom built image, which delivers significant improvements for production use and security features in Kubernetes.

### **Enhanced Security**

* **Non-Root Execution:** Both the Ghost and MySQL components run exclusively as a non-root user (UID/GID 65532) in Kubernetes, preventing potential privilege escalation attacks.  
* **Distroless Runtime:** We utilize **Google Container Tools Distroless Debian 13 - NodeJS 22** as the final runtime environment. Distroless images contain only the required application and language dependencies, **excluding shells and package managers**, making them substantially more secure and reducing the attack surface.  
* **Vulnerability Reduction:** By replacing gosu with a native container execution flow and adopting Distroless, we removed several critical vulnerabilities reported in the original Ghost image:  
  * **Result:** This change alone reduced **6 critical vulnerabilities** and **34 high vulnerabilities** reported by Docker Scout in the official image.

**Example Security Reports:**

| Ghost Official Image | Ghost on Kubernetes Image |
| :---- | :---- |
| Example scan for the [Ghost Official Image](https://hub.docker.com/_/ghost/tags): ![Docker Scout Report - Ghost Official Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ghost.png) | Example of our [Ghost on Kubernetes Image on Docker Hub](https://hub.docker.com/r/ngeorger/ghost-on-kubernetes/tags): ![Docker Scout Report - Ghost on Kubernetes Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ngeorger.png) |

### **Performance & Architecture**

* **Custom Build Artifacts:** We maintain two distinct Dockerfiles for production and development:  
  * **Production Image:** The main image built using our hardened, multi-stage build process. See the [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile).  
  * **Development Image:** A variant tailored for testing, which bundles SQLite support. See the [Dockerfile-dev](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile-dev).  
* **Multi-Arch Support:** Images are built for both amd64 and arm64 architectures.  
* **Multi-Stage Build:** We use the official Node 22 Jod LTS image for building, which significantly reduces the final image size and improves security by removing unnecessary build components.  
* **Updated Ghost v6 & NodeJS 22 LTS:** Using the latest stable versions for security and performance.  
* **Robust Entrypoint (entrypoint.js):** A custom Node.js entrypoint script, executed by the unprivileged user, handles necessary runtime operations like updating default themes before starting the Ghost application. The script can be reviewed here: [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js).  
* **Dedicated Init Container:** The deployment includes an initContainer to handle directory creation, correct ownership (UID/GID 65532), and permission setting prior to the main Ghost container launch, ensuring seamless operation inside the Distroless container.

## **Deployment Architecture Overview**

This project provides complete Kubernetes manifest files (deploy/) to run a production-ready Ghost instance backed by a MySQL database.

| Resource | Components | Details |
| :---- | :---- | :---- |
| **Namespace** | ghost-on-kubernetes | Provides logical isolation for all components. (File: [00-namespace.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/00-namespace.yaml)) |
| **StatefulSet** | ghost-on-kubernetes-mysql | Manages the MySQL 8 database, ensuring stable networking and persistent storage. (File: [05-mysql.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/05-mysql.yaml)) |
| **Deployment** | ghost-on-kubernetes | Manages the Ghost v6 application pods. (File: [06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml)) |
| **Services** | ghost-on-kubernetes-service, ghost-on-kubernetes-mysql-service | Exposes Ghost (2368) and MySQL (3306) internally within the cluster. (File: [03-service.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/03-service.yaml)) |
| **PersistentVolumeClaims (PVC)** | k8s-ghost-content, ghost-on-kubernetes-mysql-pvc | Requests persistent storage for Ghost content (themes, images) and MySQL data. (File: [02-pvc.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/02-pvc.yaml)) |
| **Secrets** | ghost-config-prod, ghost-on-kubernetes-mysql-env, tls-secret | Securely stores Ghost configuration, database credentials, and TLS certificates (optional). (Files: [01-mysql-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-mysql-config.yaml), [04-ghost-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/04-ghost-config.yaml), [01-tls.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-tls.yaml)) |
| **Ingress** | ghost-on-kubernetes-ingress | Exposes the Ghost application to the outside world via HTTP/HTTPS (requires a TLD). (File: [07-ingress.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml)) |

*Note*: You can host multiple Ghost instances by replacing the Namespace specification in each manifest file.

## **Installation Instructions (Production)**

Follow these steps to deploy Ghost on your Kubernetes cluster.

### **Prerequisites**

1. A functioning Kubernetes cluster (kubectl configured).  
2. A provisioned StorageClass (required for PVCs).

### **0. Clone (or fork) the Repository**

```bash
## Clone the repository  
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags  
## Change directory  
cd ghost-on-kubernetes
```

### **1. Review and Configure**

Review the example configuration files and modify the manifests in the deploy/ folder to suit your environment (e.g., storage class, domain name, secret values).

* **Configurations:** Check the example configuration files in the [examples/](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/) directory:  
  * config.production.sample.yaml: Recommended configuration using MySQL 8. Requires a valid top-level domain (TLD) for the url field and Ingress configuration.  
  * config.development.sample.yaml: Uses SQLite for testing environments.  
* **Official Ghost Docs:** Refer to the [official Ghost documentation](https://ghost.org/docs/config/#custom-configuration-files) for detailed configuration options.

### **2. Deployment Sequence**

It is **crucial** to apply the manifests in the correct order to ensure dependency resolution (especially the database components).

1. **Create the Namespace:**  

   ```bash
    kubectl apply -f deploy/00-namespace.yaml
    ```

2. **Create Secrets (Credentials and Config):**  

   ```bash
   # IMPORTANT: Customize these secrets before applying  
   kubectl apply -f deploy/01-mysql-config.yaml  
   kubectl apply -f deploy/04-ghost-config.yaml  
   kubectl apply -f deploy/01-tls.yaml
   ```

3. **Create Persistent Storage and Services:**  

   ```bash
   kubectl apply -f deploy/02-pvc.yaml  
   kubectl apply -f deploy/03-service.yaml
   ```

4. **Deploy MySQL Database (StatefulSet):**  

   ```bash
   # Wait for the MySQL PVC to be bound  
   kubectl apply -f deploy/05-mysql.yaml
   ```

5. **Deploy the Ghost Application (Deployment):**  

    ```bash
    # Wait for MySQL to be ready before starting
   kubectl apply -f deploy/06-ghost-deployment.yaml
   ```

6. **Expose Ghost with Ingress (Optional/Recommended):**  

    ```bash
    # Routes external traffic to the Ghost Service
    kubectl apply -f deploy/07-ingress.yaml
    ```

## **Your Ghost Blog is Deployed!**

Congratulations! You have deployed a highly secure and scalable Ghost v6 instance on Kubernetes.

### **Accessing Without a Domain Name (Testing)**

To preview the website without configuring Ingress or a TLD, you can use port forwarding:

1. Temporarily configure both url and admin URLs in your config.production.json Secret to use `http://localhost:2368/`.  
2. Restart the Ghost pod(s) after updating the Secret.  
3. Run the port-forwarding command:  

  ```bash
  kubectl port-forward -n ghost-on-kubernetes services ghost-on-kubernetes-service 2368:2368
  ```

## Contributing

We welcome contributions from the community! Please check the [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md) file for more information on how to contribute to this project.

## License and Credits

* This project is licensed under the MIT License. Please check the [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE) file for more information.
* The Ghost CMS is licensed under the [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
* The node image and the Distroless image are licensed by their respective owners.

## Star History

![Star History Chart](https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark)

