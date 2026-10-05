# Ghost on Kubernetes Helm Chart

Deploy [Ghost](https://ghost.org) CMS on Kubernetes with a hardened, rootless,
multi-arch container image.

## Prerequisites

- Kubernetes 1.25 or newer (enforced by `kubeVersion` in `Chart.yaml`)
- Helm 3.13 or newer
- A default StorageClass, or an explicit `storageClassName` per claim
- An Ingress controller (Traefik and nginx presets included) if you enable Ingress
- cert-manager if you use `ingress.tls.mode: certManager` or `both`

## Install

```bash
helm repo add sredevopsorg https://sredevopsorg.github.io/ghost-on-kubernetes
helm repo update

helm install my-ghost sredevopsorg/ghost-on-kubernetes \
  --namespace ghost --create-namespace \
  --set ghost.url=https://yourdomain.tld \
  --set ingress.hosts[0].host=yourdomain.tld \
  --set ingress.tls.hosts[0]=yourdomain.tld \
  --set persistence.ghost.storageClassName=your-storage-class \
  --set persistence.mysql.storageClassName=your-storage-class
```

Run `helm install` and read the NOTES output: it prints the URL, the TLS state,
and any warning that applies to the configuration you chose.

## Common configurations

Every example below is a file in `examples/` and is rendered by CI.

| Example | Use it for |
| ------- | ---------- |
| `examples/production-values.yaml` | Internal MySQL, cert-manager TLS, disruption budget |
| `examples/ha-values.yaml` | Three replicas over ReadWriteMany storage, spread across zones |
| `examples/external-mysql-values.yaml` | A database managed outside this release |
| `examples/development-values.yaml` | Local development, no Ingress, small footprint |
| `examples/manual-tls-values.yaml` | A certificate you supply yourself |

```bash
helm install my-ghost sredevopsorg/ghost-on-kubernetes \
  -n ghost --create-namespace \
  -f examples/production-values.yaml
```

## Configuration

### Ghost

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `ghost.url` | Public site URL, including the scheme | `https://yourdomain.tld` |
| `ghost.adminUrl` | Admin URL, defaults to `ghost.url` | `""` |
| `ghost.probeHost` | Host header used by the probes, defaults to the hostname of `ghost.url` | `""` |
| `ghost.contentPath` | Where Ghost stores uploads, themes and logs | `/home/nonroot/app/ghost/content` |
| `ghost.config.existingSecret` | Mount `config.production.json` from a secret you manage | `""` |
| `ghost.mail.*` | Outgoing mail, required before Ghost can send mail | SMTP settings |
| `ghost.resources` | Ghost container requests and limits | 100m/256Mi – 800m/800Mi |
| `ghost.securityContext` | Container security context, restricted-PSS compliant | non-root, read-only rootfs |
| `ghost.extraConfig` | Merged into `config.production.json`, top-level keys win | `{}` |
| `ghost.initContainer.enabled` | Root init container that chowns the content volume | `false` |
| `ghost.readinessProbe.enabled` | Gates traffic to the pod | `true` |
| `ghost.startupProbe.enabled` | Allows a slow first boot while the database migrates | `true` |
| `ghost.livenessProbe.enabled` | Restarts a wedged process | `false` |
| `ghost.affinity` | `nodeAffinity`, `podAffinity`, `podAntiAffinity`, each optional | `{}` |
| `ghost.nodeSelector` / `tolerations` / `topologySpreadConstraints` | Scheduling control | empty |

### Database

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `mysql.enabled` | Deploy the MySQL StatefulSet and its headless Service | `true` |
| `mysql.auth.database` / `username` / `password` / `rootPassword` | Credentials | change me |
| `mysql.auth.existingSecret` | Use a secret you manage, keys `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_HOST` | `""` |
| `mysql.external.*` | Connection details used when `mysql.enabled=false` | placeholders |
| `mysql.initContainer.enabled` | Root init container that chowns the data directory | `true` |
| `mysql.livenessProbe.enabled` / `readinessProbe.enabled` | TCP checks | `true` |

### Cache

Valkey is a cache, not a database: Ghost works without it and simply serves more
slowly.

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `valkey.enabled` | Deploy the bundled Valkey | `false` |
| `valkey.auth.enabled` | Require a password on it | `true` |
| `valkey.auth.existingSecret` | Use a secret you manage, key `valkey-password` | `""` |
| `valkey.external.enabled` | Cache through an external Valkey or Redis | `false` |
| `valkey.keyPrefix` | Namespace for every cache key | `ghost` |
| `valkey.ttl.*` | Entry lifetime per adapter, in seconds | 15 minutes to 24 hours |

### Storage

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `persistence.ghost.enabled` | Claim for Ghost content | `true` |
| `persistence.ghost.accessMode` | Must be `ReadWriteMany` for more than one replica | `ReadWriteOnce` |
| `persistence.ghost.size` / `storageClassName` / `selector` | Claim tuning | `1Gi`, default class |
| `persistence.mysql.*` | Same keys for the database | `1Gi` |
| `persistence.valkey.*` | Same keys for the cache | `1Gi` |

Turning a claim off switches that workload to an `emptyDir`. Nothing breaks,
but the data is lost on every pod restart. `NOTES.txt` warns when it happens.

### Networking and exposure

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `service.type` | Type of the Ghost Service | `ClusterIP` |
| `service.port` / `targetPort` | Ghost Service port and container port | `2368` |
| `ingress.enabled` | Create an Ingress | `true` |
| `ingress.className` / `preset` / `entrypoint` / `annotations` | Ingress wiring | `traefik` |
| `ingress.hosts[]` | Hosts and paths, with `path` and `pathType` | `yourdomain.tld` |
| `ingress.tls.enabled` / `mode` / `secretName` / `certManager.*` / `certificate` / `key` / `hosts` | TLS | `manual`, `tls-secret` |
| `networkPolicy.enabled` / `egress` | Restrict traffic to the Ghost pods | `false` |

The MySQL and Valkey Services are always headless and internal: their `type` is
not configurable, because a load balancer in front of a database or a cache is
never what you want.

### Platform

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `replicaCount` | Ghost replicas, ignored when autoscaling is on | `1` |
| `autoscaling.enabled` / `minReplicas` / `maxReplicas` / `metrics` / `behavior` | HorizontalPodAutoscaler | off |
| `podDisruptionBudget.enabled` / `maxUnavailable` / `minAvailable` | Eviction safety | off |
| `strategy` / `minReadySeconds` / `revisionHistoryLimit` / `progressDeadlineSeconds` | Rollout behaviour | RollingUpdate, surge 1 |
| `serviceAccount.create` / `name` / `annotations` | Pod identity | created, token not mounted |
| `valkey.podSecurityContext` | Merged over `podSecurityContext` for Valkey pods | `{}` |
| `podSecurityContext` | Pod level security context, `fsGroup` grants volume access | `fsGroup: 65532` |
| `priorityClassName` | Priority class for every pod | unset |
| `imagePullSecrets` | `[{name: <secret>}]` for private registries | `[]` |
| `labels` / `annotations` / `podLabels` / `podAnnotations` | Extra metadata | empty |
| `extraEnv` / `extraEnvFrom` / `extraVolumes` / `extraVolumeMounts` | Escape hatches for the Ghost pod | empty |
| `initContainer.*` | Shared root init container image and resources | busybox |
| `volumes.*` | Sizes of the ephemeral volumes | see `values.yaml` |
| `testImage.*` | Image used by `helm test` | busybox |

### Anything else

`ghost.extraConfig` is merged into `config.production.json` last, so any Ghost
setting this chart does not model can still be set:

```yaml
ghost:
  extraConfig:
    imageOptimization:
      sharp:
        quality: 80
    themes:
      - mytheme
```

For full control, set `ghost.config.existingSecret` to a secret holding your own
`config.production.json`. The chart then stops rendering one, but the rest of
the release still references your `ghost.url`, the Service, and the content
volume.

## Upgrading from 1.x

```bash
helm upgrade my-ghost sredevopsorg/ghost-on-kubernetes -n ghost --reset-values -f my-values.yaml
```

Every release in the 2.0.x line contains changes that a plain `helm upgrade`
cannot apply to a running 1.x release:

1. **Workload selectors are release-scoped.** The MySQL StatefulSet and the
   Valkey Deployment used to select on `app: ghost-on-kubernetes-mysql`, which
   two releases in one namespace shared. Selectors are immutable, so recreate
   those two workloads once, before or during the upgrade:

   ```bash
   kubectl delete statefulset <fullname>-mysql --cascade=orphan -n ghost
   kubectl delete deployment <fullname>-valkey --cascade=orphan -n ghost
   helm upgrade my-ghost sredevopsorg/ghost-on-kubernetes -n ghost -f my-values.yaml
   ```

   Persistent volume claims are not touched by that delete, so the data stays.
   If the delete is skipped, `helm upgrade` fails with an immutable-field error.

2. **The Ghost pod no longer runs a root init container.** Ownership comes from
   `podSecurityContext.fsGroup` now. Set `ghost.initContainer.enabled=true` if
   your volume driver does not apply `fsGroup` (some NFS exports with
   `root_squash`).

3. **Probes are on by default.** Readiness and startup now render where they
   previously did not, which restarts the pods once on upgrade. Liveness stays
   off unless you enable it, and `ghost.probeHost` now defaults to the hostname
   of `ghost.url` rather than `ingress.hosts[0].host`, so probes no longer fail
   when Ingress is disabled.

4. **Values that were never read are gone or replaced.** `service.mysql.type` and
   `service.valkey.type` no longer exist: those Services are headless and
   ClusterIP. `valkey.initResources` was unused. `ghost.affinity.enabled` is
   ignored; set `nodeAffinity`, `podAffinity` or `podAntiAffinity` instead.

5. **`strategy.rollingUpdate.maxSurge` defaults to 1 instead of 3.** With
   `ReadWriteOnce` content, a surge pod cannot attach the volume on a second
   node, so a lower surge stalls less often. For a single replica, `strategy.type:
   Recreate` is the simplest safe choice.

## Verifying

```bash
helm lint ./ghost-on-kubernetes --strict
helm template rel ./ghost-on-kubernetes
helm test my-ghost -n ghost
```

## Troubleshooting

**Ghost pod stuck in ContainerCreating with a pending PVC.**
`kubectl describe pvc -n ghost` and check the StorageClass name and the access
mode. For more than one replica the claim must be `ReadWriteMany`.

**Ghost logs: permission denied on the content volume.**
The volume driver is not applying `fsGroup`. Set
`ghost.initContainer.enabled=true`, or chown the volume to 65532 once by hand.

**Rollout stuck after an image change.**
A `ReadWriteOnce` volume plus `maxUnavailable: 0` means the old pod holds the
volume until the new one is ready, and the new pod may be waiting on a volume
another node already has. Use `strategy.type=Recreate`, ReadWriteMany storage, or
raise `maxUnavailable` to 1.

**Probes fail with 404 or a wrong site.**
Set `ghost.probeHost` to the host Ghost serves, and check that `ghost.url` has
the scheme (`https://`). Set `ghost.readinessProbe.scheme=HTTPS` when the
probes must go through TLS.

**MySQL will not start.**
`kubectl logs -n ghost <pod> -c mysql-init` for the ownership fix, then the
`mysql` container. Check that the claim is bound, and that
`mysql.auth.*` values are the ones the database was initialised with: the
MySQL image only applies them on first start, so changing them later needs a
manual `ALTER USER`.

**TLS never becomes valid.**
With `ingress.tls.mode=manual`, create the secret yourself or set
`ingress.tls.certificate` and `ingress.tls.key`. `NOTES.txt` says so at install
time.

## Security notes

- Ghost runs as UID 65532 with a read-only root filesystem, all capabilities
  dropped and no service account token mounted.
- MySQL runs as UID 65532, Valkey as UID 999, both with dropped capabilities.
- Every pod sets `seccompProfile: RuntimeDefault` and `fsGroup: 65532`.
- Containers that must start as root set `runAsNonRoot: false` explicitly. A
  container that inherits `runAsNonRoot: true` without an explicit
  `runAsUser` is rejected by the kubelet unless its image declares a non-root
  user, so the opt-in init containers carry that override.
- The MySQL pod still starts with a root init container by default, which the
  restricted Pod Security Standard rejects. Set
  `mysql.initContainer.enabled=false` to drop it and rely on `fsGroup`.
- Credentials live in values, Helm release secrets and rendered Secrets. Prefer
  `mysql.auth.existingSecret`, `valkey.auth.existingSecret` and
  `ghost.config.existingSecret` when a secret manager is available.

## Uninstall

```bash
helm uninstall my-ghost -n ghost
```

Claims are not deleted with the release:

```bash
kubectl delete pvc -n ghost -l app.kubernetes.io/instance=my-ghost
```
