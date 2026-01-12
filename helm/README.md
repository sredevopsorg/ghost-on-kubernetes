# Ghost on Kubernetes Helm Chart

Deploy Ghost CMS v6 on Kubernetes with enhanced security using this Helm chart.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- StorageClass configured for persistent volumes
- (Optional) Ingress controller installed
- (Optional) cert-manager for automatic TLS certificate management

## Installation

### Quick Start with Internal MySQL

```bash
helm install my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --create-namespace \
  --set ghost.url=https://yourdomain.tld \
  --set ghost.adminUrl=https://yourdomain.tld \
  --set ingress.hosts[0].host=yourdomain.tld \
  --set ingress.tls.hosts[0]=yourdomain.tld \
  --set persistence.ghost.storageClassName=your-storage-class \
  --set persistence.mysql.storageClassName=your-storage-class
```

### With External MySQL

```bash
helm install my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --create-namespace \
  --set mysql.enabled=false \
  --set mysql.external.host=external-mysql-host \
  --set mysql.external.database=ghost \
  --set mysql.external.username=ghost \
  --set mysql.external.password=your-password \
  --set ghost.url=https://yourdomain.tld \
  --set persistence.ghost.storageClassName=your-storage-class
```

### With cert-manager for TLS

```bash
helm install my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --create-namespace \
  --set ghost.url=https://yourdomain.tld \
  --set ingress.tls.mode=certManager \
  --set ingress.tls.certManager.issuer=letsencrypt-prod \
  --set ingress.tls.certManager.issuerKind=ClusterIssuer \
  --set persistence.ghost.storageClassName=your-storage-class
```

### With Manual TLS Certificates

```bash
# Create TLS secret first
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n ghost

# Install chart
helm install my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --set ghost.url=https://yourdomain.tld \
  --set ingress.tls.mode=manual \
  --set ingress.tls.secretName=tls-secret \
  --set persistence.ghost.storageClassName=your-storage-class
```

## Configuration

### Key Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of Ghost replicas | `1` |
| `image.repository` | Ghost image repository | `ghcr.io/sredevopsorg/ghost-on-kubernetes` |
| `image.tag` | Ghost image tag | `main` |
| `ghost.url` | Ghost site URL | `https://yourdomain.tld` |
| `ghost.adminUrl` | Ghost admin URL | `https://yourdomain.tld` |
| `mysql.enabled` | Deploy MySQL StatefulSet | `true` |
| `mysql.external.host` | External MySQL host | `external-mysql-host` |
| `persistence.ghost.enabled` | Enable Ghost content persistence | `true` |
| `persistence.ghost.storageClassName` | StorageClass for Ghost content | `""` |
| `persistence.ghost.accessMode` | Access mode for Ghost PVC | `ReadWriteOnce` |
| `persistence.ghost.size` | Ghost content volume size | `1Gi` |
| `persistence.mysql.enabled` | Enable MySQL persistence | `true` |
| `persistence.mysql.storageClassName` | StorageClass for MySQL | `""` |
| `ingress.enabled` | Enable Ingress | `true` |
| `ingress.className` | Ingress class name | `traefik` |
| `ingress.preset` | Ingress preset (traefik/nginx/custom) | `traefik` |
| `ingress.tls.enabled` | Enable TLS | `true` |
| `ingress.tls.mode` | TLS mode (manual/certManager/both) | `manual` |

### Mail Configuration

```yaml
ghost:
  mail:
    enabled: true
    transport: "SMTP"
    from: "user@server.com"
    service: "Google"
    host: "smtp.gmail.com"
    port: 465
    secure: true
    user: "user@server.com"
    password: "your-password"
```

### Resource Limits

```yaml
ghost:
  resources:
    limits:
      cpu: 800m
      memory: 800Mi
    requests:
      cpu: 100m
      memory: 256Mi

mysql:
  resources:
    limits:
      cpu: 900m
      memory: 1Gi
    requests:
      cpu: 300m
      memory: 500Mi
```

### High Availability Setup

For HA, you need ReadWriteMany storage:

```yaml
replicaCount: 3
persistence:
  ghost:
    accessMode: ReadWriteMany
    storageClassName: nfs-client  # or other RWX storage
```

**Note**: Ghost officially doesn't support HA clustering. Consider using a CDN and caching layer.

### Ingress Presets

#### Traefik (default)
```yaml
ingress:
  preset: traefik
  className: traefik
```

#### Nginx
```yaml
ingress:
  preset: nginx
  className: nginx
```

#### Custom
```yaml
ingress:
  preset: custom
  annotations:
    custom.annotation/key: value
```

## Upgrading

```bash
helm upgrade my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --reuse-values \
  --set image.tag=new-version
```

## Uninstalling

```bash
helm uninstall my-ghost --namespace ghost
```

**Warning**: PVCs are not automatically deleted. To remove them:

```bash
kubectl delete pvc -n ghost -l app.kubernetes.io/instance=my-ghost
```

## Security Features

- **Non-root containers**: Ghost runs as UID 65532, MySQL as UID 65534
- **Distroless base**: Minimal attack surface with no shell
- **ReadOnlyRootFilesystem**: Immutable container filesystems
- **Security contexts**: Drop all capabilities, no privilege escalation
- **Network policies**: (optional) Can be added via annotations

## Troubleshooting

### Ghost pod stuck in Init
Check init container logs:
```bash
kubectl logs -n ghost <pod-name> -c permissions-fix
```

### MySQL connection issues
Verify MySQL is ready:
```bash
kubectl get pods -n ghost -l app=ghost-on-kubernetes-mysql
kubectl logs -n ghost <mysql-pod-name>
```

### Storage issues
Check PVC status:
```bash
kubectl get pvc -n ghost
kubectl describe pvc <pvc-name> -n ghost
```

## Values File Example

See `values.yaml` for full configuration options. Create a custom values file:

```yaml
# custom-values.yaml
ghost:
  url: https://blog.example.com
  adminUrl: https://blog.example.com
  mail:
    enabled: true
    from: noreply@example.com
    user: smtp-user@example.com
    password: smtp-password

mysql:
  enabled: true
  auth:
    database: ghost_prod
    username: ghost_user
    password: secure-password
    rootPassword: secure-root-password

persistence:
  ghost:
    storageClassName: fast-ssd
    size: 5Gi
  mysql:
    storageClassName: standard
    size: 10Gi

ingress:
  className: nginx
  preset: nginx
  tls:
    mode: certManager
    certManager:
      issuer: letsencrypt-prod
      issuerKind: ClusterIssuer
  hosts:
    - host: blog.example.com
      paths:
        - path: /
          pathType: Prefix
```

Install with custom values:
```bash
helm install my-ghost ./ghost-on-kubernetes \
  --namespace ghost \
  --create-namespace \
  -f custom-values.yaml
```

## Contributing

See the main repository for contribution guidelines: https://github.com/sredevopsorg/ghost-on-kubernetes

## License

MIT License - See LICENSE file for details