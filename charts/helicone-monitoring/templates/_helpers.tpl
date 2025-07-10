{{/*
Expand the name of the chart.
*/}}

{{- define "helicone.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the namespace.
*/}}
{{- define "helicone-monitoring.namespace" -}}
{{- if .Values.monitoring.namespaceOverride }}
{{- .Values.monitoring.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helicone-monitoring.labels" -}}
helm.sh/chart: {{ include "helicone.name" . }}
{{ include "helicone-monitoring.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helicone-monitoring.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helicone.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
