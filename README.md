# Ghost on Kubernetes by [SREDevOps](https://sredevops.org)

[![Build and push image to DockerHub and GitHub Container Registry](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml/badge.svg)](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml)

This repo deploys a clean Ghost CMS v5.xx.x from [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) in Kubernetes, as a Deployment using our [custom image](https://github.com/sredevopsdev/ghost-on-kubernetes/blob/main/Dockerfile) built based on the ["official" Ghost 5 debian image](https://github.com/docker-library/ghost/blob/master/5/debian/Dockerfile), but with some modifications:

- We use the official Node 18 Hydrogen bookworm slim image as base.
- Removed gosu, we use the default user (node) to run Ghost.
- Modified the entrypoint to run as node user, so we can run the pod as non-root.
- Update every possible dependencies in the base image to minimize vulnerabilities.
- We update npm and ghost-cli to the latest versions on every build.
- We use the latest version of Ghost 5.

> *_Note: At this time, we dropped support for arm64 and armv7l, but we will add it back soon. Pull requests are welcome._*  

## Installation

## 1. Clone the repository

```bash
# Clone the repository
git clone https://github.com/sredevopsdev/ghost-on-kubernetes.git
# Change directory
cd ghost-on-kubernetes
# Checkout to your local branch (optional)
git checkout -b my-branch

```

## 2. Review the default values and make changes as per your requirements, if any into the following files

- deploy/00-namespace.yaml
- deploy/01-config.production.yaml # Check config.production.sample.json for more details

```yaml
config.production.sample.json: |
{
  "url": "http://localhost:2368", # Change the url as per your requirements
  "admin": {
    "url": "http://localhost:2368" # Change the url as per your requirements
  },
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "mail": {
    "transport": "SMTP", # Or use Mailgun, etc.
    "options": {
      "service": "Google",
      "host": "smtp.gmail.com",
      "port": 465,
      "secure": true,
      "auth": {
        "user": "user@mail.com",
        "pass": "pass"
      }
    }
  },
  "logging": {
    "transports": [
      "stdout"
    ]
  },
  "database": {
    "client": "mysql",
    "connection": 
    {
      "host": "mysql-ghostk3s", # Same as service name
      "user": "userdb", # Same as in secret
      "password": "passdb", # Same as in secret
      "database": "db", # Same as in secret
      "port": "3306"
    }
  },
  "debug": true,
  "process": "local",
  "paths": {
    "contentPath": "/var/lib/ghost/content"
  }
}


```

- deploy/01-secrets.yaml

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-ghostk3s
  namespace: ghostk3s
type: Opaque
stringData:
  MYSQL_DATABASE: mysql-db-name # Same as in config.production.json
  MYSQL_USER: mysql-db-user # Same as in config.production.json
  MYSQL_PASSWORD: mysql-db-password # Same as in config.production.json
  MYSQL_ROOT_PASSWORD: mysql-db-root-password # Same as in config.production.json
```

- deploy/02-pvc.yaml # Change the storageClassName as per your requirements
- deploy/03-ingress.yaml # Change the hosts as per your requirements
- deploy/03-service.yaml
- deploy/04-mysql.yaml
- deploy/05-ghost-deployment.yaml

## 3. Apply your manifests

```bash
# Create the namespace
kubectl apply -f deploy/00-namespace.yaml
# Create the secrets
kubectl apply -f deploy/01-secrets.yaml
kubectl apply -f deploy/01-config.production.yaml
# Create the persistent volume
kubectl apply -f deploy/02-pvc.yaml
# Create the ingress
kubectl apply -f deploy/03-ingress.yaml
# Create the services
kubectl apply -f deploy/03-service.yaml
# Create the MySQL database
kubectl apply -f deploy/04-mysql.yaml
# Create the Ghost deployment
kubectl apply -f deploy/05-ghost-deployment.yaml
```

## 4. Access your Ghost CMS

```bash
# Get the ingress IP address
kubectl get ing -n ghostk3s -o wide 


```

## 5. Open your browser and access the Ghost CMS

[http://localhost:2368](http://localhost:2368)

## 6. Login to your Ghost CMS

[http://localhost:2368/ghost](http://localhost:2368/ghost)
