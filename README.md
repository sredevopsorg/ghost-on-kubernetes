# Ghost on Kubernetes by SREDevOps.cl

[README en castellano](./README.es.md)

This repository deploys a Ghost CMS on k3s or any Kubernetes distro using kubectl. It's tested using k3s only, the main reason is __storage__, which is simplified with k3s. 

## Notes:
- _Please review and edit the files in this repository according to your needs._
- Please note that this is just a suggestion, and you need to modify it to fit your specific needs.
- Please review and edit the files according to your needs.

## Features
- Deploys a fully-functioning Ghost CMS on Kubernetes.
- Supports custom domains and TLS certificates with secrets.
- Easy to use and maintain.

## Requirements
- Kubernetes 1.16 or higher.
- k3s 1.20 or higher.
- kubectl
- Very basic knowledge on kubernetes
- How to encode strings with base64

## Files
The following files are included in this repository:

- 00-namespace.yaml: Creates a namespace for the Ghost deployment.
- 01-secrets.yaml: Creates secrets for the Ghost deployment. This file needs to be edited according to the comments inside it.
- 02-mysql.yaml: Deploys a MySQL database for the Ghost deployment.
- 04-pvc.yaml: Creates a persistent volume claim for the Ghost deployment.
- 04-service.yaml: Creates a service for the Ghost deployment.
- 05-ghost.yaml: Deploys a Ghost pod.

## Installation
To install Ghost on Kubernetes, follow these steps:

- Clone this repository.
- Edit 01-secrets.yaml with your own secrets and certificate (I use Cloudflare for DNS, so I use their provided cert and key, google it)
- In the root directory of the repository, run the following command to deploy the Ghost deployment:
  ```bash
    kubectl apply -f .
  ```

The Ghost deployment will be deployed. You can access your Ghost CMS at the default Ghost port, which is 2368.
Usage

## Troubleshooting
If you are having trouble deploying Ghost on Kubernetes, you can troubleshoot the issue by following these steps:

Check the logs for the Ghost pod.
Check the configuration of the files in this repository.
Create an issue in this repo or search for support in https://foro.sredevops.cl

## Contributing
If you would like to contribute to this project, please follow these steps:

- Fork the repository.
- Make your changes to the code.
- Submit a pull request.

