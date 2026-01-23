{{- define "ecommerce-app.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ecommerce-app.fullname" -}}
{{- if .Values.global.fullnameOverride -}}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.global.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "ecommerce-app.namespace" -}}
{{- if .Values.global.namespaceOverride }}{{ .Values.global.namespaceOverride }}{{ else }}{{ .Release.Namespace }}{{ end }}
{{- end -}}

{{- define "ecommerce-app.labels" -}}
app: ecommerce
project: ecommerce
managed-by: helm
chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
release: {{ .Release.Name }}
version: {{ default "v1.0.0" .Values.global.version }}
{{- end -}}

{{- define "ecommerce-app.selectorLabels" -}}
app: ecommerce
component: {{ .component }}
{{- end -}}

{{- define "ecommerce-app.image" -}}
{{- $registry := .Values.global.imageRegistry | default "" -}}
{{- $repo := .image.repository -}}
{{- $tag := .image.tag | default "latest" -}}
{{- if $registry }}{{ printf "%s/%s:%s" $registry $repo $tag }}{{ else }}{{ printf "%s:%s" $repo $tag }}{{ end -}}
{{- end -}}
