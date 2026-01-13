# **Ghost en Kubernetes (v6.x) por SREDevOps.Org**

Despliega la principal plataforma de publicación de código abierto, **Ghost**, en Kubernetes con la máxima **seguridad** y **eficiencia** utilizando una imagen de contenedor endurecida y multi-arquitectura.

Mantenido por ***[SREDevOps.org](https://www.sredevops.org)**: SRE, DevOps, Linux, Hacking Ético, IA, ML, Código Abierto, Cloud Native, Platform Engineering en Inglés, Español y Portugués (Brasil).*

[![Build Multiarch](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml/badge.svg?branch=main)](https://github.com/sredevopsorg/ghost-on-kubernetes/actions/workflows/multi-build.yaml) [![Image Size](https://ghcr-badge.egpl.dev/sredevopsorg/ghost-on-kubernetes/size?color=%2344cc11&tag=main&label=main+image+size)](https://github.com/sredevopsorg/ghost-on-kubernetes/pkgs/container/ghost-on-kubernetes) [![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/sredevopsorg/ghost-on-kubernetes/badge)](https://securityscorecards.dev/viewer/?uri=github.com/sredevopsorg/ghost-on-kubernetes) [![Fork this repository](https://img.shields.io/github/forks/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/fork) [![Star this repository](https://img.shields.io/github/stars/sredevopsorg/ghost-on-kubernetes?style=social)](https://github.com/sredevopsorg/ghost-on-kubernetes/stargazers) [![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8888/badge)](https://www.bestpractices.dev/projects/8888) [![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/ghost-on-kubernetes)](https://artifacthub.io/packages/search?repo=ghost-on-kubernetes)

## **Aspectos Destacados: Seguridad y Eficiencia**

Este repositorio implementa Ghost CMS v6.xx.x de [@TryGhost (Oficial)](https://github.com/TryGhost/Ghost) en Kubernetes con una imagen personalizada, que ofrece mejoras significativas para el uso en producción y características de seguridad en Kubernetes.

### **Seguridad Mejorada**

* **Ejecución Sin Root:** Tanto los componentes de Ghost como los de MySQL se ejecutan exclusivamente como un **usuario sin privilegios (non-root)** (UID/GID 65532) en Kubernetes, previniendo posibles ataques de escalada de privilegios.
* **Tiempo de Ejecución Distroless:** Utilizamos **Google Container Tools Distroless Debian 13 - NodeJS 22** como el entorno de tiempo de ejecución final. Las imágenes **Distroless** contienen solo las dependencias de la aplicación y el lenguaje requeridas, **excluyendo shells y gestores de paquetes**, lo que las hace sustancialmente más seguras y reduce la superficie de ataque.
* **Reducción de Vulnerabilidades:** Al reemplazar `gosu` con un flujo de ejecución de contenedor nativo y adoptar Distroless, eliminamos varias vulnerabilidades críticas reportadas en la imagen original de Ghost:
  * **Resultado:** Solo este cambio redujo **6 vulnerabilidades críticas** y **34 vulnerabilidades altas** reportadas por Docker Scout en la imagen oficial.

**Ejemplo de Reportes de Seguridad:**

| Imagen Oficial de Ghost | Imagen de Ghost en Kubernetes |
| :---- | :---- |
| Escaneo de ejemplo para la [Imagen Oficial de Ghost](https://hub.docker.com/_/ghost/tags): ![Reporte de Docker Scout - Imagen Oficial de Ghost](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ghost.png) | Ejemplo de nuestra [Imagen de Ghost en Kubernetes en Docker Hub](https://hub.docker.com/r/ngeorger/ghost-on-kubernetes/tags): ![Reporte de Docker Scout - Imagen de Ghost en Kubernetes](https://raw.githubusercontent.com/sredevopsorg/ghost-on-kubernetes/main/docs/images/dockerhub-ngeorger.png) |

### **Rendimiento y Arquitectura**

* **Artefactos de Build Personalizados:** Mantenemos dos Dockerfiles distintos para producción y desarrollo:
  * **Imagen de Producción:** La imagen principal construida utilizando nuestro proceso de construcción endurecido y multi-etapa. Ver el [Dockerfile](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile).
  * **Imagen de Desarrollo:** Una variante adaptada para pruebas, que incluye soporte para SQLite. Ver el [Dockerfile-dev](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/Dockerfile-dev).
* **Soporte Multi-Arquitectura:** Las imágenes están construidas para las arquitecturas **amd64** y **arm64**.
* **Build Multi-Etapa:** Utilizamos la imagen oficial de Node 22 Jod LTS para la construcción, lo que reduce significativamente el tamaño final de la imagen y mejora la seguridad al eliminar componentes de construcción innecesarios.
* **Ghost v6 y NodeJS 22 LTS Actualizados:** Utilizando las últimas versiones estables para seguridad y rendimiento.
* **Punto de Entrada Robusto (entrypoint.js):** Un script de punto de entrada **Node.js** personalizado, ejecutado por el usuario sin privilegios, maneja las operaciones de tiempo de ejecución necesarias, como la actualización de temas predeterminados, antes de iniciar la aplicación Ghost. El script se puede revisar aquí: [entrypoint.js](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/entrypoint.js).
* **Contenedor Init Dedicado:** El despliegue incluye un **initContainer** para manejar la creación de directorios, la propiedad correcta (UID/GID 65532) y la configuración de permisos antes del lanzamiento del contenedor principal de Ghost, asegurando una operación fluida dentro del contenedor Distroless.

## **Resumen de la Arquitectura de Despliegue**

Este proyecto proporciona archivos manifest completos de Kubernetes (`deploy/`) para ejecutar una instancia de Ghost lista para producción, respaldada por una base de datos **MySQL**.

| Recurso | Componentes | Detalles |
| :---- | :---- | :---- |
| **Namespace** | ghost-on-kubernetes | Proporciona aislamiento lógico para todos los componentes. (Archivo: [00-namespace.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/00-namespace.yaml)) |
| **StatefulSet** | ghost-on-kubernetes-mysql | Gestiona la base de datos MySQL 8, asegurando red estable y almacenamiento persistente. (Archivo: [05-mysql.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/05-mysql.yaml)) |
| **Deployment** | ghost-on-kubernetes | Gestiona los pods de la aplicación Ghost v6. (Archivo: [06-ghost-deployment.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/06-ghost-deployment.yaml)) |
| **Services** | ghost-on-kubernetes-service, ghost-on-kubernetes-mysql-service | Expone Ghost (2368) y MySQL (3306) internamente dentro del clúster. (Archivo: [03-service.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/03-service.yaml)) |
| **PersistentVolumeClaims (PVC)** | k8s-ghost-content, ghost-on-kubernetes-mysql-pvc | Solicita almacenamiento persistente para el contenido de Ghost (temas, imágenes) y los datos de MySQL. (Archivo: [02-pvc.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/02-pvc.yaml)) |
| **Secrets** | ghost-config-prod, ghost-on-kubernetes-mysql-env, tls-secret | Almacena de forma segura la configuración de Ghost, las credenciales de la base de datos y los certificados TLS (opcional). (Archivos: [01-mysql-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-mysql-config.yaml), [04-ghost-config.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/04-ghost-config.yaml), [01-tls.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/01-tls.yaml)) |
| **Ingress** | ghost-on-kubernetes-ingress | Expone la aplicación Ghost al mundo exterior a través de HTTP/HTTPS (requiere un TLD). (Archivo: [07-ingress.yaml](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/deploy/07-ingress.yaml)) |

*Nota*: Puedes alojar múltiples instancias de Ghost reemplazando la especificación de Namespace en cada archivo manifest.

## **Instrucciones de Instalación (Producción)**

Sigue estos pasos para desplegar Ghost en tu clúster de Kubernetes.

### **Prerrequisitos**

1. Un clúster de Kubernetes en funcionamiento (`kubectl` configurado).
2. Un StorageClass provisionado (requerido para los PVCs).

### **0. Clonar (o hacer fork) del Repositorio**

```bash
## Clonar el repositorio
git clone https://github.com/sredevopsorg/ghost-on-kubernetes.git --depth 1 --branch main --single-branch --no-tags
## Cambiar de directorio
cd ghost-on-kubernetes
```

### **1. Revisar y Configurar**

Revisa los archivos de configuración de ejemplo y modifica los manifests en la carpeta `deploy/` para adaptarlos a tu entorno (ej. clase de almacenamiento, nombre de dominio, valores de secretos).

* **Configuraciones:** Revisa los archivos de configuración de ejemplo en el directorio [examples/](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/examples/):
  * `config.production.sample.yaml`: Configuración recomendada usando MySQL 8. Requiere un **dominio de nivel superior (TLD)** válido para el campo `url` y la configuración de Ingress.
  * `config.development.sample.yaml`: Utiliza SQLite para entornos de prueba.
* **Documentación Oficial de Ghost:** Consulta la [documentación oficial de Ghost](https://ghost.org/docs/config/#custom-configuration-files) para opciones de configuración detalladas.

### **2. Secuencia de Despliegue**

Es **crucial** aplicar los manifests en el orden correcto para asegurar la resolución de dependencias (especialmente los componentes de la base de datos).

Alternativamente, puedes instalar el chart desde nuestro repositorio Helm (recomendado):

```bash
helm repo add sredevopsorg https://sredevopsorg.github.io/ghost-on-kubernetes
helm repo update
helm install my-ghost sredevopsorg/ghost-on-kubernetes \
  --namespace ghost \
  --create-namespace \
  --set ghost.url=https://tudominio.tld \
  --set persistence.ghost.storageClassName=tu-clase-de-almacenamiento
```

1. **Crear el Namespace:**

    `kubectl apply -f deploy/00-namespace.yaml`

2. **Crear Secrets (Credenciales y Configuración):**

    ```bash
    # IMPORTANTE: Personaliza estos secretos antes de aplicarlos
    kubectl apply -f deploy/01-mysql-config.yaml
    kubectl apply -f deploy/04-ghost-config.yaml
    kubectl apply -f deploy/01-tls.yaml
    ```

3. **Crear Almacenamiento Persistente y Services:**

    ```bash
    kubectl apply -f deploy/02-pvc.yaml
    kubectl apply -f deploy/03-service.yaml
    ```

4. **Desplegar la Base de Datos MySQL (StatefulSet):**

    ```bash
    # Espera a que el PVC de MySQL esté enlazado
    kubectl apply -f deploy/05-mysql.yaml
    ```

5. **Desplegar la Aplicación Ghost (Deployment):**

    ```bash
    # Espera a que MySQL esté listo antes de comenzar
    kubectl apply -f deploy/06-ghost-deployment.yaml
    ```

6. **Exponer Ghost con Ingress (Opcional/Recomendado):**

    ```bash
    # Enruta el tráfico externo al Service de Ghost
    kubectl apply -f deploy/07-ingress.yaml
    ```

## **¡Tu Blog Ghost está Desplegado\!**

¡Felicidades\! Has desplegado una instancia de Ghost v6 altamente segura y escalable en Kubernetes.

### **Acceso Sin Nombre de Dominio (Pruebas)**

Para previsualizar el sitio web sin configurar Ingress o un TLD, puedes usar el *port forwarding*:

1. Configura temporalmente las URL `url` y `admin` en tu Secret `config.production.json` para usar `http://localhost:2368/`.
2. Reinicia el/los pod(s) de Ghost después de actualizar el Secret.
3. Ejecuta el comando de *port-forwarding*:

<!-- end list -->

```bash
kubectl port-forward -n ghost-on-kubernetes services ghost-on-kubernetes-service 2368:2368
```

## Contribuciones

¡Damos la bienvenida a las contribuciones de la comunidad\! Por favor, revisa el archivo [CONTRIBUTING.md](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/CONTRIBUTING.md) para obtener más información sobre cómo contribuir a este proyecto.

## Licencia y Créditos

* Este proyecto está licenciado bajo la **Licencia MIT**. Por favor, revisa el archivo [LICENSE](https://github.com/sredevopsorg/ghost-on-kubernetes/blob/main/LICENSE) para obtener más información.
* Ghost CMS está licenciado bajo la [Licencia MIT](https://github.com/TryGhost/Ghost/blob/main/LICENSE).
* La imagen de node y la imagen Distroless están licenciadas por sus respectivos propietarios.

## Historial de Estrellas

![Star History Chart](https://api.star-history.com/svg?repos=sredevopsorg/ghost-on-kubernetes&type=Date&theme=dark)
