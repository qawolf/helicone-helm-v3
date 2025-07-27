{{- define "helicone.name" -}}
{{- $name := default .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "helicone.ai-gateway.name" -}}
{{ include "helicone.name" . }}-ai-gateway
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helicone.ai-gateway.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helicone.ai-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helicone.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helicone.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helicone.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels
*/}}
{{- define "helicone.labels" -}}
helm.sh/chart: {{ include "helicone.chart" . }}
{{ include "helicone.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

app.kubernetes.io/managed-by: {{ .Release.Service }}

{{- define "ai-gateway.env.minioAndRedisParams" -}}
- name: AI_GATEWAY__MINIO__HOST
  valueFrom:
    secretKeyRef:
      name: {{ .Values.helicone.aiGateway.minioHostSecretName | default "ai-gateway-minio-host" | quote }}
      key: {{ .Values.helicone.aiGateway.minioHostSecretKey | default "host" | quote }}
- name: AI_GATEWAY__MINIO__REGION
  valueFrom:
    secretKeyRef:
      name: {{ .Values.helicone.aiGateway.minioRegionSecretName | default "ai-gateway-minio-region" | quote }}
      key: {{ .Values.helicone.aiGateway.minioRegionSecretKey | default "region" | quote }}
- name: AI_GATEWAY__CACHE_STORE__HOST_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.helicone.aiGateway.redisHostSecretName | default "ai-gateway-redis-host" | quote }}
      key: {{ .Values.helicone.aiGateway.redisHostSecretKey | default "host_url" | quote }}
- name: AI_GATEWAY__RATE_LIMIT_STORE__HOST_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.helicone.aiGateway.redisHostSecretName | default "ai-gateway-redis-host" | quote }}
      key: {{ .Values.helicone.aiGateway.redisHostSecretKey | default "host_url" | quote }}
{{- end }}



