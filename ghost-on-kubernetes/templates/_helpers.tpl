{{/*
Expand the name of the chart.
*/}}
{{- define "ghost-on-kubernetes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ghost-on-kubernetes.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ghost-on-kubernetes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ghost-on-kubernetes.labels" -}}
helm.sh/chart: {{ include "ghost-on-kubernetes.chart" . }}
{{ include "ghost-on-kubernetes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ghost-on-kubernetes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghost-on-kubernetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ghost-on-kubernetes.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ghost-on-kubernetes.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the content of the config file as secret
*/}}

{{- define "ghost-on-kubernetes.configProductionJson" -}}
# create a variable for mysql host with the name of the release
{{- $name := include "ghost-on-kubernetes.fullname" . }}
{{- $host := printf "%s-mysql" $name }}



{
  "url": "{{ .Values.ghostConfigProd.url }}",
  "admin": {
      "url": "{{ .Values.ghostConfigProd.adminUrl }}"
      },
  "server": {
      "host": "0.0.0.0",
      "port": "{{ .Values.ghostConfigProd.port }}"
      },
  "database": {
      "client": "mysql",
      "connection": {
          "host": "{{ $host }}",
          "user": "{{ .Values.mysqlStatefulset.user }}",
          "password": "{{ .Values.mysqlStatefulset.password }}",
          "database": "{{ .Values.mysqlStatefulset.database }}",
          "port": "{{ .Values.mysqlStatefulset.port }}"
          }
  },
  "mail": {
      "transport": "{{ .Values.ghostConfigProd.mailTransport }}",
      "options": {
          "host": "{{ .Values.ghostConfigProd.mailHost }}",
          "port": "{{ .Values.ghostConfigProd.mailPort }}",
          "service": "{{ .Values.ghostConfigProd.mailService }}",
          "secureConnection": "{{ .Values.ghostConfigProd.mailSecureConnection }}",
          "auth": {
              "user": "{{ .Values.ghostConfigProd.mailAuthUser }}",
              "pass": "{{ .Values.ghostConfigProd.mailAuthPass }}"
              }
          }
      },
  "logging": {
      "transports": [
          "file",
          "stdout"
      ]
  },
  "process": "local",
  "paths": {
      "contentPath": "/var/lib/ghost/content"
      },
  "debug": "{{ .Values.ghostConfigProd.debug }}",
  "emailAnalytics": "{{ .Values.ghostConfigProd.emailAnalytics }}",
  "privacy": {
      "useUpdateCheck": "{{ .Values.ghostConfigProd.useUpdateCheck }}",
      "useRpcPing": "{{ .Values.ghostConfigProd.useRpcPing }}"
      },
  "backgroundJobs": {
      "emailAnalytics": "{{ .Values.ghostConfigProd.emailAnalytics }}"
      }
}

{{- end }}
