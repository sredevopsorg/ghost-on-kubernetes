{{/*
Expand the name of the chart.
*/}}
{{- define "ghost-on-kubernetes.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
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
app.kubernetes.io/part-of: ghost-on-kubernetes
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ghost-on-kubernetes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghost-on-kubernetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
MySQL service name
*/}}
{{- define "ghost-on-kubernetes.mysql.servicename" -}}
{{- if .Values.mysql.enabled }}
{{- printf "%s-mysql-service" (include "ghost-on-kubernetes.fullname" .) }}
{{- else }}
{{- .Values.mysql.external.host }}
{{- end }}
{{- end }}

{{/*
MySQL host
*/}}
{{- define "ghost-on-kubernetes.mysql.host" -}}
{{- if .Values.mysql.enabled }}
{{- printf "%s-mysql-service" (include "ghost-on-kubernetes.fullname" .) }}
{{- else }}
{{- .Values.mysql.external.host }}
{{- end }}
{{- end }}

{{/*
MySQL port
*/}}
{{- define "ghost-on-kubernetes.mysql.port" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.service.mysql.port }}
{{- else }}
{{- .Values.mysql.external.port }}
{{- end }}
{{- end }}

{{/*
MySQL database
*/}}
{{- define "ghost-on-kubernetes.mysql.database" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.auth.database }}
{{- else }}
{{- .Values.mysql.external.database }}
{{- end }}
{{- end }}

{{/*
MySQL username
*/}}
{{- define "ghost-on-kubernetes.mysql.username" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.auth.username }}
{{- else }}
{{- .Values.mysql.external.username }}
{{- end }}
{{- end }}

{{/*
MySQL password
*/}}
{{- define "ghost-on-kubernetes.mysql.password" -}}
{{- if .Values.mysql.enabled }}
{{- .Values.mysql.auth.password }}
{{- else }}
{{- .Values.mysql.external.password }}
{{- end }}
{{- end }}

