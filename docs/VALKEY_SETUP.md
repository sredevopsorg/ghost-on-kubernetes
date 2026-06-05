# Valkey/Redis Cache Setup Guide

This guide explains how to enable and configure Valkey (or Redis) caching for your Ghost on Kubernetes deployment using the static deployment mechanism.

## Overview

Valkey is a high-performance in-memory data store that Ghost uses for caching. It can significantly improve your Ghost blog's performance by caching:

- Post images
- Global scans
- Public posts
- Public tags
- Link redirects
- Statistics

## Files Involved

When using Valkey with the static deployment, the following files are used:

- `01-valkey-config.yaml` - Valkey authentication credentials
- `02-pvc.yaml` - Persistent storage for Ghost, MySQL, and Valkey data
- `05-valkey.yaml` - Valkey deployment
- `03-service.yaml` - Services for Ghost, MySQL, and Valkey
- `04-ghost-config.yaml` - Ghost configuration with cache settings
- `06-ghost-deployment.yaml` - Ghost deployment with Valkey environment variables

## Deployment Order

Apply the configuration files in this order:

```bash
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-mysql-config.yaml
kubectl apply -f 01-valkey-config.yaml       # NEW
kubectl apply -f 01-tls.yaml
kubectl apply -f 02-pvc.yaml                 # Now includes Valkey PVC
kubectl apply -f 03-service.yaml
kubectl apply -f 04-ghost-config.yaml
kubectl apply -f 05-mysql.yaml
kubectl apply -f 05-valkey.yaml              # NEW
kubectl apply -f 06-ghost-deployment.yaml
kubectl apply -f 07-ingress.yaml
```

## Configuration

### Basic Setup (No Authentication)

The default configuration includes Valkey cache settings in `04-ghost-config.yaml`:

```json
"hostSettings": {
  "postsPublicCache": { "enabled": true },
  "linkRedirectsPublicCache": { "enabled": true },
  "tagsPublicCache": { "enabled": true },
  "statsCache": { "enabled": true }
},
"adapters": {
  "active": "Redis",
  "cache": {
    "Redis": {
      "host": "ghost-on-kubernetes-valkey-service",
      "port": 6379,
      "db": 0,
      "ttl": 86400,
      "keyPrefix": "ghost:"
    },
    ...
  }
}
```

### Enabling Valkey Authentication

If you want to use authentication with Valkey:

1. **Set a strong password** in `01-valkey-config.yaml`:
   ```yaml
   stringData:
     VALKEY_PASSWORD: "your-strong-password-here"
   ```

2. **Uncomment Valkey authentication** in `05-valkey.yaml`:
     - valkey-server
     - --dir
     - /data
     - --protected-mode
     - "no"
     - --requirepass           # Uncomment
     - $(VALKEY_PASSWORD)      # Uncomment

   env:
     - name: VALKEY_PASSWORD
       valueFrom:
         secretKeyRef:
           name: ghost-on-kubernetes-valkey-env
           key: VALKEY_PASSWORD
   ```

3. **Update Ghost deployment** in `06-ghost-deployment.yaml` to include the password:
   ```yaml
   env:
     - name: NODE_ENV
       value: production
     - name: VALKEY_PASSWORD
       valueFrom:
         secretKeyRef:
           name: ghost-on-kubernetes-valkey-env
           key: VALKEY_PASSWORD
   ```

4. **Update Ghost config** in `04-ghost-config.yaml` to include credentials:
   ```json
   "Redis": {
     "host": "ghost-on-kubernetes-valkey-service",
     "port": 6379,
     "db": 0,
     "ttl": 86400,
     "keyPrefix": "ghost:",
     "username": "default",
     "password": "your-strong-password-here"
   }
   ```

## TTL (Time To Live) Values

The cache TTL values (in seconds) control how long items are cached:

- `imageSizes`: 86400 (1 day)
- `gscan`: 43200 (12 hours)
- `postsPublic`: 1800 (30 minutes)
- `tagsPublic`: 3600 (1 hour)
- `linkRedirectsPublic`: 7200 (2 hours)
- `stats`: 900 (15 minutes)

Adjust these values in `04-ghost-config.yaml` based on your needs.

## Using External Valkey/Redis

If you want to use an external Redis or Valkey instance instead of deploying one:

1. **Skip files**: Do not apply `08-valkey-config.yaml`, `09-valkey-pvc.yaml`, and `10-valkey.yaml`

2. **Do not apply the Valkey service**: Comment out or remove the Valkey service section from `03-service.yaml`

3. **Update `04-ghost-config.yaml`** with your external Valkey/Redis details:
   ```json
   "Redis": {
     "host": "your-external-valkey-host",
     "port": 6379,
     "db": 0,
     "ttl": 86400,
     "keyPrefix": "ghost:",
     "username": "your-username",
     "password": "your-password"
   }
   ```

## Example Configurations

Two example configuration files are provided:

- `examples/config.production-valkey.sample.yaml` - Production configuration with Valkey
- `examples/config.development-valkey.sample.yaml` - Development configuration with Valkey

These can be used as templates for your deployments.

## Storage Requirements

Valkey persistence is configured with:

- **Storage Class**: Default (modify `09-valkey-pvc.yaml` if needed)
- **Size**: 1Gi (adjust based on your cache needs)
- **Access Mode**: ReadWriteOnce

For development, 1Gi is usually sufficient. Adjust for production based on your blog size and traffic.

## Resource Limits

Default Valkey resource limits in `10-valkey.yaml`:

```yaml
resources:
  requests:
    memory: 128Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 500m
```

Adjust these based on your deployment size and available cluster resources.

## Troubleshooting

### Valkey Pod Won't Start

1. Check Valkey pod logs:
   ```bash
   kubectl logs -f deployment/ghost-on-kubernetes-valkey -n ghost-on-kubernetes
   ```

2. Verify PVC is created:
   ```bash
   kubectl get pvc -n ghost-on-kubernetes | grep valkey
   ```

3. Check events:
   ```bash
   kubectl describe pod <valkey-pod-name> -n ghost-on-kubernetes
   ```

### Ghost Can't Connect to Valkey

1. Verify Valkey service is running:
   ```bash
   kubectl get svc -n ghost-on-kubernetes | grep valkey
   ```

2. Test connectivity from Ghost pod:
   ```bash
   kubectl exec -it <ghost-pod-name> -n ghost-on-kubernetes -- sh
   # Inside the pod:
   nc -zv ghost-on-kubernetes-valkey-service 6379
   ```

3. Check Ghost logs:
   ```bash
   kubectl logs -f deployment/ghost-on-kubernetes -n ghost-on-kubernetes
   ```

### Cache Not Working

1. Verify Ghost config is loaded correctly:
   ```bash
   kubectl exec -it <ghost-pod-name> -n ghost-on-kubernetes -- cat /home/nonroot/app/ghost/config.production.json
   ```

2. Check for cache-related errors in Ghost logs

3. Verify Valkey contains data:
   ```bash
   kubectl exec -it <valkey-pod-name> -n ghost-on-kubernetes -- valkey-cli
   # Inside valkey-cli:
   > KEYS ghost:*
   > INFO stats
   ```

## Next Steps

After deploying Valkey, you can:

1. Monitor cache performance in Ghost admin
2. Adjust TTL values based on your content update frequency
3. Scale Valkey resources if needed
4. Consider adding Valkey monitoring/alerting with Prometheus
