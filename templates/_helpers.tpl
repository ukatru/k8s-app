{{/*
Expand the name of the chart.
*/}}
{{- define "k8s-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "k8s-app.fullname" -}}
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
{{- define "k8s-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "k8s-app.labels" -}}
helm.sh/chart: {{ include "k8s-app.chart" . }}
{{ include "k8s-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ printf "%s-%s-%s" .Values.appSpec.name .Values.appSpec.env .Values.appSpec.version }}
app.kubernetes.io/component: backend
app.kubernetes.io/part-of: {{ .Values.appSpec.snowAppId }}
platform.k8s.ukatru.cloud/env: {{ .Values.appSpec.env }}
platform.k8s.ukatru.com/app: {{ .Values.appSpec.name }}
platform.k8s.ukatru.cloud/module-version: {{ .Chart.Version }}
{{- if .Values.appSpec.branch }}
platform.k8s.ukatru.cloud/branch: {{ .Values.appSpec.branch }}
{{- end }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- with .Values.pipelineLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "k8s-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ .Values.appSpec.name }}
{{- end }}

{{/*
Observability labels (Grafana/Prometheus compatible)
*/}}
{{- define "k8s-app.observabilityLabels" -}}
app.kubernetes.io/env: {{ .Values.appSpec.env }}
app.kubernetes.io/service: {{ .Values.appSpec.name }}
app.kubernetes.io/version: {{ .Values.appSpec.version }}
{{- if .Values.observability.team }}
app.kubernetes.io/team: {{ .Values.observability.team }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "k8s-app.annotations" -}}
{{- if .Values.appSpec.repoUrl }}
platform.k8s.ukatru.cloud/repo: {{ .Values.appSpec.repoUrl }}
{{- end }}
{{- if .Values.appSpec.pipelineId }}
platform.k8s.ukatru.cloud/pipeline-id: {{ .Values.appSpec.pipelineId }}
{{- end }}
{{- if .Values.appSpec.pipelineUrl }}
platform.k8s.ukatru.cloud/pipeline-url: {{ .Values.appSpec.pipelineUrl }}
{{- end }}
{{- if .Values.gitlabJwt }}
platform.k8s.ukatru.cloud/gitlab-jwt: {{ .Values.gitlabJwt }}
{{- end }}
{{- with .Values.annotations }}
{{ toYaml . }}
{{- end }}
{{- with .Values.pipelineAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8s-app.serviceAccountName" -}}
{{- if .Values.podIdentity.enabled }}
{{- default (include "k8s-app.fullname" .) .Values.podIdentity.serviceAccountName }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}

{{/*
Rolling update strategy
Defaults based on environment:
- prod: maxSurge 100%, maxUnavailable 0 (fast rollout)
- others: maxSurge 1, maxUnavailable 0 (gradual rollout)
*/}}
{{- define "k8s-app.rollingUpdate" -}}
{{- if .Values.rollingUpdate }}
maxSurge: {{ .Values.rollingUpdate.maxSurge }}
maxUnavailable: {{ .Values.rollingUpdate.maxUnavailable }}
{{- else if eq .Values.appSpec.env "prod" }}
maxSurge: 100%
maxUnavailable: 0
{{- else }}
maxSurge: 1
maxUnavailable: 0
{{- end }}
{{- end }}

{{/*
Generate DNS name for ingress
Logic:
- Non-sandbox without branch: {app}-{env}.{subdomain}
- Sandbox OR with branch: {app}-{env}-{branch}.{subdomain}
- Clean invalid DNS characters
*/}}
{{- define "k8s-app.dnsName" -}}
{{- $dnsName := "" }}
{{- if and (ne .Values.appSpec.env "sandbox") (not .Values.appSpec.branch) }}
  {{- $dnsName = printf "%s-%s.%s" .Values.appSpec.name .Values.appSpec.env .Values.clusterConfig.clusterSubDomain }}
{{- else }}
  {{- $dnsName = printf "%s-%s-%s.%s" .Values.appSpec.name .Values.appSpec.env .Values.appSpec.branch .Values.clusterConfig.clusterSubDomain }}
{{- end }}
{{- regexReplaceAll "[^A-Za-z0-9.-]" $dnsName "-" }}
{{- end }}

{{/*
Get resource plan values (deprecated - use k8s-app.languageResources instead)
This is kept for backward compatibility
*/}}
{{- define "k8s-app.resources" -}}
{{- include "k8s-app.languageResources" . }}
{{- end }}

{{/*
Get primary port
*/}}
{{- define "k8s-app.primaryPort" -}}
{{- if .Values.ports }}
{{- (index .Values.ports 0).containerPort }}
{{- else }}
8080
{{- end }}
{{- end }}

{{/*
Get primary port name
*/}}
{{- define "k8s-app.primaryPortName" -}}
{{- if .Values.ports }}
{{- (index .Values.ports 0).name }}
{{- else }}
http
{{- end }}
{{- end }}

{{/*
Observability environment variables
*/}}
{{- define "k8s-app.observabilityEnv" -}}
- name: APP_ENV
  value: {{ .Values.appSpec.env | quote }}
- name: APP_NAME
  value: {{ .Values.appSpec.name | quote }}
- name: APP_VERSION
  value: {{ .Values.appSpec.version | quote }}
{{- if .Values.observability.metrics.enabled }}
- name: METRICS_PORT
  value: {{ .Values.observability.metrics.port | quote }}
- name: METRICS_PATH
  value: {{ .Values.observability.metrics.path | quote }}
{{- end }}
{{- if .Values.observability.tracing.enabled }}
- name: TRACING_ENABLED
  value: "true"
- name: TRACING_SAMPLE_RATE
  value: {{ .Values.observability.tracing.sampleRate | quote }}
{{- end }}
{{- if .Values.observability.logging.enabled }}
- name: LOG_FORMAT
  value: {{ .Values.observability.logging.format | quote }}
{{- end }}
{{- end }}

{{/*
Language-specific environment variables
*/}}
{{- define "k8s-app.languageEnv" -}}
{{- if eq .Values.appSpec.language "python" }}
- name: PYTHONUNBUFFERED
  value: "1"
- name: PYTHONDONTWRITEBYTECODE
  value: "1"
{{- else if eq .Values.appSpec.language "java" }}
- name: JAVA_OPTS
  value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
{{- else if eq .Values.appSpec.language "dotnet" }}
- name: DOTNET_RUNNING_IN_CONTAINER
  value: "true"
- name: DOTNET_SYSTEM_GLOBALIZATION_INVARIANT
  value: "false"
{{- end }}
{{- end }}
