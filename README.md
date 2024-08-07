# Ghost on Kubernetes by SREDevOps.Org

<center><a href="https://sredevops.org" target="_blank" rel="noopener"><img src="https://github.com/sredevopsorg/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f" alt="SREDevOps.org" width="60%" align="center" /></a></center>

**Community for SRE, DevOps, Cloud Native, GNU/Linux, and more. 🌎**

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) | [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) | [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) | [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) | [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) | [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888)

> This repository implements Ghost CMS v5.xx.x from [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) on Kubernetes, with our custom image, which has significant improvements to be used on Kubernetes. See this whole README for more information.

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" />
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" height="300px" />
</picture>

## Recent Changes

We've made some significant updates to improve the security and efficiency of our Ghost implementation on Kubernetes:

1. **Multi-arch support**: The images are now multi-arch, with [support for amd64 and arm64](#arm64-compatible).
2. **Distroless Image**: We use [@GoogleContainerTools](https://github.com/GoogleContainerTools)'s [Distroless NodeJS](https://github.com/GoogleContainerTools/distroless/blob/main/examples/nodejs/Dockerfile) as the execution environment for the final image. Distroless images are minimal images that contain only the necessary components to run the application, making them more secure and efficient than traditional images.
3. **MySQL StatefulSet**: We've changed the MySQL implementation to a StatefulSet. This provides stable network identifiers and persistent storage, which is important for databases like MySQL that need to maintain state.
4. **Init Container**: We've added an init container to the Ghost deployment. This container is responsible for setting up the necessary configuration files and directories before the main Ghost container starts, ensuring the right directories are created, correct ownership for user node inside distroless container UID/GID to 65532, and the correct permissions are set.  Check [deploy/06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml) for details on these changes.
5. **Entrypoint Script**: We've introduced a new entrypoint script that runs as the non-privileged user inside the distroless container. This script is responsible for updating the default themes then starts the Ghost application. This script is executed by the nonroot user without privileges within the Distroless container, which updates default themes and starts the Ghost application, operation performed into the distroless container in runtime. [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)

```Dockerfile
#
# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with the official Node 20 on Debian Bookworm (LTS Iron) image and uses the Distroless base image for security and minimalism.
#
# Stage 1: Build Environment
# In this stage, the build environment is set up and the necessary dependencies are installed.
# The Ghost version is defined as a build argument and set as an environment variable.
# The installation directory, content directory, and original content directory for Ghost are also set as environment variables.
# The Ghost CLI is installed globally and configured with some workarounds to build the arm64 version in GitHub without timeout failures.
# Ghost is then installed with the specified version, using MySQL as the database, and configured without prompts, stack traces, and setup.
# The original content directory is moved to a backup location, a new content directory is created, and the correct ownership and permissions are set.
#
# Stage 2: Final Image
# In this stage, the final image is created using the Distroless base image.
# The Ghost installation directory is copied from the build environment to the final image.
# The working directory is set to the Ghost installation directory and a volume is created for the content directory.
# The entrypoint script is copied to the current Ghost version.
# Port 2368 is exposed for Ghost.
# The command is set to start Ghost with the entrypoint script.
#
# For more information, refer to the GitHub repository: https://github.com/sredevopsorg/ghost-on-kubernetes

# Stage 1: Build Environment
FROM node:iron-bookworm@sha256:786005cf39792f7046bcd66491056c26d2dbcc669c072d1a1e4ef4fcdddd26eb AS build-env
...

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12
...
# This Dockerfile is used to build a container image for running Ghost, a popular open-source blogging platform, on Kubernetes.
# The image is built with official Node 20 on Debian Bookworm (LTS Iron)  image and uses the Distroless base image for security and minimalism.

# Stage 1: Build Environment
FROM node:iron-bookworm@sha256:786005cf39792f7046bcd66491056c26d2dbcc669c072d1a1e4ef4fcdddd26eb AS build-env
USER root
# Create a new user and group named "nonroot" with the UID 65532 and GID 65532, not a member of the root, sudo, and sys groups, and set the home directory to /home/nonroot.
# This user is used to run the Ghost application in the container for security reasons.
RUN groupadd -g 65532 nonroot && \
    useradd -u 65532 -g 65532 -d /home/nonroot nonroot && \
    usermod -aG nonroot nonroot && \
    mkdir -pv /home/nonroot && \
    chown -Rfv 65532:65532 /home/nonroot

USER nonroot
SHELL ["/bin/bash", "-c"]
ENV NODE_ENV=production NPM_CONFIG_LOGLEVEL=info

# Define the GHOST_VERSION build argument and set it as an environment variable
ARG GHOST_VERSION 
ENV GHOST_VERSION=$GHOST_VERSION  

# Set the installation directory, content directory, and original content directory for Ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig

RUN mkdir -pv "$GHOST_INSTALL"
    
# Install the latest version of Ghost CLI globally and config some workarounds to build arm64 version in Github without timeout failures
RUN yarn config set network-timeout 60000 && \
    yarn config set inline-builds true && \
    npm config set fetch-timeout 60000 && \
    npm config set progress && \
    npm config set omit dev

# Create the Ghost installation directory and set the owner to the "node" user


# RUN npm i -g ghost-cli@latest || yarn global add ghost-cli@latest

# Install Ghost with the specified version, using MySQL as the database, and configure it without prompts, stack traces, setup, and in the specified installation directory
# RUN ghost install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local || 

RUN npx ghost-cli install $GHOST_VERSION --dir $GHOST_INSTALL --db mysql --dbhost mysql --no-prompt --no-stack --no-setup --color --process local


# Move the original content directory to a backup location, create a new content directory, set the correct ownership and permissions, and switch back to the "node" user
RUN mv -v $GHOST_CONTENT $GHOST_CONTENT_ORIGINAL && \
    mkdir -v $GHOST_CONTENT && \
    # chown -Rfv 65532 $GHOST_CONTENT_ORIGINAL && \
    # chown -Rfv 65532 $GHOST_CONTENT && \
    # chown -fv 65532 $GHOST_INSTALL && \
    chmod -v 0775 $GHOST_CONTENT

# Switch back to the "node" user
# USER node

# Stage 2: Final Image
FROM gcr.io/distroless/nodejs20-debian12

# Set the installation directory and content directory for Ghost
ENV GHOST_INSTALL_SRC=/home/nonroot/app/ghost
ENV GHOST_INSTALL=/home/nonroot/app/ghost
ENV GHOST_CONTENT=/home/nonroot/app/ghost/content
ENV GHOST_CONTENT_ORIGINAL=/home/nonroot/app/ghost/content.orig
USER nonroot

# Copy the Ghost installation directory from the build environment to the final image
COPY --from=build-env $GHOST_INSTALL_SRC $GHOST_INSTALL

# Set the working directory to the Ghost installation directory and create a volume for the content directory
# The volume is used to persist the data across container restarts, upgrades, and migrations. 
# It's going to be handled with an init container that will copy the content from your original content directory to the new content directory (If there is any)
# The CMD script will handle default themes included (Casper and Source) and init Ghost.

WORKDIR $GHOST_INSTALL
VOLUME $GHOST_CONTENT

# Copy the entrypoint script to the current Ghost version.
COPY --chown=65532 entrypoint.js current/entrypoint.js


# Expose port 2368 for Ghost
EXPOSE 2368

# Set the command to start Ghost with the entrypoint (See https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)
CMD ["current/entrypoint.js"]
```


## Features

- [ARM64 Support!](#arm64-compatible)
- We use the official Node 20 Iron Bookworm image as our build environment. [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile)
- We introduce a multi-stage build, which reduces the final image size, and improves security by removing unnecessary components from the final image.
- [Distroless Node 20 Debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) as our runtime environment for the final stage of the image.
- Removed gosu, now everything runs as the default Node user (UID 1000:GID 1000) inside the Distroless container. This change itself reduces 2 critical vulnerabilities and 33 high vulnerabilities reported by Docker Scout in the original Ghost image (References: [Ghost Official Image](https://hub.docker.com/layers/library/ghost/5.84/images/sha256-918536e36327bef2d9dabbe520cf2a53d692b9dc01075442810f6aa9a337cd60?context=repo&tab=vulnerabilities) and [Ghost on Kubernetes Image on Docker Hub](https://hub.docker.com/layers/ngeorger/ghost-on-kubernetes/main/images/sha256-095809c153e7292ea1962419811492f188aab8e1840aa63194485e3a6d4900b2?context=explore) at the time of writing).
- New Entrypoint flow, using a Node.js script executed by the Node user without privileges within the Distroless container, which updates default themes and starts the Ghost application, operation which is performed into the distroless container itself.
- We use the latest version of Ghost 5 (when the image is built).

## ARM64 Compatible

- Images are now multi-arch, with support for amd64 and arm64 [(link to discussion)](https://github.com/sredevopsorg/ghost-on-kubernetes/issues/73#issuecomment-1933939315)


## Installation

### 0. Clone the repository or fork it

```bash
# Clone the repository
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Change directory
cd ghost-on-kubernetes
# Create a new branch for your changes (optional but recommended).
git checkout -b my-branch --no-track --detach
```

### 1. Check the example configurations

- There are some example configuration files in the [examples](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/) directory. We use the stored configuration as a `kind: Secret` in the `ghost-on-kubernetes` namespace for Ghost and MySQL configuration. There are two example configuration files:
  - `config.development.sample.yaml`: This configuration file is for the Ghost development environment. It uses SQLite as the database. It can be useful if you want to test the Ghost configuration before implementing it in a production environment.
  - `config.production.sample.yaml`: This configuration file is for the Ghost production environment. It uses MySQL 8, and is the recommended configuration for production environments. It requires a valid top-level domain (TLD) and [configuration for Ingress to access Ghost from the Internet](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml).
- If you need more information on the configuration, check the [official Ghost documentation](https://ghost.org/docs/config/#custom-configuration-files).

### 2. Review the default values and make changes as needed in the following files

- `deploy/00-namespace.yaml` # Change the namespace according to your needs
- `deploy/01-secrets.yaml`

```yaml
# deploy/01-secrets.yaml

apiVersion: v1
kind: Secret
metadata:
  name: mysql-ghost-on-kubernetes
  namespace: ghost-on-kubernetes
type: Opaque
stringData:
  MYSQL_DATABASE: mysql-db-name # Same as in deploy/04-config.production.yaml
  MYSQL_USER: mysql-db-user # Same as in deploy/04-config.production.yaml
  MYSQL_PASSWORD: mysql-db-password # Same as in deploy/04-config.production.yaml
  MYSQL_ROOT_PASSWORD: mysql-db-root-password # Same as in deploy/04-config.production.yaml
```

- `deploy/02-pvc.yaml` # Change the storageClassName according to your needs
- `deploy/03-services.yaml` # Change the hosts according to your needs
- `deploy/04-config.production.yaml` # Change the values according to the secrets and services
- `deploy/05-mysql.yaml` # Change the values according to the secrets and services
- `deploy/06-ghost-deployment.yaml` # Change the values according to the secrets and services
- `deploy/07-ingress.yaml` # Optional

### 3. Apply your manifests

```bash
# Before applying the manifests, make sure you are in the root directory of the repository
# 🚨 Be sure to not change the filenames, also be sure to modify the files according to your needs before applying them.
# Why? Just because we need to deploy them in order. If you change the filenames, you will need to apply them one by one in the correct order.
kubectl apply -f ./deploy
```

### 4. Access your Ghost CMS

```bash
# Get the ingress IP, if you have configured the Ingress
kubectl get ingress -n ghost-on-kubernetes -o wide 

# Alternatively, create a port-forwarding rule to access the Ghost CMS
kubectl port-forward -n ghost-on-kubernetes service/service-ghost-on-kubernetes 2368:2368
```

### 5. Open your browser and access your Ghost CMS

- [http://localhost:2368](http://localhost:2368) (if you used the port-forwarding method)
- [http://your-ghost-domain.com](http://your-ghost-domain.com) (if you used the Ingress method)

### 6. Log in to your Ghost CMS Admin Panel

- [http://localhost:2368/ghost](http://localhost:2368/ghost) (if you used the port-forwarding method)
- [http://your-ghost-domain.com/ghost](http://your-ghost-domain.com/ghost) (if you used the Ingress method)

## Contributing

We welcome contributions from the community! Please check the [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md) file for more information on how to contribute to this project.

## License and Credits

- This project is licensed under the GNU General Public License v3.0. Please check the [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE) file for more information.
- The Ghost CMS is licensed under the [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
- The node:20 image and the Distroless image are licensed by their respective owners.
