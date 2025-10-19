# Ghost en Kubernetes por SREDevOps.Org

[![SREDevOps.org](https://github.com/sredevopsorg/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f)](https://www.sredevops.org)

_**SREDevOps.org**: SRE, DevOps, Linux, Ethical Hacking, AI, ML, Open Source, Cloud Native, Platform Engineering en Español, Portugués (Brasil) y English_

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888) [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ghost-on-kubernetes)](https://artifacthub.io/packages/search?repo=ghost-on-kubernetes)

## Introducción

Este repositorio implementa **Ghost CMS v6.xx.x** desde [@TryGhost (Oficial)](https://github.com/TryGhost/Ghost) en **Kubernetes**, usando nuestra imagen personalizada con mejoras significativas diseñadas para su uso en Kubernetes [(Dockerfile)](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile). Revisa todo este README para más información.

## Características

- Tanto **Ghost** como **MySQL** se ejecutan como usuarios *non-root* en Kubernetes, mejorando considerablemente la seguridad, junto con otras mejoras en la imagen personalizada.
- Soporte **multi-arch** (amd64 y arm64).
- Se usa la imagen oficial **Node 22 Jod LTS** como entorno de build. [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile#L5).
- Implementa un **multi-stage build**, reduciendo el tamaño final de la imagen y mejorando la seguridad al eliminar componentes innecesarios.
- Usa **[Distroless Node 22 Debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md)** como entorno de runtime en la imagen final.
- La imagen oficial de Ghost usaba *gosu*, pero fue removido en favor de una ejecución nativa sin privilegios dentro del contenedor. Todo corre como usuario *non-root* (UID/GID 65532) en el contenedor **Distroless**. Este cambio reduce 6 vulnerabilidades críticas y 34 altas reportadas por Docker Scout en la imagen oficial de Ghost.

  - Ejemplo de escaneo para la [Imagen Oficial de Ghost](https://hub.docker.com/_/ghost/tags)

    ![Docker Scout Report - Ghost Official Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ghost.png)

  - Ejemplo de nuestra [Imagen Ghost on Kubernetes en Docker Hub](https://hub.docker.com/r/ngeorger/ghost-on-kubernetes/tags)

    ![Docker Scout Report - Ghost on Kubernetes Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ngeorger.png)

- Nuevo **Entrypoint** basado en script **Node.js** ejecutado por el usuario sin privilegios dentro del contenedor **Distroless**, que actualiza los temas por defecto y lanza la aplicación Ghost.
- Se usa siempre la última versión de Ghost 6 al momento del build.

## Cambios recientes

Actualizaciones clave para mejorar la seguridad y eficiencia de Ghost en Kubernetes:

- **Ghost v6 actualizado**: Usamos la nueva versión, revisa la [documentación oficial](https://docs.ghost.org/update).
- **NodeJS actualizado**: Desde Iron LTS (Node v20) a Jod LTS (Node v22).
- **Soporte multi-arch**: Imágenes para amd64 y arm64.
- **Imagen Distroless**: Basada en [@GoogleContainerTools](https://github.com/GoogleContainerTools), solo con los componentes necesarios para ejecutar la app.
- **MySQL StatefulSet**: Ahora MySQL se ejecuta como StatefulSet, lo que permite almacenamiento persistente y redes estables.
- **Init Container**: Nuevo init container que prepara configuraciones, permisos y directorios antes de iniciar Ghost. Ver [deploy/06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml).
- **Entrypoint Script**: Script NodeJS que corre como usuario *non-root* dentro del contenedor Distroless para actualizar temas y lanzar Ghost. [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)

## Instrucciones de instalación

### 0. Clonar el repositorio

```bash
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
cd ghost-on-kubernetes
git checkout -b my-branch --no-track --detach
```

### 1. Revisar configuraciones de ejemplo

Los archivos de ejemplo están en [examples](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/):

- `config.development.sample.yaml`: Configuración para desarrollo, usa SQLite.
- `config.production.sample.yaml`: Configuración para producción, usa MySQL 8. Requiere dominio válido y [Ingress configurado](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml).

Más detalles en la [documentación oficial de Ghost](https://ghost.org/docs/config/#custom-configuration-files).

### 2. Editar valores según tus necesidades

Revisa cada manifiesto dentro de [deploy/](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/).

### Arquitectura de despliegue Ghost en Kubernetes

Ghost requiere varios recursos Kubernetes:

#### Namespace

Aisla recursos en `ghost-on-kubernetes`.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ghost-on-kubernetes
```

#### Secrets

Guarda datos sensibles como contraseñas y certificados TLS.

- `ghost-config-prod`
- `ghost-on-kubernetes-mysql-env`
- `tls-secret`

#### PersistentVolumeClaims

Permite almacenamiento persistente para contenido Ghost y base de datos MySQL.

#### Services

Expone Ghost y MySQL dentro del clúster.

#### StatefulSet

Administra la base de datos MySQL con almacenamiento persistente.

#### Deployment

Gestiona la aplicación Ghost (stateless).

#### Ingress

Expone Ghost a Internet mediante dominio.

## Despliegue en Kubernetes

Aplica los archivos **en orden**:

```bash
kubectl apply -f deploy/00-namespace.yaml
kubectl apply -f deploy/01-mysql-config.yaml
kubectl apply -f deploy/04-ghost-config.yaml
kubectl apply -f deploy/01-tls.yaml
kubectl apply -f deploy/02-pvc.yaml
kubectl apply -f deploy/03-service.yaml
kubectl apply -f deploy/05-mysql.yaml
kubectl apply -f deploy/06-ghost-deployment.yaml
kubectl apply -f deploy/07-ingress.yaml
```

## Tu blog Ghost está desplegado

Has desplegado Ghost en Kubernetes exitosamente. Personaliza configuraciones según tus necesidades (almacenamiento, recursos, dominio, etc.).

## Acceder sin dominio

Para previsualizar Ghost sin dominio:

Configura `url` y `admin url` como `http://localhost:2368/`, reinicia el pod y usa port-forward:

```bash
kubectl port-forward -n ghost-on-kubernetes services ghost-on-kubernetes-service 2368:2368
```

## Contribuir

Contribuciones son bienvenidas. Revisa [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md).

## Licencia y créditos

- Proyecto bajo **MIT License**. Ver [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE).
- **Ghost CMS** está bajo [MIT License](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
- Las imágenes base (Node y Distroless) pertenecen a sus respectivos autores.

## Historial de estrellas

![Star History Chart](https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark)
