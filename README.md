# k8s-app Helm Chart

A comprehensive Helm chart for deploying applications on Kubernetes, converted from Timoni CUE module.

## Features

- **Multi-language support**: Python, Java, .NET
- **Auto-scaling**: HPA with custom metrics
- **Health probes**: Liveness, readiness, and startup probes
- **Observability**: Grafana, Prometheus, Tempo integration
- **Pod Identity (IRSA)**: AWS IAM roles for service accounts
- **External configs/secrets**: Auto-discovery and custom mappings
- **Storage**: EFS persistent volumes
- **Resource plans**: Small, medium, large, huge, or custom
- **Deployment strategies**: Rolling, Recreate, Blue/Green
- **Service mesh ready**: Istio VirtualService support

## Installation

### Prerequisites

- Kubernetes 1.20+
- Helm 3.0+

### Install Chart

```bash
# Add repository (if published)
helm repo add k8s-app https://charts.example.com

# Install chart
helm install my-app k8s-app/k8s-app \
  --namespace my-namespace \
  --create-namespace \
  --values values.yaml
```

### Local Installation

```bash
# From source
helm install my-app . \
  --namespace my-namespace \
  --create-namespace \
  --values values.yaml
```

## Quick Start

### Minimal Configuration

```yaml
# values.yaml
appSpec:
  name: "my-app"
  version: "1.0.0"
  snowAppId: "SNOW123456"
  env: "dev"
  image: "my-registry/my-app:1.0.0"

observability:
  team: "platform"

resources:
  plan: "small"
```

### Deploy

```bash
helm upgrade --install my-app . \
  --namespace dev \
  --create-namespace \
  --values values.yaml
```

## Configuration

See [values.yaml](values.yaml) for all available options.

### Key Configuration Sections

#### Application Specification

```yaml
appSpec:
  name: "my-app"              # REQUIRED
  version: "1.0.0"            # REQUIRED
  snowAppId: "SNOW123456"     # REQUIRED
  env: "dev"                  # REQUIRED: dev, staging, prod
  language: "python"          # python, java, dotnet
  image: "registry/app:tag"   # REQUIRED
```

#### Resources

```yaml
resources:
  plan: "medium"  # small, medium, large, huge, custom
  instances: 2
  
  # Auto-scaling
  autoscaling:
    enabled: true
    minInstances: 2
    maxInstances: 10
```

#### Pod Identity (IRSA)

```yaml
podIdentity:
  enabled: true
  aws:
    assumedRoles:
      - "arn:aws:iam::123456789012:role/my-app-role"
```

#### Health Probes

```yaml
lifecycle:
  livenessProbe:
    probeType: "http"
    path: "/health"
    port: 8080
  readinessProbe:
    probeType: "http"
    path: "/ready"
    port: 8080
```

#### External Configs/Secrets

```yaml
externalConfigs:
  autodiscovery:
    enabled: true  # Auto-discovers ConfigMaps
  files:
    - configMapName: my-config
      key: config.yaml

externalSecrets:
  autodiscovery:
    enabled: true  # Auto-discovers Secrets
  envVars:
    - secretObjectName: db-credentials
      mappings:
        DB_PASSWORD: password
```

## Examples

### Python Application

```yaml
appSpec:
  name: "python-api"
  version: "1.0.0"
  snowAppId: "SNOW123456"
  env: "prod"
  language: "python"
  image: "registry/python-api:1.0.0"

resources:
  plan: "medium"
  autoscaling:
    enabled: true
    minInstances: 3
    maxInstances: 20

lifecycle:
  livenessProbe:
    probeType: "http"
    path: "/health"
    port: 8080
  readinessProbe:
    probeType: "http"
    path: "/ready"
    port: 8080

observability:
  team: "backend"
  metrics:
    enabled: true
    port: 9090
  tracing:
    enabled: true
    sampleRate: "1.0"
```

### Java Application with IRSA

```yaml
appSpec:
  name: "java-service"
  version: "2.0.0"
  snowAppId: "SNOW789012"
  env: "prod"
  language: "java"
  image: "registry/java-service:2.0.0"

resources:
  plan: "large"

podIdentity:
  enabled: true
  aws:
    assumedRoles:
      - "arn:aws:iam::123456789012:role/java-service-role"

env:
  SPRING_PROFILES_ACTIVE: "prod"
  JAVA_OPTS: "-Xmx2g -XX:+UseG1GC"
```

### Application with Storage

```yaml
appSpec:
  name: "data-processor"
  version: "1.5.0"
  snowAppId: "SNOW345678"
  env: "prod"
  image: "registry/data-processor:1.5.0"

resources:
  plan: "huge"

storage:
  - name: data
    type: efs
    accessMode: ReadWriteMany
    size: 100Gi
    mount:
      path: /data
      readOnly: false
```

## Integration with kpack

This chart works seamlessly with kpack for automated image builds:

```yaml
# .gitlab-ci.yml
build:
  script:
    - kp image patch my-app --git-revision ${CI_COMMIT_SHA} --wait
    - BUILT_IMAGE=$(kp image status my-app -o json | jq -r '.latestImage')

deploy:
  script:
    - |
      helm upgrade --install my-app ./k8s-app \
        --namespace production \
        --set appSpec.image=${BUILT_IMAGE} \
        --set appSpec.version=${CI_COMMIT_SHORT_SHA} \
        --wait
```

## Upgrading

```bash
# Upgrade release
helm upgrade my-app . \
  --namespace my-namespace \
  --values values.yaml \
  --wait

# Rollback
helm rollback my-app 1 --namespace my-namespace
```

## Uninstalling

```bash
helm uninstall my-app --namespace my-namespace
```

## Development

### Linting

```bash
helm lint .
```

### Template Rendering

```bash
helm template my-app . --values values.yaml
```

### Dry Run

```bash
helm install my-app . \
  --namespace test \
  --values values.yaml \
  --dry-run --debug
```

## Conversion from Timoni

This chart was converted from a Timoni CUE module. Key differences:

| Timoni CUE | Helm |
|------------|------|
| `templates/schema.cue` | `values.yaml` |
| `templates/*.cue` | `templates/*.yaml` |
| CUE validation | Helm validation |
| `timoni apply` | `helm install/upgrade` |

## Support

For issues or questions:
- GitHub Issues: https://github.com/ukatru/k8s-app/issues
- Documentation: https://github.com/ukatru/k8s-app/wiki

## License

Apache 2.0
