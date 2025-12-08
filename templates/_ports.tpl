{{/*
Port calculation logic (similar to Timoni's PortsCalculator)
Ensures there's always an "app" port (defaults to 8080)
*/}}

{{/*
Get all ports with default "app" port
Stores result in a dict for later use
*/}}
{{- define "k8s-app.calculatePorts" -}}
{{- $userPorts := .Values.ports | default list }}
{{- $appPortName := "app" }}
{{- $defaultAppPort := dict "containerPort" 8080 "name" $appPortName }}
{{- $userDefinedAppPort := dict }}
{{- $hasUserAppPort := false }}
{{- $nonAppPorts := list }}
{{- range $userPorts }}
  {{- if eq .name $appPortName }}
    {{- $userDefinedAppPort = . }}
    {{- $hasUserAppPort = true }}
  {{- else }}
    {{- $nonAppPorts = append $nonAppPorts . }}
  {{- end }}
{{- end }}
{{- $finalAppPort := $defaultAppPort }}
{{- if $hasUserAppPort }}
  {{- $finalAppPort = $userDefinedAppPort }}
{{- end }}
{{- $result := prepend $nonAppPorts $finalAppPort }}
{{- dict "ports" $result | toJson }}
{{- end }}

{{/*
Get service ports from calculated ports
*/}}
{{- define "k8s-app.servicePorts" -}}
{{- $calculated := include "k8s-app.calculatePorts" . | fromJson }}
{{- range $calculated.ports }}
- port: {{ .containerPort }}
  targetPort: {{ .containerPort }}
  protocol: TCP
  name: {{ .name }}
{{- end }}
{{- end }}

{{/*
Get container ports from calculated ports
*/}}
{{- define "k8s-app.containerPorts" -}}
{{- $calculated := include "k8s-app.calculatePorts" . | fromJson }}
{{- range $calculated.ports }}
- containerPort: {{ .containerPort }}
  protocol: TCP
  name: {{ .name }}
{{- end }}
{{- end }}

{{/*
Get the app port number
*/}}
{{- define "k8s-app.appPort" -}}
{{- $calculated := include "k8s-app.calculatePorts" . | fromJson }}
{{- range $calculated.ports }}
  {{- if eq .name "app" }}
    {{- .containerPort }}
  {{- end }}
{{- end }}
{{- end }}
