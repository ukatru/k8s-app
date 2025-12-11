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
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
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
app: {{ .Release.Name }}
app.kubernetes.io/componenet: backend
app.kubernetes.io/instance: {{ .Values.appSpec.name }}-{{ .Values.appSpec.env }}-{{ .Values.appSpec.version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ .Release.Name }}
app.kubernetes.io/part-of: {{ .Values.appSpec.appId }}
app.kubernetes.io/version: {{ .Values.appSpec.version }}
platform.k8s.g1001.cloud/env: {{ .Values.appSpec.env }}
platform.k8s.g1001.cloud/module-version: {{ .Chart.Version }}
{{- with .Values.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "k8s-app.selectorLabels" -}}
app.kubernetes.io/name: {{ .Release.Name }}
{{- end }}

{{/*
Language-specific environment variables - Dynamic lookup
Dynamically calls k8s-app.envVars.<language> if the helper exists

To add a new language, simply create _<language>.tpl with:
{{- define "k8s-app.envVars.<language>" -}}
- name: YOUR_ENV_VAR
  value: "value"
{{- end }}
*/}}
{{- define "k8s-app.languageEnvVars" -}}
{{- $language := .Values.appSpec.language -}}
{{- if $language -}}
  {{- $helperName := printf "k8s-app.envVars.%s" $language -}}
  {{- include $helperName . -}}
{{- end -}}
{{- end }}

{{/*
Language-specific volume sources - Dynamic lookup
Attempts to call k8s-app.volumeSources.<language> if defined

Note: Due to Helm limitations, we cannot check if a template exists before calling it.
Each language helper MUST define the volumeSources template (can be empty).
This is the simplest approach without maintaining a separate registry.

To add language-specific volume mounts, create in _<language>.tpl:
{{- define "k8s-app.volumeSources.<language>" -}}
- configMap:
    name: your-config
{{- end }}

For languages without volume needs, define an empty helper:
{{- define "k8s-app.volumeSources.<language>" -}}
{{- end }}
*/}}
{{- define "k8s-app.volumeSources" -}}
{{- $language := .Values.appSpec.language -}}
{{- if $language -}}
  {{- $helperName := printf "k8s-app.volumeSources.%s" $language -}}
  {{- include $helperName . -}}
{{- end -}}
{{- end }}

{{/*
Get language-specific default environment variables as a map
Converts the YAML list format to a dict for merging
*/}}
{{- define "k8s-app.envVarsMap" -}}
{{- $language := .Values.appSpec.language -}}
{{- $envMap := dict -}}
{{- if $language -}}
  {{- $helperName := printf "k8s-app.envVars.%s" $language -}}
  {{- $envYaml := include $helperName . | trim -}}
  {{- if $envYaml -}}
    {{- /* Parse the YAML list and convert to map */ -}}
    {{- $lines := splitList "\n" $envYaml -}}
    {{- $currentName := "" -}}
    {{- range $lines -}}
      {{- $line := trim . -}}
      {{- if hasPrefix "- name:" $line -}}
        {{- $currentName = trim (trimPrefix "- name:" $line) -}}
      {{- else if and (hasPrefix "value:" $line) $currentName -}}
        {{- $value := trim (trimPrefix "value:" $line) | trimAll "\"" -}}
        {{- $_ := set $envMap $currentName $value -}}
        {{- $currentName = "" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- $envMap | toYaml -}}
{{- end }}

{{/*
Merge language defaults with user-provided env vars
User-provided values take precedence over language defaults
*/}}
{{- define "k8s-app.mergedEnvVars" -}}
{{- $languageDefaults := dict -}}
{{- if .Values.appSpec.language -}}
  {{- $languageDefaults = include "k8s-app.envVarsMap" . | fromYaml | default dict -}}
{{- end -}}
{{- $userEnv := .Values.env | default dict -}}
{{- $merged := merge $userEnv $languageDefaults -}}
{{- range $key, $value := $merged }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "k8s-app.annotations" -}}
{{- if .Values.appSpec.repoUrl -}}
plaform.k8s.g1001.cloud/repo: {{ .Values.appSpec.repoUrl }}
{{ end -}}
{{- if .Values.appSpec.pipelineId -}}
plaform.k8s.g1001.cloud/pipelineId: {{ .Values.appSpec.pipelineId }}
{{ end -}}
{{- if .Values.appSpec.pipelineUrl -}}
plaform.k8s.g1001.cloud/pipelineUrl: {{ .Values.appSpec.pipelineUrl }}
{{ end -}}
{{- with .Values.annotations -}}
{{ toYaml . }}
{{ end -}}
{{- end }}

{{/*
Get the app port from ports configuration
*/}}
{{- define "k8s-app.appPort" -}}
{{- $port := 8080 -}}
{{- range .Values.ports -}}
{{- if eq .name "http" -}}
{{- $port = .containerPort -}}
{{- end -}}
{{- end -}}
{{- $port -}}
{{- end }}

{{/*
Get deployment strategy based on environment or custom override
*/}}
{{- define "k8s-app.deploymentStrategy" -}}
{{- if .Values.deployment -}}
  {{- if .Values.deployment.maxSurge -}}
maxSurge: {{ .Values.deployment.maxSurge }}
maxUnavailable: {{ .Values.deployment.maxUnavailable | default 0 }}
  {{- else if eq .Values.appSpec.env "prod" -}}
maxSurge: "100%"
maxUnavailable: 0
  {{- else -}}
maxSurge: 1
maxUnavailable: 0
  {{- end -}}
{{- else if eq .Values.appSpec.env "prod" -}}
maxSurge: "100%"
maxUnavailable: 0
{{- else -}}
maxSurge: 1
maxUnavailable: 0
{{- end -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "k8s-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (printf "%s-sa" (include "k8s-app.fullname" .)) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate probe configuration with language-based defaults
*/}}
{{- define "k8s-app.probe" -}}
{{- $probe := .probe -}}
{{- $language := .language -}}
{{- $appPort := .appPort -}}
{{- $probeType := $probe.probeType | default (ternary "tcp" "http" (eq $language "spa")) -}}
{{- $port := $probe.port | default $appPort -}}
{{- if eq $probeType "http" }}
httpGet:
  path: {{ $probe.path | default "/health" }}
  port: {{ $port }}
{{- else if eq $probeType "tcp" }}
tcpSocket:
  port: {{ $port }}
{{- else if eq $probeType "grpc" }}
grpc:
  port: {{ $port }}
{{- end }}
initialDelaySeconds: {{ $probe.initialDelaySeconds | default 60 }}
periodSeconds: {{ $probe.periodSeconds | default 5 }}
timeoutSeconds: {{ $probe.timeoutSeconds | default 1 }}
successThreshold: {{ $probe.successThreshold | default 1 }}
failureThreshold: {{ $probe.failureThreshold | default 11 }}
{{- end }}

{{/*
Generate DNS name for ingress
*/}}
{{- define "k8s-app.ingressHost" -}}
{{- if and .Values.appSpec.branch (eq .Values.appSpec.env "sandbox") }}
{{- printf "%s-%s-%s.%s" .Values.appSpec.name .Values.appSpec.branch .Values.appSpec.env .Values.clusterConfig.clusterSubDomain }}
{{- else if eq .Values.appSpec.env "prod" }}
{{- printf "%s.%s" .Values.appSpec.name .Values.clusterConfig.clusterSubDomain }}
{{- else }}
{{- printf "%s-%s.%s" .Values.appSpec.name .Values.appSpec.env .Values.clusterConfig.clusterSubDomain }}
{{- end }}
{{- end }}
