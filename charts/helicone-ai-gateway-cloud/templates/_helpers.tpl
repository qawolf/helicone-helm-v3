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
{{- end }}

{{- define "helicone.ai-gateway.env" -}}

- name: AI_GATEWAY__DATABASE__URL
  valueFrom:
    secretKeyRef:
      name: ai-gateway-secrets
      key: dbUrl
- name: PGSSLROOTCERT
  valueFrom:
    secretKeyRef:
      name: ai-gateway-secrets
      key: dbCert
{{- with .Values.aiGateway.extraEnvVars }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}
