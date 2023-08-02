{{/*
Expand the name of the chart.
*/}}
{{- define "ghost-on-kubernetes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 36 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ghost-on-kubernetes.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 36 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 36 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 36 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ghost-on-kubernetes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 36 | trimSuffix "-" }}
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
Define the content of config.production.json file
*/}}
{{- define "ghost-on-kubernetes.configProductionJson" -}}
{
"url": "{{ .Values.ghostConfigProd.url }}",
"admin": {"url": "{{ .Values.ghostConfigProd.adminUrl }}"},
"server": {
    "host": "{{ .Values.ghostConfigProd.host }}",
    "port": "{{ .Values.ghostConfigProd.port }}"
    },
"database": {
    "client": "mysql",
    "connection": {
        "host": "{{ include "ghost-on-kubernetes.fullname" . }}-mysql",
        "user": "{{ .Values.mysqlGhostOnKubernetes.mysqlUser }}",
        "password": "{{ .Values.mysqlGhostOnKubernetes.mysqlPassword }}",
        "database": "{{ .Values.mysqlGhostOnKubernetes.mysqlDatabase }}"
    }
},
"mail": {
    "transport": "{{ .Values.ghostConfigProd.mailTransport }}",
    "options": {
        "host": "{{ .Values.ghostConfigProd.mailHost }}",
        "port": "{{ .Values.ghostConfigProd.mailPort }}",
        "service": "{{ .Values.ghostConfigProd.mailService }}",
        "secure": "{{ .Values.ghostConfigProd.mailSecureConnection }}",
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
