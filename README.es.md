# Ghost en Kubernetes por SREDevOps.Org

[![SREDevOps.org](https://github.com/sredevopsorg/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f)](https://sredevops.org)

**Comunidad para SRE, DevOps, Cloud Native, GNU/Linux, y más. 🌎**

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888) [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ghost-on-kubernetes)](https://artifacthub.io/packages/search?repo=ghost-on-kubernetes)

## Introducción

Este repositorio implementa Ghost CMS v5.xx.x desde [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) en Kubernetes, con nuestra imagen personalizada, la cual tiene mejoras significativas para ser usada en Kubernetes [(Dockerfile)](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile). Vea este README completo para más información.

## Características

- Tanto los componentes de Ghost como los de MySQL se ejecutan como usuario sin privilegios de root en Kubernetes, lo que mejora significativamente la seguridad, además de las mejoras de nuestra imagen personalizada.
- Soporte multi-arquitectura (amd64 y arm64).
- Usamos la imagen oficial de Node 20 Iron Bookworm como nuestro entorno de construcción. [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile).
- Introducimos una *build multi-stage*, que reduce el tamaño final de la imagen y mejora la seguridad al eliminar componentes innecesarios de la imagen final.
- [Distroless Node 20 Debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) como nuestro entorno de ejecución para la etapa final de la imagen.
- Se eliminó *gosu*, ahora todo se ejecuta como usuario sin privilegios de root (UID/GID 65532) dentro del contenedor Distroless. Este cambio por sí solo reduce 6 vulnerabilidades críticas y 34 vulnerabilidades altas reportadas por Docker Scout en la imagen original de Ghost. Referencias:

  - [Imagen Oficial de Ghost](https://hub.docker.com/_/ghost/tags)

    ![Docker Scout Report - Ghost Official Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ghost.png)

  - [Imagen de Ghost en Kubernetes en Docker Hub](https://hub.docker.com/r/ngeorger/ghost-on-kubernetes/tags)

    ![Docker Scout Report - Ghost on Kubernetes Image](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ngeorger.png)

- Nuevo flujo de *Entrypoint*, utilizando un script Node.js ejecutado por el usuario Node sin privilegios dentro del contenedor Distroless, que actualiza los temas predeterminados y inicia la aplicación Ghost, operación que se realiza dentro del contenedor Distroless en tiempo de ejecución.
- Usamos la última versión de Ghost 5 (al momento de construir la imagen).


## Cambios Recientes

Hemos realizado algunas actualizaciones significativas para mejorar la seguridad y eficiencia de nuestra implementación de Ghost en Kubernetes:

1. **Soporte multi-arquitectura**: Las imágenes ahora son multi-arquitectura, con soporte para amd64 y arm64.
2. **Imagen Distroless**: Usamos [Distroless NodeJS](https://github.com/GoogleContainerTools/distroless/blob/main/examples/nodejs/Dockerfile) de [@GoogleContainerTools](https://github.com/GoogleContainerTools) como entorno de ejecución para la imagen final. Las imágenes Distroless son imágenes mínimas que contienen solo los componentes necesarios para ejecutar la aplicación, haciéndolas más seguras y eficientes que las imágenes tradicionales.
3. **MySQL StatefulSet**: Hemos cambiado la implementación de MySQL a un StatefulSet. Esto proporciona identificadores de red estables y almacenamiento persistente, lo cual es importante para bases de datos como MySQL que necesitan mantener el estado.
4. **Contenedor Init**: Hemos agregado un contenedor init al *Deployment* de Ghost. Este contenedor se encarga de configurar los archivos y directorios necesarios antes de que se inicie el contenedor principal de Ghost, asegurando que se creen los directorios correctos, la propiedad correcta para el usuario *node* dentro del contenedor *distroless* UID/GID a 65532, y que se establezcan los permisos correctos. Revisar [deploy/06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml) para detalles sobre estos cambios.
5. **Script de Entrypoint**: Hemos introducido un nuevo script de *entrypoint* que se ejecuta como usuario sin privilegios dentro del contenedor *distroless*. Este script se encarga de actualizar los temas predeterminados y luego inicia la aplicación Ghost. Este script es ejecutado por el usuario sin privilegios dentro del contenedor Distroless, el cual actualiza los temas por defecto y arranca la aplicación Ghost, operación que se realiza dentro del contenedor distroless en tiempo de ejecución. [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js)


## Historial de Estrellas

![Star History Chart](https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark)

## Instalación

### 0. Clonar el repositorio o hacerle un fork

```bash
# Clonar el repositorio
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Cambiar de directorio
cd ghost-on-kubernetes
# Crear una nueva rama para tus cambios (opcional pero recomendado).
git checkout -b my-branch --no-track --detach
```

### 1. Revisar los archivos de configuración de ejemplo

- Hay algunos archivos de configuración de ejemplo en el directorio [examples](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/).  Usamos la configuración almacenada como un `kind: Secret` en el namespace `ghost-on-kubernetes` para la configuración de Ghost y MySQL. Hay dos ejemplos de archivos de configuración:
  - `config.development.sample.yaml`: Este archivo de configuración es para el entorno de desarrollo de Ghost.  Utiliza SQLite como base de datos. Puede ser útil si quieres probar la configuración de Ghost antes de implementarla en un entorno de producción.
  - `config.production.sample.yaml`: Este archivo de configuración es para el entorno de producción de Ghost.  Utiliza MySQL 8, y es la configuración recomendada para entornos de producción. Requiere un dominio de nivel superior (TLD) válido y  [configuración para Ingress para acceder a Ghost desde Internet](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml).
- Si necesitas más información sobre la configuración, revisa la [documentación oficial de Ghost](https://ghost.org/docs/config/#custom-configuration-files).


### 2. Revisar los valores por defecto y realizar cambios según sea necesario

### Entendiendo la Arquitectura del Deployment de Ghost en Kubernetes

Implementar una aplicación sofisticada como Ghost en Kubernetes implica orquestar varios componentes. Desglosemos los recursos esenciales de Kubernetes que usaremos:

### Namespaces: Aislando Nuestra Instancia de Ghost

Los namespaces en Kubernetes proporcionan una separación lógica de los recursos. Usaremos el namespace `ghost-on-kubernetes` para contener todos los recursos relacionados con nuestro deployment de Ghost. Este enfoque mejora la organización y previene conflictos de recursos con otras aplicaciones que se ejecutan en el mismo clúster.

Archivo: [deploy/00-namespace.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/00-namespace.yaml)

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ghost-on-kubernetes
  labels:
    app: ghost-on-kubernetes
    # ... other labels
```

### Secrets: Almacenando de Forma Segura la Información Sensible

Los secrets en Kubernetes nos permiten almacenar y administrar datos sensibles, como credenciales de bases de datos y certificados TLS, de forma segura. Usaremos los siguientes Secrets:

- `ghost-config-prod`: Almacena la configuración de Ghost, incluyendo los detalles de conexión a la base de datos y la configuración del servidor de correo.
- `ghost-on-kubernetes-mysql-env`: Contiene variables de entorno para la base de datos MySQL, incluyendo el nombre de la base de datos, el nombre de usuario y la contraseña.
- `tls-secret`: Contiene el certificado TLS y la clave para habilitar HTTPS en nuestro blog Ghost.

Archivo: [deploy/01-mysql-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-mysql-config.yaml)

Archivo: [deploy/04-ghost-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/04-ghost-config.yaml)

Archivo: [deploy/01-tls.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-tls.yaml)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ghost-config-prod
  namespace: ghost-on-kubernetes
  # ... other metadata
type: Opaque
stringData:
  config.production.json: |-
    {
      # ... Ghost configuration
    }
```

### PersistentVolumeClaims: Almacenamiento Persistente para Nuestro Blog

Los PersistentVolumeClaims (PVCs) en Kubernetes nos permiten solicitar volúmenes de almacenamiento persistente. Usaremos dos PVCs:

- `k8s-ghost-content`: Proporciona almacenamiento persistente para el contenido de Ghost, incluyendo imágenes, temas y archivos subidos.
- `ghost-on-kubernetes-mysql-pvc`: Ofrece almacenamiento persistente para la base de datos MySQL, asegurando la persistencia de los datos a través de reinicios y reprogramaciones de pods.


Archivo: [deploy/02-pvc.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/02-pvc.yaml)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: k8s-ghost-content
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... PVC specification
```

### Services: Exponiendo Ghost y MySQL Dentro del Clúster

Los Services en Kubernetes proporcionan una forma de exponer nuestras aplicaciones que se ejecutan en un conjunto de pods como un servicio de red. Definiremos dos services:

- `ghost-on-kubernetes-service`: Expone la aplicación Ghost internamente dentro del clúster en el puerto 2368.
- `ghost-on-kubernetes-mysql-service`: Expone la base de datos MySQL internamente en el puerto 3306, permitiendo que la aplicación Ghost se conecte a la base de datos.

Archivo: [deploy/03-service.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/03-service.yaml)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: ghost-on-kubernetes-service
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Service specification
```

### StatefulSet: Administrando la Base de Datos MySQL

Un StatefulSet en Kubernetes está diseñado para administrar aplicaciones con estado, como bases de datos, que requieren almacenamiento persistente e identidades de red estables. Usaremos un StatefulSet para implementar una única réplica de la base de datos MySQL.

Archivo: [deploy/05-mysql.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/05-mysql.yaml)

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ghost-on-kubernetes-mysql
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... StatefulSet specification
```

### Deployment: Administrando la Aplicación Ghost

Los Deployments en Kubernetes administran la implementación y el escalado de aplicaciones sin estado. Usaremos un Deployment para implementar una única réplica de la aplicación Ghost.

Archivo: [deploy/06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ghost-on-kubernetes
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Deployment specification
```

### Ingress: Exponiendo Ghost al Mundo Exterior

Un recurso Ingress en Kubernetes actúa como un proxy inverso, enrutando el tráfico externo a los servicios dentro del clúster. Usaremos un Ingress para exponer nuestro blog Ghost a Internet utilizando un nombre de dominio.

Archivo: [deploy/07-ingress.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ghost-on-kubernetes-ingress
  namespace: ghost-on-kubernetes
  # ... other metadata
spec:
  # ... Ingress specification
```


## Uniéndolo todo: Implementando Ghost en Kubernetes

Con nuestros recursos de Kubernetes definidos, ahora podemos implementar Ghost en nuestro clúster. Sigue estos pasos generales:

1. **Crear el Namespace:**

   ```bash
   kubectl apply -f deploy/00-namespace.yaml
   ```

2. **Crear los Secrets:**

   ```bash
   kubectl apply -f deploy/01-mysql-config.yaml
   kubectl apply -f deploy/04-ghost-config.yaml
   kubectl apply -f deploy/01-tls.yaml
   ```

3. **Crear los PersistentVolumeClaims:**

   ```bash
   kubectl apply -f deploy/02-pvc.yaml
   ```

4. **Crear los Services:**

   ```bash
   kubectl apply -f deploy/03-service.yaml
   ```

5. **Implementar la base de datos MySQL:**

   ```bash
   kubectl apply -f deploy/05-mysql.yaml
   ```

6. **Implementar la aplicación Ghost:**

   ```bash
   kubectl apply -f deploy/06-ghost-deployment.yaml
   ```

7. **Exponer Ghost con Ingress (Opcional):**

   ```bash
   kubectl apply -f deploy/07-ingress.yaml
   ```

## ¡Tu blog Ghost está en vivo!

¡Felicitaciones! Has implementado con éxito Ghost en un clúster de Kubernetes. Esta configuración proporciona una base sólida y escalable para tu plataforma de blogs. Recuerda personalizar las configuraciones, como la clase de almacenamiento, los límites de recursos y el nombre de dominio, para que se ajusten a tus requisitos específicos.


## Contribuyendo

¡Agradecemos las contribuciones de la comunidad! Por favor, revisa el archivo [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md) para obtener más información sobre cómo contribuir a este proyecto.


## Licencia y Créditos

- Este proyecto está licenciado bajo la Licencia MIT. Por favor, revisa el archivo [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE) para más información.
- El Ghost CMS está licenciado bajo la [Licencia MIT](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
- La imagen de Node y la imagen de Distroless están licenciadas por sus respectivos propietarios.
