{{/*
Resource plan defaults map by language
This allows dynamic lookup instead of hardcoded if/else chains
*/}}

{{/*
Default resource plans (language-agnostic baseline)
*/}}
{{- define "k8s-app.defaultPlans" -}}
small:
  requests: {cpu: "250m", memory: "256Mi"}
  limits: {cpu: "500m", memory: "512Mi"}
medium:
  requests: {cpu: "500m", memory: "512Mi"}
  limits: {cpu: "1000m", memory: "1Gi"}
large:
  requests: {cpu: "1000m", memory: "1Gi"}
  limits: {cpu: "2000m", memory: "2Gi"}
huge:
  requests: {cpu: "2000m", memory: "2Gi"}
  limits: {cpu: "4000m", memory: "4Gi"}
{{- end }}

{{- define "k8s-app.resourcePlanDefaults" -}}
default:
  small:
    requests: {cpu: "250m", memory: "256Mi"}
    limits: {cpu: "500m", memory: "512Mi"}
  medium:
    requests: {cpu: "500m", memory: "512Mi"}
    limits: {cpu: "1000m", memory: "1Gi"}
  large:
    requests: {cpu: "1000m", memory: "1Gi"}
    limits: {cpu: "2000m", memory: "2Gi"}
  huge:
    requests: {cpu: "2000m", memory: "2Gi"}
    limits: {cpu: "4000m", memory: "4Gi"}
python:
  small:
    requests: {cpu: "250m", memory: "256Mi"}
    limits: {cpu: "500m", memory: "512Mi"}
  medium:
    requests: {cpu: "500m", memory: "512Mi"}
    limits: {cpu: "1000m", memory: "1Gi"}
  large:
    requests: {cpu: "1000m", memory: "1Gi"}
    limits: {cpu: "2000m", memory: "2Gi"}
  huge:
    requests: {cpu: "2000m", memory: "2Gi"}
    limits: {cpu: "4000m", memory: "4Gi"}
java:
  small:
    requests: {cpu: "500m", memory: "512Mi"}
    limits: {cpu: "1000m", memory: "1Gi"}
  medium:
    requests: {cpu: "1000m", memory: "1Gi"}
    limits: {cpu: "2000m", memory: "2Gi"}
  large:
    requests: {cpu: "2000m", memory: "2Gi"}
    limits: {cpu: "4000m", memory: "4Gi"}
  huge:
    requests: {cpu: "4000m", memory: "4Gi"}
    limits: {cpu: "8000m", memory: "8Gi"}
dotnet:
  small:
    requests: {cpu: "250m", memory: "384Mi"}
    limits: {cpu: "500m", memory: "768Mi"}
  medium:
    requests: {cpu: "500m", memory: "768Mi"}
    limits: {cpu: "1000m", memory: "1536Mi"}
  large:
    requests: {cpu: "1000m", memory: "1536Mi"}
    limits: {cpu: "2000m", memory: "3Gi"}
  huge:
    requests: {cpu: "2000m", memory: "3Gi"}
    limits: {cpu: "4000m", memory: "6Gi"}
spa:
  small:
    requests: {cpu: "100m", memory: "128Mi"}
    limits: {cpu: "200m", memory: "256Mi"}
  medium:
    requests: {cpu: "200m", memory: "256Mi"}
    limits: {cpu: "500m", memory: "512Mi"}
  large:
    requests: {cpu: "500m", memory: "512Mi"}
    limits: {cpu: "1000m", memory: "1Gi"}
  huge:
    requests: {cpu: "1000m", memory: "1Gi"}
    limits: {cpu: "2000m", memory: "2Gi"}
{{- end }}

{{/*
Get resource plan for language and plan size
If plan is "custom", use user-specified values instead of t-shirt sizes
If language is not specified or not found, uses "default" plans
Usage: {{ include "k8s-app.getResourcePlan" . }}
*/}}
{{- define "k8s-app.getResourcePlan" -}}
{{- $allPlans := fromYaml (include "k8s-app.resourcePlanDefaults" .) }}
{{- $language := .Values.appSpec.language | default "default" }}
{{- $plan := .Values.resources.plan | default "small" }}
{{- $languagePlans := index $allPlans $language | default (index $allPlans "default") }}
{{- if eq $plan "custom" }}
requests:
  cpu: {{ .Values.resources.cpu.minMilliCores }}m
  memory: {{ .Values.resources.memory.minMB }}Mi
limits:
  cpu: {{ .Values.resources.cpu.maxMilliCores }}m
  memory: {{ .Values.resources.memory.maxMB }}Mi
{{- else }}
{{- $planResources := index $languagePlans $plan | default (index $languagePlans "small") }}
{{- $planResources | toYaml }}
{{- end }}
{{- end }}
