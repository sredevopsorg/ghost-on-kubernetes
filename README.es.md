# Ghost en Kubernetes por [SREDevOps](https://sredevops.org)

[![Construir y enviar imagen a DockerHub y GitHub Container Registry](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml/badge.svg)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml)

Este repositorio implementa un Ghost CMS v5.xx.x limpio desde [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) en Kubernetes, como una Implementación utilizando nuestra [imagen personalizada](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile) construida sobre la imagen oficial de Ghost 5 debian, pero con algunas modificaciones:

## Cambios recientes

Hemos realizado algunas actualizaciones significativas para mejorar la seguridad y la eficiencia de nuestra implementación de Ghost en Kubernetes:

1. **Imagen base Distroless**: La imagen de contenedor de Ghost ahora se basa en una imagen base Distroless. Esto reduce la superficie de ataque eliminando componentes innecesarios como shell, gestores de paquetes y utilidades que no son necesarios para que nuestra aplicación se ejecute. La imagen también se construye utilizando un proceso de varias etapas, lo que hace que la imagen final sea más pequeña y segura.

2. **StatefulSet de MySQL**: Hemos cambiado la implementación de MySQL de nuevo a un StatefulSet. Esto proporciona identificadores de red estables y almacenamiento persistente, lo que es importante para las bases de datos como MySQL que necesitan mantener estado.

3. **Usuario sin privilegios**: Por defecto, el contenedor de Ghost ahora se ejecuta como un usuario sin privilegios. Esto es una buena práctica de seguridad, ya que reduce el potencial daño si el contenedor se ve comprometido. La aplicación Ghost se inicia con un contenedor de inicialización, que realiza tareas de configuración necesarias antes de que comience el contenedor Ghost principal.

Consulte el archivo `06-ghost-deployment.yaml` actualizado para los detalles de implementación de estos cambios.

## Características

- Utilizamos la imagen de entorno de construcción Node 18 Hydrogen bookworm ligera.
- Introdujo una compilación de varias etapas para compilar la imagen.
- [distroless node 18 debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) como la imagen final.
- Eliminamos gosu, utilizamos el usuario predeterminado node.
- ~~Modificamos la entrada para ejecutar como usuario node, por lo que podemos ejecutar el pod como no root.~~ DELETED ENTRYPOINT
- Actualizamos todas las dependencias posibles en la imagen base para minimizar las vulnerabilidades.
- Actualizamos npm y ghost-cli a las últimas versiones en cada compilación.
- Utilizamos la última versión de Ghost 5 (en el momento de construir la imagen)

> *Nota para los usuarios de ARM 📌: En este momento, hemos eliminado el soporte para arm64 y armv7l [(enlace a la discusión)](https://github.com/sredevopsorg/ghost-on-kubernetes/issues/73#issuecomment-1933939315), pero lo agregaremos nuevamente pronto. Las solicitudes de extracción son bienvenidas._* 

## Historial de estrellas

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" />
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" height="300px" />
</picture>

## Instalación

## 1. Clonar el repositorio

```bash
# Clonar el repositorio
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Cambiar de directorio
cd ghost-on-kubernetes
# Crear una nueva rama para sus cambios en modo desasociado (opcional pero recomendado).
git checkout -b my-branch --no-track --detach

```

## 2. Revisar los valores predeterminados y realizar cambios según sea necesario en los siguientes archivos

- deploy/00-namespace.yaml

- deploy/01-secrets.yaml

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysql-ghost-k8s
      namespace: ghost-k8s
    type: Opaque
    stringData:
      MYSQL_DATABASE: mysql-db-name # Igual que en deploy/04-config.production.yaml
      MYSQL_USER: mysql-db-user # Igual que en deploy/04-config.production.yaml
      MYSQL_PASSWORD: mysql-db-password # Igual que en deploy/04-config.production.yaml
      MYSQL_ROOT_PASSWORD: mysql-db-root-password # Igual que en deploy/04-config.production.yaml
    ```

- deploy/02-pvc.yaml # Cambie el storageClassName según sus requisitos
- deploy/03-services.yaml # Cambie los hosts según sus requisitos
- deploy/04-config.production.yaml # Cambie los valores según los secretos y los servicios
- deploy/05-mysql.yaml # Cambie los valores según los secretos y los servicios
- deploy/06-ghost-deployment.yaml # Cambie los valores según los secretos y los servicios
- deploy/07-ingress.yaml # Opcional

## 3. Aplicar sus manifestaciones

```bash
# Crear el espacio de nombres
kubectl apply -f deploy/00-namespace.yaml
# Crear los secretos
kubectl apply -f deploy/01-secrets.yaml
# Crear el volumen persistente
kubectl apply -f deploy/02-pvc.yaml
# Crear servicios
kubectl apply -f deploy/03-service.yaml
# Crear la configuración de Ghost
kubectl apply -f deploy/04-config.production.yaml
# Crear la base de datos de MySQL
kubectl apply -f deploy/05-mysql.yaml
# Crear la implementación de Ghost
kubectl apply -f deploy/06-ghost-deployment.yaml
# Crear el Ingreso de Ghost
kubectl apply -f deploy/07-ghost-ingress.yaml
```

## 4. Acceda a su Ghost CMS

```bash
# Obtener la dirección IP de ingress
kubectl get ing -n ghost-k8s -o wide 

# O cree un reenvío de puerto para acceder al Ghost CMS
kubectl port-forward -n ghost-k8s svc/ghost-k8s 2368:2368

```

## 5. Abra su navegador y acceda al Ghost CMS

[http://localhost:2368](http://localhost:2368)

## 6. Inicie sesión en su Ghost CMS

[http://localhost:2368/ghost](http://localhost:2368/ghost)
