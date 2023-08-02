# Ghost on Kubernetes

This Helm chart deploys Ghost CMS v5 (latest) in Kubernetes as statefulsets with MySQL 8.

## Installation

## 1. Add the sredevops Helm repository

```console
helm repo add sredevops https://sredevopsdev.github.io/ghost-on-kubernetes
```

*Modify the values in `values.yaml` to suit your needs.*

```yaml

# values.yaml

ghostConfigProd:
# Add your ghost configuration here, all details can be found: https://ghost.org/docs/concepts/config/

  url: "http://localhost:2368"
  adminUrl: "http://localhost:2368"
  host: "0.0.0.0" # We recommend to keep this value, unless you know what you are doing
  port: 2368
  mailTransport: SMTP
  mailService: Google
  mailHost: smtp.gmail.com
  mailPort: 587
  mailSecureConnection: true
  mailAuthUser: "user@mail.com"
  mailAuthPass: "c0ntr4s3n4"
  debug: true
  emailAnalytics: false
  useUpdateCheck: false
  useRpcPing: false
  # This is the secret name for TLS certificate, optional

ghostOnKubernetes:
  ghostOnKubernetes:
    env:
      nodeEnv: production
    image:
      repository: ghcr.io/sredevopsdev/ghost-on-kubernetes
      tag: main
    imagePullPolicy: Always
  replicas: 1
  resources:
    limits:
      cpu: 1000m
      memory: 1Gi
    requests:
      cpu: 0m
      memory: 0Mi

kubernetesClusterDomain: cluster.local

# Values used into mysql statefulset
mysqlGhostOnKubernetes:
# Database name
  mysqlDatabase: "ghostdb"
  mysqlUser: "userdb"
  mysqlPassword: "userdbpassword"
  mysqlRootPassword: "rootpassword"
  mysqlGhostOnKubernetes:
# Image used for mysql, Ghost docs recommend to use mysql 8.
    image:
      repository: docker.io/mysql/mysql-server
      tag: 8.0.32-1.2.11-server
    imagePullPolicy: IfNotPresent
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 0
        memory: 0
  replicas: 1 # Unless you know what you are doing, we recommend to keep this value
  mysqlPort: 3306 # Port isn't exposed, but it's required for internal operations
# User and password for database

volumeClaimTemplates:
  mysql: 
    accessMode: ReadWriteOnce
    storage: 1Gi
    storageClassName: local-path
  ghost:
    accessModes: ReadWriteOnce
    storage: 10Gi
    storageClassName: local-path

tlsSecretName: "" 
ingressHost: "ghost.localhost"

```

## 2. Install the chart

```bash
helm install my-ghost sredevops/ghost-on-kubernetes --values values.yaml
```

For more information on how to configure the chart, see the [official documentation](https://sredevopsdev.github.io/ghost-on-kubernetes/).

## Uninstallation

To uninstall/delete the `my-ghost` deployment:

```console
helm uninstall my-ghost
```

