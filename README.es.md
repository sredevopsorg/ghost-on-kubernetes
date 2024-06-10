# Ghost en Kubernetes por [SREDevOps.Org](https://sredevops.org)

<center><a href="https://sredevops.org" target="_blank" rel="noopener noreferrer"><img src="https://github.com/sredevopsdev/.github/assets/34670018/6878e00f-635c-4553-8df7-3b20406fdb4f" alt="SREDevOps.org" width="60%" align="center" /></a></center>

## Comunidad Site Reliability Engineering (SRE), DevOps, Cloud Native, GNU/Linux y más.  🌎

[![CI Multibuild](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) | [![Tamaño de la imagen](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes/208368831?tag=main)

Este repositorio implementa Ghost CMS v5.xx.x de [@TryGhost (upstream)](https://github.com/TryGhost/Ghost) en Kubernetes, como una implementación utilizando nuestra [imagen personalizada](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile), basada en la imagen oficial de Ghost 5 debian ["oficial"](https://github.com/docker-library/ghost/blob/master/5/debian/Dockerfile), con modificaciones importantes, como:

## Cambios recientes

Hemos realizado algunas actualizaciones significativas para mejorar la seguridad y la eficiencia de nuestra implementación de Ghost en Kubernetes:

1. **Imagen base Distroless**: La imagen del contenedor de Ghost ahora se basa en una imagen base Distroless. Esto reduce la superficie de ataque eliminando componentes innecesarios como shell, gestores de paquetes y utilidades que no son necesarios para que nuestra aplicación se ejecute. La imagen también se construye mediante un proceso de compilación de varias etapas, lo que hace que la imagen final sea más pequeña y más segura.

2. **StatefulSet de MySQL**: Hemos cambiado la implementación de MySQL de nuevo a un StatefulSet. Esto proporciona identificadores de red estables y almacenamiento persistente, lo que es importante para las bases de datos como MySQL que necesitan mantener estado.

3. **Usuario sin privilegios**: Por defecto, el contenedor de Ghost ahora se ejecuta como un usuario sin privilegios. Esto es una buena práctica de seguridad, ya que reduce el potencial daño si el contenedor se compromete. La aplicación Ghost se inicia con un contenedor de inicialización, que realiza tareas de configuración necesarias antes de que comience el contenedor principal de Ghost.

Consulta el archivo de implementación actualizado [deploy/06-ghost-deployment.yaml](deploy/06-ghost-deployment.yaml) para los detalles de implementación de estos cambios.

## Características

- [Soporte ARM64!](#arm64-supported)
- Utilizamos la imagen de Node 20 Iron Buster oficial como entorno de compilación.
- Se introduce un proceso de compilación de varias etapas para compilar la imagen.
- [distroless node 20 debian 12](https://github.com/GoogleContainerTools/distroless/blob/main/README.md) como entorno de ejecución para la imagen final.
- Se eliminó gosu, utilizamos el usuario node predeterminado.
- Nuevo proceso de Entrypoint, utilizando un script en node.js ejecutado por el usuario node sin privilegios dentro del contenedor distroless. 
- Utilizamos la última versión de Ghost 5 (cuando se construye la imagen).

## 📌 ARM64 compatible

- Las imagenes ahora son multiarch, con soporte amd64 y arm64 [(enlace a la discusión)](https://github.com/sredevopsorg/ghost-on-kubernetes/issues/73#issuecomment-1933939315)

## Historial de estrellas

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" />
  <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date" height="300px" />
</picture>

## Instalación

## 0. Clonar el repositorio

```bash
# Clonar el repositorio
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
# Cambiar de directorio
cd ghost-on-kubernetes
# Crear una nueva rama para sus cambios en modo desasociado (opcional pero recomendado).
git checkout -b my-branch --no-track --detach

```

## 1. Comprobar las configuraciones de ejemplo

- Hay algunos archivos de configuración de ejemplo en el [directorio `examples`](./examples/). Utilizamos la configuración almacenada como `kind: Secret` en el espacio de nombres `ghost-on-kubernetes` para la configuración de Ghost y MySQL. Existen dos archivos de configuración de ejemplo:

  - `config.development.sample.yaml`: Este archivo de configuración es para el entorno de desarrollo de Ghost. Utiliza SQLite como base de datos. Puede ser útil si desea probar la configuración de Ghost antes de implementarla en un entorno de producción.
  
  - `config.production.sample.yaml`: Este archivo de configuración es para el entorno de producción de Ghost. Utiliza MySQL 8, y es el archivo de configuración recomendado para entornos de producción. Requiere TLD (dominio de nivel superior) válido y la [configuración de Ingress para acceder a Ghost desde Internet.](./deploy/07-ingress.yaml)

- Si necesitas más información sobre la configuración, consulte la [documentación oficial de Ghost](https://ghost.org/docs/config/#custom-configuration-files).

## 2. Revisar los valores predeterminados y realizar cambios según sea necesario en los siguientes archivos

- deploy/00-namespace.yaml

- deploy/01-secrets.yaml

    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: mysql-ghost-on-kubernetes
      namespace: ghost-on-kubernetes
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

## 4. Acceder a su Ghost CMS

```bash
# Obtener la dirección IP de entrada
kubectl get ing -n ghost-on-kubernetes -o wide 

# O bien, cree un reenvío de puertos para acceder al Ghost CMS
kubectl port-forward -n ghost-on-kubernetes svc/ghost-on-kubernetes 2368:2368

```

## 5. Abra su navegador y acceda al Ghost CMS

[http://localhost:2368](http://localhost:2368)

## 6. Inicie sesión en su Ghost CMS

[http://localhost:2368/ghost](http://localhost:2368/ghost)
