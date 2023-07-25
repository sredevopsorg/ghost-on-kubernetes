# Ghost on Kubernetes

[![Build and push image to DockerHub and GitHub Container Registry](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml/badge.svg)](https://github.com/sredevopsdev/ghost-on-kubernetes/actions/workflows/build-custom-image.yaml)

This repository contains a Helm chart for deploying Ghost on Kubernetes and a Dockerfile for building a custom Ghost image.

## Installation

1. Add the sredevops Helm repository:

```bash
helm repo add sredevops https://sredevopsdev.github.io/ghost-on-kubernetes
```

2. Install the chart using the values from `./charts/values.yaml`:

```bash
helm install my-ghost sredevops/ghost-on-kubernetes -f ./charts/values.yaml
```

Note: You may need to modify the values in `./charts/values.yaml` to suit your needs.

## Configuration

The following table lists the configurable parameters of the Ghost chart and their default values.

| Parameter                        | Description                         | Default                                                 |
| ---------------------------------| ----------------------------------- | ------------------------------------------------------- |
| `mysql.accessMode`               | Access mode for MySQL volume        | `ReadWriteOnce`                                         |
| `mysql.storage`                  | Size of MySQL volume                | `1Gi`                                                   |
| `mysql.storageClassName`         | Storage class for MySQL volume      | `local-path`                                            |
| `ghost.accessModes`              | Access mode for Ghost volume        | `ReadWriteOnce`                                         |
| `ghost.storage`                  | Size of Ghost volume                | `10Gi`                                                  |
| `ghost.storageClassName`         | Storage class for Ghost volume      | `local-path`                                            |
| `ghost.ghostConfigProd.url`      | URL for Ghost production environment| `http://localhost:2368`                                 |
| `ghost.ghostConfigProd.adminUrl` | URL for Ghost admin panel           | `http://localhost:2368`                                 |
| `ghost.ghostConfigProd.host`     | Host for Ghost production environment| `0.0.0.0`                                             |
| `ghost.ghostConfigProd.port`     | Port for Ghost production environment| `2368`                                               |
| `ghost.ghostConfigProd.mailTransport` | Mail transport for Ghost production environment| `SMTP`                                       |
| `ghost.ghostConfigProd.mailService` | Mail service for Ghost production environment| `Google`                                         |
| `ghost.ghostConfigProd.mailHost` | Mail host for Ghost production environment| `smtp.gmail.com`                                   |
| `ghost.ghostConfigProd.mailPort` | Mail port for Ghost production environment| `587`                                             |
| `ghost.ghostConfigProd.mailSecureConnection` | Whether to use secure connection for mail in Ghost production environment| `true` |
| `ghost.ghostConfigProd.mailAuthUser` | Mail authentication user for Ghost production environment| `user@mail.com`                          |
| `ghost.ghostConfigProd.mailAuthPass` | Mail authentication password for Ghost production environment| `c0ntr4s3n4`                          |
| `ghost.ghostConfigProd.debug` | Whether to enable debug mode for Ghost production environment| `true`                                         |
| `ghost.ghostConfigProd.emailAnalytics` | Whether to enable email analytics for Ghost production environment| `false`                             |
| `ghost.ghostConfigProd.useUpdateCheck` | Whether to enable update check for Ghost production environment| `false`                                 |
| `ghost.ghostConfigProd.useRpcPing` | Whether to enable RPC ping for Ghost production environment| `false`                                       |


For more information on how to configure the chart or you have any questions, please create an issue in this repository.[ https://github.com/sredevopsdev/ghost-on-kubernetes/issues ](https://github.com/sredevopsdev/ghost-on-kubernetes/issues/new)