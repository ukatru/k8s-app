# Timoni to Helm Conversion Guide

This document explains how the Timoni CUE module was converted to a Helm chart.

## Conversion Mapping

### File Structure

| Timoni CUE | Helm | Description |
|------------|------|-------------|
| `timoni.cue` | `Chart.yaml` | Chart metadata |
| `templates/schema.cue` | `values.yaml` | Configuration schema and defaults |
| `templates/Instance.cue` | `templates/_helpers.tpl` | Helper functions |
| `templates/deployment.cue` | `templates/deployment.yaml` | Deployment manifest |
| `templates/service.cue` | `templates/service.yaml` | Service manifest |
| `templates/service-account.cue` | `templates/serviceaccount.yaml` | ServiceAccount manifest |
| `templates/scaledobject.cue` | `templates/hpa.yaml` | HPA manifest |
| `templates/virtualservice.cue` | `templates/ingress.yaml` | Ingress manifest |
| `templates/efs.cue` | `templates/pvc.yaml` | PVC manifest |

### Schema Conversion

#### Timoni CUE Schema
```cue
#Config: {
    appSpec: #AppSpec
    resources: #Resources
    datadog: #DatadogConfig
    lifecycle?: #Lifecycle
    // ...
}
```

#### Helm Values
```yaml
appSpec:
  name: ""
  version: ""
  # ...

resources:
  plan: "small"
  # ...

datadog:
  team: ""
  # ...
```

### Template Conversion

#### Timoni CUE Template
```cue
#Deployment: appsv1.#Deployment & {
    _config: #Config
    metadata: #Metadata & {
        #Meta: _config.metadata
    }
    spec: {
        replicas: *_config.resources.instances | 1
        // ...
    }
}
```

#### Helm Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "k8s-app.fullname" . }}
  labels:
    {{- include "k8s-app.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.resources.instances | default 1 }}
  # ...
```

## Key Differences

### 1. Type Safety

**Timoni CUE:**
- Strong typing with CUE schema
- Compile-time validation
- Type constraints (e.g., `int & >0 & <65536`)

**Helm:**
- YAML-based (no strong typing)
- Runtime validation only
- Relies on Kubernetes API validation

### 2. Defaults

**Timoni CUE:**
```cue
plan: *"" | "custom" | "small" | "medium" | "large" | "huge"
```

**Helm:**
```yaml
plan: "small"  # Default in values.yaml
```

### 3. Conditionals

**Timoni CUE:**
```cue
if _config.deploymentStrategy != "Rolling" {
    strategy: {
        type: "Recreate"
    }
}
```

**Helm:**
```yaml
{{- if eq .Values.deploymentStrategy "Recreate" }}
strategy:
  type: Recreate
{{- end }}
```

### 4. Computed Values

**Timoni CUE:**
```cue
_resources: {
    if _config.resources.plan == "small" {
        requests: {cpu: "250m", memory: "256Mi"}
        limits: {cpu: "500m", memory: "512Mi"}
    }
}
```

**Helm:**
```yaml
{{- define "k8s-app.resources" -}}
{{- if eq .Values.resources.plan "small" }}
requests:
  cpu: 250m
  memory: 256Mi
limits:
  cpu: 500m
  memory: 512Mi
{{- end }}
{{- end }}
```

## Migration Steps

### 1. For Existing Timoni Users

If you're currently using the Timoni module:

```bash
# Export current Timoni values
timoni inspect values my-app -n my-namespace > current-values.yaml

# Convert to Helm format (manual adjustment needed)
# Edit current-values.yaml to match Helm values.yaml structure

# Install with Helm
helm install my-app ./k8s-app \
  --namespace my-namespace \
  --values current-values.yaml
```

### 2. Value Conversion

Some values need manual conversion:

#### Timoni
```yaml
values:
  appName: my-app
  appVersion: 1.0.0
  appEnv: production
  image: registry/app:1.0.0
```

#### Helm
```yaml
appSpec:
  name: my-app
  version: 1.0.0
  env: production
  image: registry/app:1.0.0
```

### 3. Testing

```bash
# Dry run to verify templates
helm install my-app ./k8s-app \
  --namespace test \
  --values values.yaml \
  --dry-run --debug

# Lint the chart
helm lint ./k8s-app

# Template rendering
helm template my-app ./k8s-app --values values.yaml
```

## Features Preserved

✅ All Timoni features have been preserved:
- Multi-language support (Python, Java, .NET)
- Resource plans (small, medium, large, huge, custom)
- Auto-scaling with HPA
- Health probes (liveness, readiness, startup)
- Datadog integration (APM, logging, profiling)
- Pod Identity (IRSA)
- External configs/secrets auto-discovery
- Storage (EFS)
- Deployment strategies (Rolling, Recreate, BlueGreen*)
- Service mesh support (Istio VirtualService*)

*Note: BlueGreen and VirtualService require additional CRDs

## Features Added

✅ New Helm-specific features:
- Standard Helm hooks
- NOTES.txt for post-install information
- Helm test support
- Better upgrade/rollback support
- Helm repository compatibility

## Limitations

### Timoni CUE Advantages Lost

1. **Type Safety**: No compile-time type checking
2. **Validation**: Less strict validation (relies on K8s API)
3. **Computed Values**: More verbose template syntax
4. **Unification**: No CUE unification capabilities

### Workarounds

1. **Validation**: Use `helm lint` and `--dry-run`
2. **Type Safety**: Document required fields in README
3. **Testing**: Use Helm tests and CI/CD validation

## CI/CD Integration

### Timoni
```yaml
deploy:
  script:
    - timoni apply my-app \
        -f values.yaml \
        --version ${CI_COMMIT_SHORT_SHA}
```

### Helm
```yaml
deploy:
  script:
    - helm upgrade --install my-app ./k8s-app \
        --namespace production \
        --values values.yaml \
        --set appSpec.version=${CI_COMMIT_SHORT_SHA} \
        --wait
```

## Best Practices

### 1. Use Values Files

```bash
# Development
helm install my-app ./k8s-app -f values-dev.yaml

# Production
helm install my-app ./k8s-app -f values-prod.yaml
```

### 2. Override with --set

```bash
helm upgrade my-app ./k8s-app \
  --set appSpec.image=registry/app:v2.0.0 \
  --set appSpec.version=v2.0.0
```

### 3. Use Helm Secrets

```bash
# Install helm-secrets plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Encrypt secrets
helm secrets enc values-prod.yaml

# Deploy with secrets
helm secrets upgrade --install my-app ./k8s-app \
  -f values-prod.yaml
```

## Troubleshooting

### Common Issues

**Issue**: Template rendering errors
```bash
# Debug with --debug flag
helm install my-app ./k8s-app --dry-run --debug
```

**Issue**: Missing required values
```bash
# Check what values are required
helm show values ./k8s-app
```

**Issue**: Upgrade conflicts
```bash
# Force upgrade
helm upgrade my-app ./k8s-app --force

# Or rollback
helm rollback my-app 1
```

## Support

For conversion issues or questions:
- Check the [README](README.md) for examples
- Review [values.yaml](values.yaml) for all options
- See [examples/](examples/) for complete configurations

## Future Enhancements

Planned improvements:
- [ ] JSON Schema validation for values
- [ ] Helm chart testing framework
- [ ] Additional deployment strategies
- [ ] More language-specific templates
- [ ] Enhanced Datadog integration
