# Ghost en Kubernetes por SREDevOps.cl

Este repositorio despliega un CMS Ghost en k3s o cualquier distribución de Kubernetes usando kubectl. Se ha probado solo con k3s, la razón principal es el __almacenamiento__, que se simplifica con k3s.

## Notas:
- _Por favor, revisa y edita los archivos en este repositorio según tus necesidades._
- Ten en cuenta que esto es solo una sugerencia y debes modificarlo para que se ajuste a tus necesidades específicas.
- Por favor, revisa y edita los archivos según tus necesidades.

## Características
- Despliega un CMS Ghost completamente funcional en Kubernetes.
- Admite dominios personalizados y certificados TLS con secrets.
- Fácil de usar y mantener.

## Requisitos
- Kubernetes 1.16 o superior.
- k3s 1.20 o superior.
- kubectl
- Conocimientos básicos sobre Kubernetes
- Cómo codificar cadenas en base64

## Archivos
Los siguientes archivos están incluidos en este repositorio:

- 00-namespace.yaml: Crea un espacio de nombres para el despliegue de Ghost.
- 01-secrets.yaml: Crea secrets para el despliegue de Ghost. Este archivo debe ser editado de acuerdo a los comentarios que contiene.
- 02-mysql.yaml: Despliega una base de datos MySQL para el despliegue de Ghost.
- 04-pvc.yaml: Crea una reclamación de volumen persistente para el despliegue de Ghost.
- 04-service.yaml: Crea un servicio para el despliegue de Ghost.
- 05-ghost.yaml: Despliega un pod de Ghost.

## Instalación
Para instalar Ghost en Kubernetes, sigue estos pasos:

- Clona este repositorio.
- Edita 01-secrets.yaml con tus propios secrets y certificado (yo uso Cloudflare para DNS, por lo que utilizo su certificado y clave proporcionados, búscalo en Google).
- En el directorio raíz del repositorio, ejecuta el siguiente comando para desplegar Ghost:
  ```bash
    kubectl apply -f .
  ```
Ghost será desplegado. Puedes acceder a tu CMS Ghost en el puerto predeterminado de Ghost, que es el 2368.

## Solución de problemas
Si tienes problemas al desplegar Ghost en Kubernetes, puedes solucionar el problema siguiendo estos pasos:

- Verifica los registros (logs) del pod de Ghost.
- Verifica la configuración de los archivos en este repositorio.
- Crea un issue en este repositorio o busca soporte en https://foro.sredevops.cl

## Contribuciones
Si deseas contribuir a este proyecto, sigue estos pasos:

- Haz un fork del repositorio.
- Realiza tus cambios en el código.
- Envía una pull request.
