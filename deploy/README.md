# Deploying Ghost on Kubernetes with Kustomize

The manifests in this directory are consumed with [Kustomize](https://kustomize.io/):

```
deploy/
├── kustomization.yaml          # default entry point -> base (kubectl apply -k deploy/)
├── base/                       # the plain manifests, one base for every overlay
│   ├── kustomization.yaml
│   └── 00-namespace.yaml ... 07-ingress.yaml
├── components/                 # reusable, opt-in building blocks
│   ├── external-mysql/
│   ├── external-valkey/
│   ├── ingress-nginx/
│   ├── ingress-cert-manager/
│   └── ha/
└── overlays/                   # environment / scenario variations
    ├── development/
    ├── production/
    └── external-services/
```

If you prefer a fully parameterized install, use the Helm chart instead
(`Charts/ghost-on-kubernetes`). Kustomize has no templating: overlays are plain
patches.

## Prerequisites

* `kustomize` v5 or newer, or `kubectl` v1.24+ (which embeds Kustomize).
* A StorageClass, unless you set one explicitly (see below).

Render without applying to inspect the result:

```bash
kubectl kustomize deploy/overlays/production
# or
kustomize build deploy/overlays/production
```

## Quick start

```bash
# Base defaults (same objects as the old per-file kubectl apply sequence):
kubectl apply -k deploy/

# A ready-made example overlay:
kubectl apply -k deploy/overlays/production
```

## The base

`deploy/base/` holds the same 15 objects as before (the files were only moved):

| File | Objects |
| :---- | :---- |
| 00-namespace.yaml | Namespace `ghost-on-kubernetes` |
| 01-mysql-config.yaml, 01-tls.yaml, 01-valkey-config.yaml, 04-ghost-config.yaml | Secrets |
| 02-pvc.yaml | 3 PersistentVolumeClaims |
| 03-service.yaml | 3 Services |
| 05-mysql.yaml | StatefulSet `ghost-on-kubernetes-mysql` |
| 05-valkey.yaml | Deployment `ghost-on-kubernetes-valkey` |
| 06-ghost-deployment.yaml | Deployment `ghost-on-kubernetes` |
| 07-ingress.yaml | Ingress `ghost-on-kubernetes-ingress` |

Every object sets `metadata.namespace: ghost-on-kubernetes`. Editing the base is
still the recommended way to change values for a single deployment.

## Overlays

| Overlay | What it does |
| :---- | :---- |
| `overlays/development` | Removes the pinned `storageClassName` so the cluster default is used, and serves the site on `http://ghost.localhost` without TLS. Single replica. |
| `overlays/production` | Sets storage class `standard` + 10Gi, larger Ghost resources, `https://blog.example.com` in both the Ingress and Ghost's config, TLS from `tls-secret`. |
| `overlays/external-services` | Removes the in-cluster MySQL and Valkey workloads (and their PVCs, Services, Secrets) and repoints Ghost at external MySQL and Valkey/Redis endpoints. |

**Every value in these overlays is a placeholder.** Review them (domain, storage
class, credentials) before applying.

## Components

Components are reusable patch bundles. Reference them from any overlay:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
components:
  - ../../components/ingress-nginx
```

| Component | What it does |
| :---- | :---- |
| `external-mysql` | Deletes the MySQL Secret/StatefulSet/Service/PVC and points Ghost at an external MySQL server. |
| `external-valkey` | Deletes the Valkey Secret/Deployment/Service/PVC and points Ghost at an external Valkey/Redis server. |
| `ingress-nginx` | Switches the Ingress class from Traefik to NGINX. |
| `ingress-cert-manager` | Removes the placeholder TLS Secret, adds a cert-manager `Certificate` and annotates the Ingress. Requires the cert-manager CRDs. |
| `ha` | Runs 2 Ghost replicas and switches the content PVC to `ReadWriteMany`. |

**`external-mysql` and `external-valkey` cannot be combined in the same overlay.**
Each one rewrites the whole `stringData["config.production.json"]` value, so the
last patch applied would win and drop the other change. Use
`overlays/external-services` when both services are external, or copy that
overlay and edit its single config patch.

## Writing your own overlay

```bash
mkdir -p deploy/overlays/my-blog
```

`deploy/overlays/my-blog/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../base
components:
  - ../../components/ingress-nginx
patches:
  # All PVCs: use my StorageClass and 20Gi.
  - target:
      kind: PersistentVolumeClaim
    patch: |-
      - op: replace
        path: /spec/storageClassName
        value: my-storage-class
      - op: replace
        path: /spec/resources/requests/storage
        value: 20Gi
  # One named object: the file must live inside this overlay directory.
  - path: ingress-patch.yaml
    target:
      kind: Ingress
      name: ghost-on-kubernetes-ingress
```

Then `kubectl apply -k deploy/overlays/my-blog`.

Patch files live under the overlay that uses them - the default Kustomize load
restrictor rejects patch files or manifests referenced from above the overlay
root, which is why shared logic is packaged as components instead.

## Common tasks

### Change the storage class or size

Patch every PVC with a JSON6902 patch that has no `name`, as in the example
above, or set a class on one PVC only by adding a `name`.

The base pins `storageClassName: ""`, which disables dynamic provisioning. Use
`- op: remove` to fall back to the cluster default instead.

### Change the domain, mail or database settings

Ghost reads one JSON file, `config.production.json`, stored in the
`ghost-config-prod` Secret. A single JSON value cannot be partially patched, so
an overlay has to replace the whole value. Copy
`deploy/base/04-ghost-config.yaml` into a patch file in your overlay, change the
values, and reference it:

```yaml
patches:
  - path: ghost-config-patch.yaml
    target:
      kind: Secret
      name: ghost-config-prod
```

`ghost-config-patch.yaml` looks like:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghost-config-prod
  namespace: ghost-on-kubernetes
type: Opaque
stringData:
  config.production.json: |-
    { ... full config ... }
```

The shipped overlays/components do exactly this; CI checks that every config
patch keeps the same top-level keys as the base secret so the copies cannot
silently drift.

### Provide real credentials

Do not commit secrets. Put them in a patch file whose name contains `.local`
(for example `secrets.local.yaml`) - `.gitignore` already excludes
`***/*.local*` - and reference it from the overlay:

```yaml
patches:
  - path: secrets.local.yaml
    target:
      kind: Secret
      name: ghost-on-kubernetes-valkey-env
```

`secretGenerator` with `behavior: merge` does **not** merge into secrets that
the base defines as resources, so use patches.

### Change the namespace

Set `namespace:` and replace the base Namespace object (Kustomize rewrites
`metadata.namespace` but does not rename the Namespace itself):

`deploy/overlays/my-ghost/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: my-ghost
resources:
  - ../../base
  - namespace.yaml
patches:
  - target:
      kind: Namespace
      name: ghost-on-kubernetes
    patch: |-
      $patch: delete
      apiVersion: v1
      kind: Namespace
      metadata:
        name: ghost-on-kubernetes
```

`namespace.yaml` is a plain Namespace named `my-ghost`. Ghost talks to MySQL and
Valkey through short in-namespace service names, so no other reference needs to
change.

### Enable high availability

```yaml
components:
  - ../../components/ha
patches:
  - target:
      kind: PersistentVolumeClaim
    patch: |-
      - op: replace
        path: /spec/storageClassName
        value: my-rwx-storage-class
```

`k8s-ghost-content` must be `ReadWriteMany`; Ghost itself does not officially
support clustering (see the note in `base/02-pvc.yaml`).

## Conventions and limitations

* **Patch files must carry `metadata.namespace`** when they are not attached to a
  `target:` selector; the base sets the namespace explicitly and a namespace-less
  patch will fail with `no resource matches strategic merge patch`.
* **Do not use `namePrefix` or `nameSuffix`.** Ghost's `config.production.json`,
  the Ingress backend, the volume and the secret references contain literal
  object names that Kustomize cannot rewrite.
* **Prefer `target:` selectors.** A JSON6902 patch whose target has no `name`
  applies to every match: handy for the three PVCs, wrong for `kind: Deployment`
  (Ghost and Valkey).
* **Config patches replace the whole JSON** - see above.
* **cert-manager resources** are not part of the Kubernetes core schemas; validate
  them with `kubeconform -ignore-missing-schemas`.

## Migration from the per-file apply sequence

Nothing was deleted; the manifests moved into `base/`.

| Before | Now |
| :---- | :---- |
| `kubectl apply -f deploy/00-namespace.yaml` | `kubectl apply -f deploy/base/00-namespace.yaml` |
| `kubectl apply -f deploy/01-... deploy/02-... ...` (manual order) | `kubectl apply -k deploy/` |
| `kubectl apply -f deploy/06-ghost-deployment.yaml` | `kubectl apply -f deploy/base/06-ghost-deployment.yaml` |

Applying the individual files in order still works, from `deploy/base/`.

## Validating changes

```bash
for t in deploy deploy/base deploy/overlays/*; do kustomize build "$t" >/dev/null || echo "FAILED $t"; done
kustomize build deploy/base | kubeconform -strict -ignore-missing-schemas -summary -
```

The `Kustomize Validation` workflow runs the same checks on pull requests that
touch `deploy/**`.
