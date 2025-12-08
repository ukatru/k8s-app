{{/*
Probe defaults map by language
This allows dynamic lookup instead of hardcoded if/else chains
*/}}

{{- define "k8s-app.livenessProbeDefaults" -}}
default:
  probeType: http
  path: /health
  port: 8080
  initialDelaySeconds: 30
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
python:
  probeType: http
  path: /health
  port: 8080
  initialDelaySeconds: 30
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
java:
  probeType: http
  path: /actuator/health/liveness
  port: 8080
  initialDelaySeconds: 60
  timeoutSeconds: 3
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
dotnet:
  probeType: http
  path: /health/live
  port: 8080
  initialDelaySeconds: 30
  timeoutSeconds: 2
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
spa:
  probeType: tcp
  port: 8080
  initialDelaySeconds: 10
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 3
{{- end }}

{{- define "k8s-app.readinessProbeDefaults" -}}
default:
  probeType: http
  path: /ready
  port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
python:
  probeType: http
  path: /ready
  port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
java:
  probeType: http
  path: /actuator/health/readiness
  port: 8080
  initialDelaySeconds: 30
  timeoutSeconds: 3
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
dotnet:
  probeType: http
  path: /health/ready
  port: 8080
  initialDelaySeconds: 10
  timeoutSeconds: 2
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
spa:
  probeType: tcp
  port: 8080
  initialDelaySeconds: 5
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 3
{{- end }}

{{- define "k8s-app.startupProbeDefaults" -}}
default:
  probeType: http
  path: /startup
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 30
python:
  probeType: http
  path: /startup
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 30
java:
  probeType: http
  path: /actuator/health/liveness
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 3
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 60
dotnet:
  probeType: http
  path: /health/startup
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 2
  periodSeconds: 10
  successThreshold: 1
  failureThreshold: 30
spa:
  probeType: tcp
  port: 8080
  initialDelaySeconds: 0
  timeoutSeconds: 1
  periodSeconds: 5
  successThreshold: 1
  failureThreshold: 12
{{- end }}

{{/*
Merge user probe config with language defaults
User values take precedence over language defaults
If language is not specified or not found, uses "default" probes
Usage: {{ include "k8s-app.mergeProbe" (dict "defaultsTemplate" "..." "user" ... "language" ...) }}
*/}}
{{- define "k8s-app.mergeProbe" -}}
{{- $allDefaults := fromYaml (include .defaultsTemplate .) }}
{{- $language := .language | default "default" }}
{{- $defaults := index $allDefaults $language | default (index $allDefaults "default") }}
{{- $merged := merge (.user | default dict) $defaults }}
{{- $merged | toYaml }}
{{- end }}

{{/*
Render liveness probe with language-specific defaults
Usage: {{ include "k8s-app.renderLivenessProbe" . | nindent 8 }}
*/}}
{{- define "k8s-app.renderLivenessProbe" -}}
{{- $merged := include "k8s-app.mergeProbe" (dict "defaultsTemplate" "k8s-app.livenessProbeDefaults" "user" .Values.lifecycle.livenessProbe "language" .Values.appSpec.language) | fromYaml }}
{{- if eq $merged.probeType "http" }}
httpGet:
  path: {{ $merged.path }}
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "tcp" }}
tcpSocket:
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "exec" }}
exec:
  command:
    {{- toYaml $merged.exec | nindent 4 }}
{{- else if eq $merged.probeType "grpc" }}
grpc:
  port: {{ $merged.port }}
{{- end }}
initialDelaySeconds: {{ $merged.initialDelaySeconds }}
timeoutSeconds: {{ $merged.timeoutSeconds }}
periodSeconds: {{ $merged.periodSeconds }}
successThreshold: {{ $merged.successThreshold }}
failureThreshold: {{ $merged.failureThreshold }}
{{- end }}

{{/*
Render readiness probe with language-specific defaults
Usage: {{ include "k8s-app.renderReadinessProbe" . | nindent 8 }}
*/}}
{{- define "k8s-app.renderReadinessProbe" -}}
{{- $merged := include "k8s-app.mergeProbe" (dict "defaultsTemplate" "k8s-app.readinessProbeDefaults" "user" .Values.lifecycle.readinessProbe "language" .Values.appSpec.language) | fromYaml }}
{{- if eq $merged.probeType "http" }}
httpGet:
  path: {{ $merged.path }}
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "tcp" }}
tcpSocket:
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "exec" }}
exec:
  command:
    {{- toYaml $merged.exec | nindent 4 }}
{{- else if eq $merged.probeType "grpc" }}
grpc:
  port: {{ $merged.port }}
{{- end }}
initialDelaySeconds: {{ $merged.initialDelaySeconds }}
timeoutSeconds: {{ $merged.timeoutSeconds }}
periodSeconds: {{ $merged.periodSeconds }}
successThreshold: {{ $merged.successThreshold }}
failureThreshold: {{ $merged.failureThreshold }}
{{- end }}

{{/*
Render startup probe with language-specific defaults
Usage: {{ include "k8s-app.renderStartupProbe" . | nindent 8 }}
*/}}
{{- define "k8s-app.renderStartupProbe" -}}
{{- $merged := include "k8s-app.mergeProbe" (dict "defaultsTemplate" "k8s-app.startupProbeDefaults" "user" .Values.lifecycle.startupProbe "language" .Values.appSpec.language) | fromYaml }}
{{- if eq $merged.probeType "http" }}
httpGet:
  path: {{ $merged.path }}
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "tcp" }}
tcpSocket:
  port: {{ $merged.port }}
{{- else if eq $merged.probeType "exec" }}
exec:
  command:
    {{- toYaml $merged.exec | nindent 4 }}
{{- else if eq $merged.probeType "grpc" }}
grpc:
  port: {{ $merged.port }}
{{- end }}
initialDelaySeconds: {{ $merged.initialDelaySeconds }}
timeoutSeconds: {{ $merged.timeoutSeconds }}
periodSeconds: {{ $merged.periodSeconds }}
successThreshold: {{ $merged.successThreshold }}
failureThreshold: {{ $merged.failureThreshold }}
{{- end }}
