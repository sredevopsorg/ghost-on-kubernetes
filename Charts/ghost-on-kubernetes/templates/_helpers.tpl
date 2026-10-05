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
Common labels.
*/}}
{{- define "ghost-on-kubernetes.labels" -}}
helm.sh/chart: {{ include "ghost-on-kubernetes.chart" . }}
{{ include "ghost-on-kubernetes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: ghost-on-kubernetes
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels for the Ghost workload. Stable across upgrades: never add a
mutable value (image tag, version, date) here or the Deployment selector
becomes immutable.
*/}}
{{- define "ghost-on-kubernetes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghost-on-kubernetes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Selector labels for the bundled MySQL StatefulSet. Release-scoped so two Ghost
releases in one namespace never select each other's pods.
*/}}
{{- define "ghost-on-kubernetes.mysql.selectorLabels" -}}
{{ include "ghost-on-kubernetes.selectorLabels" . }}
app.kubernetes.io/component: database
{{- end }}

{{/*
Selector labels for the bundled Valkey Deployment.
*/}}
{{- define "ghost-on-kubernetes.valkey.selectorLabels" -}}
{{ include "ghost-on-kubernetes.selectorLabels" . }}
app.kubernetes.io/component: cache
{{- end }}

{{/*
Name of the Kubernetes Service account used by every workload.
*/}}
{{- define "ghost-on-kubernetes.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ghost-on-kubernetes.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Render an affinity block from {nodeAffinity, podAffinity, podAntiAffinity}.
Each key is optional and rendered verbatim when set, which keeps the manifest
valid whatever subset the user provides. The legacy "enabled" flag is accepted
and ignored so existing values files keep working.
*/}}
{{- define "ghost-on-kubernetes.affinity" -}}
{{- $affinity := omit (. | default dict) "enabled" -}}
{{- $out := dict -}}
{{- range $key := list "nodeAffinity" "podAffinity" "podAntiAffinity" -}}
{{- with (index $affinity $key) }}{{ $_ := set $out $key . }}{{ end -}}
{{- end -}}
{{- with $out }}{{ toYaml . }}{{ end -}}
{{- end }}

{{/*
Name of the secret holding the MySQL environment: the one this chart renders, or
the one supplied through mysql.auth.existingSecret.
*/}}
{{- define "ghost-on-kubernetes.mysql.secretName" -}}
{{- default (printf "%s-mysql-env" (include "ghost-on-kubernetes.fullname" .)) .Values.mysql.auth.existingSecret }}
{{- end }}

{{/*
Name of the secret holding the Valkey password: the one this chart renders, or
the one supplied through valkey.auth.existingSecret.
*/}}
{{- define "ghost-on-kubernetes.valkey.secretName" -}}
{{- default (printf "%s-valkey" (include "ghost-on-kubernetes.fullname" .)) .Values.valkey.auth.existingSecret }}
{{- end }}

{{/*
Build the "database" object of config.production.json from either the bundled
MySQL or the external server configured by the user.
*/}}
{{- define "ghost-on-kubernetes.databaseConfig" -}}
{{- $connection := dict
  "host" (ternary (printf "%s-mysql-service" (include "ghost-on-kubernetes.fullname" .)) .Values.mysql.external.host .Values.mysql.enabled)
  "port" (ternary .Values.service.mysql.port .Values.mysql.external.port .Values.mysql.enabled | int)
  "user" (ternary .Values.mysql.auth.username .Values.mysql.external.username .Values.mysql.enabled)
  "password" (ternary .Values.mysql.auth.password .Values.mysql.external.password .Values.mysql.enabled)
  "database" (ternary .Values.mysql.auth.database .Values.mysql.external.database .Values.mysql.enabled)
-}}
{{- if and .Values.mysql.enabled (not .Values.ghost.config.existingSecret) }}
{{- $_ := required "mysql.auth.password is required, or set mysql.auth.existingSecret" (index $connection "password") }}
{{- end }}
{{- dict "client" "mysql" "connection" $connection | toYaml -}}
{{- end }}

{{/*
Build the "adapters.cache" object of config.production.json. Returns an empty
map when neither the bundled nor an external cache is configured.
*/}}
{{- define "ghost-on-kubernetes.cacheConfig" -}}
{{- $bundled := .Values.valkey.enabled -}}
{{- $external := .Values.valkey.external.enabled -}}
{{- if or $bundled $external -}}
{{- $authenticated := and $bundled .Values.valkey.auth.enabled | or (and $external (ne .Values.valkey.external.password "")) -}}
{{- $cache := dict
  "host" (ternary (printf "%s-valkey-service" (include "ghost-on-kubernetes.fullname" .)) .Values.valkey.external.host $bundled)
  "port" (ternary .Values.service.valkey.port .Values.valkey.external.port $bundled | int)
  "db" (ternary .Values.valkey.database .Values.valkey.external.database $bundled | int)
  "ttl" (.Values.valkey.ttl.imageSizes | int)
  "keyPrefix" (printf "%s:" (trimSuffix ":" (default .Values.valkey.keyPrefix .Values.valkey.external.keyPrefix | default "ghost")))
-}}
{{- if $authenticated }}
{{- $_ := set $cache "username" (ternary .Values.valkey.auth.username .Values.valkey.external.username $bundled) }}
{{- $_ := set $cache "password" (ternary .Values.valkey.auth.password .Values.valkey.external.password $bundled) }}
{{- $_ := required "valkey.auth.password is required, or set valkey.auth.existingSecret" (index $cache "password") }}
{{- end }}
{{- $adapters := dict "Redis" $cache }}
{{- range $adapter := list "imageSizes" "gscan" "postsPublic" "tagsPublic" "linkRedirectsPublic" "stats" }}
{{- $_ := set $adapters $adapter (dict
  "adapter" "Redis"
  "ttl" (index $.Values.valkey.ttl $adapter | int)
  "keyPrefix" (printf "%s%s:" (index $cache "keyPrefix") $adapter)
) }}
{{- end }}
{{- dict "active" "Redis" "cache" $adapters | toYaml -}}
{{- end -}}
{{- end }}

{{/*
Render an httpGet probe for the Ghost container. Expects a dict with "root"
(the chart context) and "probe" (the probe values). The Host header defaults to
the hostname of ghost.url so probes work with no Ingress, or with an Ingress
whose host list the user has not filled in yet.
*/}}
{{- define "ghost-on-kubernetes.probe" -}}
{{- $scheme := .probe.scheme | default "HTTP" -}}
{{- $headers := list (dict "name" "Host" "value" (.root.Values.ghost.probeHost | default (urlParse .root.Values.ghost.url).hostname)) -}}
{{- if ne $scheme "HTTP" -}}
{{- $headers = append $headers (dict "name" "X-Forwarded-Proto" "value" $scheme) -}}
{{- end -}}
{{- with .probe.extraHttpHeaders -}}
{{- $headers = concat $headers . -}}
{{- end -}}
httpGet:
  path: {{ .probe.path | default "/ghost/api/v4/admin/site/" | quote }}
  port: ghk8s
  scheme: {{ $scheme | quote }}
  httpHeaders:
    {{- toYaml $headers | nindent 4 }}
initialDelaySeconds: {{ .probe.initialDelaySeconds }}
periodSeconds: {{ .probe.periodSeconds }}
timeoutSeconds: {{ .probe.timeoutSeconds }}
successThreshold: {{ .probe.successThreshold }}
failureThreshold: {{ .probe.failureThreshold }}
{{- end }}
