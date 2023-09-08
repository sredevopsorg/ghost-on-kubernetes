# Ghost on Kubernetes by [SREDevOps](https://sredevops.org)

[![Build and push image to DockerHub and GitHub Container Registry](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml/badge.svg)](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml) 

This repo deploys Ghost CMS v5.xx.x @TryGhost (upstream) in Kubernetes as deployments and statefulsets with MySQL 8.

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
  "url": "http://localhost:2368",
  "admin": {
    "url": "http://localhost:2368"
  },
  "server": {
    "port": 2368,
    "host": "0.0.0.0"
  },
  "mail": {
    "transport": "SMTP",
    "options": {
      "service": "Google",
      "host": "smtp.gmail.com",
      "port": 587,
      "secure": true,
      "auth": {
        "user": "user@mail.com",
        "pass": "pass"
      }
    }
  },
  "logging": {
    "transports": [
      "stdout",
      "file"
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
- deploy/02-pv.yaml
- deploy/03-ingress.yaml
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
kubectl apply -f deploy/02-pv.yaml
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
# Create a port-forward to your Ghost service
kubectl -n ghostk3s port-forward svc/ghostk3s 2368:2368 &

```

## 5. Open your browser and access the Ghost CMS

[http://localhost:2368](http://localhost:2368)

## 6. Login to your Ghost CMS
[http://localhost:2368/ghost](http://localhost:2368/ghost)
